// policyguard keeps forbidden sites out of the Firefox WebsiteFilter policy.
//
// It is a self-binding tool: a systemd user timer runs `policyguard enforce`
// every couple of minutes, which strips any blocklisted exception (e.g.
// youtube.com) that has crept into the policy file, keeping only the deliberate
// embed-only allowlist. A password gates the `pause` escape hatch so you can't
// impulsively grant yourself an exception without deliberately unlocking it.
//
// Honest ceiling: this runs as your own user, so a determined you with root can
// always `systemctl --user disable policyguard.timer` or edit the files. The
// point is friction against impulse, not a vault.
package main

import (
	"bufio"
	"bytes"
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"crypto/subtle"
	_ "embed"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

//go:embed blocklist.txt
var embeddedBlocklist string

//go:embed allowlist.txt
var embeddedAllowlist string

const pbkdfIters = 200000

// stdin is shared so buffered read-ahead is not lost between prompts.
var stdin = bufio.NewReader(os.Stdin)

// ---- paths -----------------------------------------------------------------

func home() string {
	h, err := os.UserHomeDir()
	if err != nil || h == "" {
		return "/root"
	}
	return h
}

func dotfilesDir() string {
	if d := os.Getenv("DOTFILES"); d != "" {
		return d
	}
	return filepath.Join(home(), ".dotfiles")
}

func stateDir() string  { return filepath.Join(home(), ".local", "state", "policyguard") }
func configDir() string { return filepath.Join(home(), ".config", "policyguard") }
func authFile() string  { return filepath.Join(configDir(), "auth.json") }
func stateFile() string { return filepath.Join(stateDir(), "state.json") }
func logFile() string   { return filepath.Join(stateDir(), "enforce.log") }

// targets returns the policy files to sanitize. Override with
// POLICYGUARD_TARGETS (colon-separated) for testing.
func targets() []string {
	if t := os.Getenv("POLICYGUARD_TARGETS"); t != "" {
		return strings.Split(t, ":")
	}
	return []string{
		filepath.Join(dotfilesDir(), "etc", "etc", "firefox", "policies", "policies.json"),
	}
}

// ---- block / allow lists ---------------------------------------------------

func parseLines(s string) []string {
	var out []string
	for _, ln := range strings.Split(s, "\n") {
		ln = strings.TrimSpace(ln)
		if ln == "" || strings.HasPrefix(ln, "#") {
			continue
		}
		out = append(out, ln)
	}
	return out
}

func blocklist() []string {
	out := parseLines(embeddedBlocklist)
	// Optional user extension, not baked into the binary.
	if b, err := os.ReadFile(filepath.Join(configDir(), "blocklist.local.txt")); err == nil {
		out = append(out, parseLines(string(b))...)
	}
	for i := range out {
		out[i] = strings.ToLower(out[i])
	}
	return out
}

func allowlist() map[string]bool {
	m := map[string]bool{}
	for _, l := range parseLines(embeddedAllowlist) {
		m[l] = true
	}
	if b, err := os.ReadFile(filepath.Join(configDir(), "allowlist.local.txt")); err == nil {
		for _, l := range parseLines(string(b)) {
			m[l] = true
		}
	}
	return m
}

func isBlocked(entry string, block []string, allow map[string]bool) bool {
	if allow[strings.TrimSpace(entry)] {
		return false
	}
	low := strings.ToLower(entry)
	for _, b := range block {
		if strings.Contains(low, b) {
			return true
		}
	}
	return false
}

// ---- enforce ---------------------------------------------------------------

func enforce() int {
	if until, paused := pausedUntil(); paused {
		logln(fmt.Sprintf("paused until %s — skipping enforcement", until.Format(time.RFC3339)))
		fmt.Printf("policyguard: paused until %s\n", until.Format("15:04:05"))
		return 0
	}
	block := blocklist()
	allow := allowlist()
	totalRemoved := 0
	for _, path := range targets() {
		removed, err := sanitizeFirefox(path, block, allow)
		if err != nil {
			if errors.Is(err, os.ErrNotExist) {
				continue // policy file not present on this machine
			}
			logln(fmt.Sprintf("ERROR %s: %v", path, err))
			fmt.Fprintf(os.Stderr, "policyguard: %s: %v\n", path, err)
			continue
		}
		if len(removed) > 0 {
			totalRemoved += len(removed)
			logln(fmt.Sprintf("%s: removed %d entr%s: %s", path, len(removed),
				plural(len(removed)), strings.Join(removed, ", ")))
			fmt.Printf("policyguard: stripped %d blocked entr%s from %s\n",
				len(removed), plural(len(removed)), filepath.Base(path))
		}
	}
	if totalRemoved == 0 {
		fmt.Println("policyguard: clean, nothing to remove")
	}
	return 0
}

func plural(n int) string {
	if n == 1 {
		return "y"
	}
	return "ies"
}

// sanitizeFirefox strips blocked entries from policies.WebsiteFilter.Exceptions
// and rewrites the file only if something changed. Returns the removed entries.
func sanitizeFirefox(path string, block []string, allow map[string]bool) ([]string, error) {
	raw, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	var doc map[string]any
	if err := json.Unmarshal(raw, &doc); err != nil {
		return nil, fmt.Errorf("parse: %w", err)
	}
	policies, _ := doc["policies"].(map[string]any)
	if policies == nil {
		return nil, nil
	}
	wf, _ := policies["WebsiteFilter"].(map[string]any)
	if wf == nil {
		return nil, nil
	}
	exc, _ := wf["Exceptions"].([]any)
	if exc == nil {
		return nil, nil
	}

	kept := make([]any, 0, len(exc))
	var removed []string
	for _, e := range exc {
		s, ok := e.(string)
		if ok && isBlocked(s, block, allow) {
			removed = append(removed, s)
			continue
		}
		kept = append(kept, e)
	}
	if len(removed) == 0 {
		return nil, nil
	}
	wf["Exceptions"] = kept

	out, err := marshalIndent(doc)
	if err != nil {
		return nil, err
	}
	if err := atomicWrite(path, out); err != nil {
		return nil, err
	}
	return removed, nil
}

// marshalIndent pretty-prints JSON without HTML-escaping (so "<all_urls>" and
// "&" survive intact) and with a trailing newline (Encoder.Encode adds one).
func marshalIndent(v any) ([]byte, error) {
	var buf bytes.Buffer
	enc := json.NewEncoder(&buf)
	enc.SetEscapeHTML(false)
	enc.SetIndent("", "  ")
	if err := enc.Encode(v); err != nil {
		return nil, err
	}
	return buf.Bytes(), nil
}

func atomicWrite(path string, data []byte) error {
	dir := filepath.Dir(path)
	tmp, err := os.CreateTemp(dir, ".policyguard-*")
	if err != nil {
		return err
	}
	tmpName := tmp.Name()
	defer os.Remove(tmpName)
	if _, err := tmp.Write(data); err != nil {
		tmp.Close()
		return err
	}
	if err := tmp.Close(); err != nil {
		return err
	}
	_ = os.Chmod(tmpName, 0o644)
	return os.Rename(tmpName, path)
}

// watch runs enforce on a fixed interval; an alternative to the systemd timer.
func watch(interval time.Duration) int {
	if interval <= 0 {
		interval = 2 * time.Minute
	}
	for {
		enforce()
		time.Sleep(interval)
	}
}

// ---- pause state -----------------------------------------------------------

type stateT struct {
	PauseUntil int64 `json:"pause_until"`
}

func loadState() stateT {
	var s stateT
	if b, err := os.ReadFile(stateFile()); err == nil {
		_ = json.Unmarshal(b, &s)
	}
	return s
}

func saveState(s stateT) error {
	if err := os.MkdirAll(stateDir(), 0o755); err != nil {
		return err
	}
	b, _ := json.MarshalIndent(s, "", "  ")
	return atomicWrite(stateFile(), append(b, '\n'))
}

func pausedUntil() (time.Time, bool) {
	s := loadState()
	if s.PauseUntil == 0 {
		return time.Time{}, false
	}
	t := time.Unix(s.PauseUntil, 0)
	return t, time.Now().Before(t)
}

// ---- password --------------------------------------------------------------

type authT struct {
	Salt  string `json:"salt"`
	Iters int    `json:"iters"`
	Hash  string `json:"hash"`
}

func kdf(password string, salt []byte, iters int) string {
	mac := []byte(password)
	for i := 0; i < iters; i++ {
		h := hmac.New(sha256.New, salt)
		h.Write(mac)
		mac = h.Sum(nil)
	}
	return hex.EncodeToString(mac)
}

func loadAuth() (authT, bool) {
	var a authT
	b, err := os.ReadFile(authFile())
	if err != nil {
		return a, false
	}
	if json.Unmarshal(b, &a) != nil || a.Hash == "" {
		return a, false
	}
	return a, true
}

func verifyPassword(password string) bool {
	a, ok := loadAuth()
	if !ok {
		return false
	}
	salt, err := hex.DecodeString(a.Salt)
	if err != nil {
		return false
	}
	got := kdf(password, salt, a.Iters)
	return subtle.ConstantTimeCompare([]byte(got), []byte(a.Hash)) == 1
}

func setPassword() int {
	if _, ok := loadAuth(); ok {
		old, err := readSecret("Current password: ")
		if err != nil || !verifyPassword(old) {
			fmt.Fprintln(os.Stderr, "policyguard: wrong password")
			return 1
		}
	} else {
		fmt.Println("No password set yet — creating one.")
	}
	p1, err := readSecret("New password: ")
	if err != nil {
		return 1
	}
	p2, err := readSecret("Confirm password: ")
	if err != nil {
		return 1
	}
	if p1 != p2 {
		fmt.Fprintln(os.Stderr, "policyguard: passwords do not match")
		return 1
	}
	if len(p1) < 4 {
		fmt.Fprintln(os.Stderr, "policyguard: password too short")
		return 1
	}
	salt := make([]byte, 16)
	if _, err := rand.Read(salt); err != nil {
		return 1
	}
	a := authT{Salt: hex.EncodeToString(salt), Iters: pbkdfIters, Hash: kdf(p1, salt, pbkdfIters)}
	if err := os.MkdirAll(configDir(), 0o700); err != nil {
		fmt.Fprintln(os.Stderr, err)
		return 1
	}
	b, _ := json.MarshalIndent(a, "", "  ")
	if err := os.WriteFile(authFile(), append(b, '\n'), 0o600); err != nil {
		fmt.Fprintln(os.Stderr, err)
		return 1
	}
	fmt.Println("policyguard: password set")
	return 0
}

// readSecret reads a line from the controlling terminal with echo disabled.
func readSecret(prompt string) (string, error) {
	fmt.Fprint(os.Stderr, prompt)
	stty := func(arg string) {
		c := exec.Command("stty", arg)
		c.Stdin = os.Stdin
		_ = c.Run()
	}
	stty("-echo")
	defer func() { stty("echo"); fmt.Fprintln(os.Stderr) }()
	line, err := stdin.ReadString('\n')
	if err != nil && line == "" {
		return "", err
	}
	return strings.TrimRight(line, "\r\n"), nil
}

func requirePassword() bool {
	if _, ok := loadAuth(); !ok {
		fmt.Fprintln(os.Stderr, "policyguard: no password set. Run 'policyguard set-password' first.")
		return false
	}
	p, err := readSecret("Password: ")
	if err != nil || !verifyPassword(p) {
		fmt.Fprintln(os.Stderr, "policyguard: wrong password")
		return false
	}
	return true
}

// ---- pause / resume commands ----------------------------------------------

func pause(args []string) int {
	if len(args) < 1 {
		fmt.Fprintln(os.Stderr, "usage: policyguard pause <duration>  (e.g. 30m, 1h, 90s)")
		return 2
	}
	d, err := time.ParseDuration(args[0])
	if err != nil || d <= 0 {
		fmt.Fprintf(os.Stderr, "policyguard: bad duration %q\n", args[0])
		return 2
	}
	if d > 8*time.Hour {
		fmt.Fprintln(os.Stderr, "policyguard: max pause is 8h")
		return 2
	}
	if !requirePassword() {
		return 1
	}
	until := time.Now().Add(d)
	if err := saveState(stateT{PauseUntil: until.Unix()}); err != nil {
		fmt.Fprintln(os.Stderr, err)
		return 1
	}
	logln(fmt.Sprintf("paused until %s", until.Format(time.RFC3339)))
	fmt.Printf("policyguard: enforcement paused until %s\n", until.Format("2006-01-02 15:04:05"))
	return 0
}

func resume() int {
	if _, paused := pausedUntil(); !paused {
		fmt.Println("policyguard: not paused")
		return 0
	}
	if !requirePassword() {
		return 1
	}
	if err := saveState(stateT{PauseUntil: 0}); err != nil {
		fmt.Fprintln(os.Stderr, err)
		return 1
	}
	logln("resumed by user")
	fmt.Println("policyguard: enforcement resumed")
	return 0
}

// ---- status ----------------------------------------------------------------

func status() int {
	fmt.Println("policyguard status")
	fmt.Println("------------------")
	if _, ok := loadAuth(); ok {
		fmt.Println("password:   set")
	} else {
		fmt.Println("password:   NOT set (pause/resume disabled)")
	}
	if until, paused := pausedUntil(); paused {
		fmt.Printf("state:      PAUSED until %s (%s left)\n",
			until.Format("15:04:05"), time.Until(until).Round(time.Second))
	} else {
		fmt.Println("state:      enforcing")
	}
	out, _ := exec.Command("systemctl", "--user", "is-active", "policyguard.timer").Output()
	fmt.Printf("timer:      %s", string(out))
	if len(out) == 0 {
		fmt.Println("unknown")
	}
	block := blocklist()
	allow := allowlist()
	for _, path := range targets() {
		raw, err := os.ReadFile(path)
		if err != nil {
			continue
		}
		var doc map[string]any
		if json.Unmarshal(raw, &doc) != nil {
			continue
		}
		policies, _ := doc["policies"].(map[string]any)
		wf, _ := mapGet(policies, "WebsiteFilter")
		exc, _ := wf["Exceptions"].([]any)
		var offenders []string
		for _, e := range exc {
			if s, ok := e.(string); ok && isBlocked(s, block, allow) {
				offenders = append(offenders, s)
			}
		}
		fmt.Printf("target:     %s\n", path)
		if len(offenders) > 0 {
			fmt.Printf("  WARNING:  %d blocked entr%s present: %s\n",
				len(offenders), plural(len(offenders)), strings.Join(offenders, ", "))
		} else {
			fmt.Println("  clean:    no blocked entries")
		}
	}
	return 0
}

func mapGet(m map[string]any, k string) (map[string]any, bool) {
	v, _ := m[k].(map[string]any)
	return v, v != nil
}

// ---- log -------------------------------------------------------------------

func logln(msg string) {
	_ = os.MkdirAll(stateDir(), 0o755)
	f, err := os.OpenFile(logFile(), os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o644)
	if err != nil {
		return
	}
	defer f.Close()
	fmt.Fprintf(f, "%s %s\n", time.Now().Format(time.RFC3339), msg)
}

// ---- main ------------------------------------------------------------------

const usage = `policyguard — keep forbidden sites out of the browser policy

usage:
  policyguard enforce            sanitize the policy files once (used by the timer)
  policyguard watch [interval]   run enforce forever on an interval (default 2m)
  policyguard status             show enforcement / pause / timer state
  policyguard pause <duration>   pause enforcement (needs password); e.g. 30m, 1h
  policyguard resume             resume enforcement (needs password)
  policyguard set-password       set or change the pause password
  policyguard help               this text
`

func main() {
	if len(os.Args) < 2 {
		fmt.Print(usage)
		os.Exit(2)
	}
	switch os.Args[1] {
	case "enforce":
		os.Exit(enforce())
	case "watch":
		var d time.Duration
		if len(os.Args) > 2 {
			d, _ = time.ParseDuration(os.Args[2])
		}
		os.Exit(watch(d))
	case "status":
		os.Exit(status())
	case "pause":
		os.Exit(pause(os.Args[2:]))
	case "resume":
		os.Exit(resume())
	case "set-password":
		os.Exit(setPassword())
	case "help", "-h", "--help":
		fmt.Print(usage)
	default:
		fmt.Fprintf(os.Stderr, "policyguard: unknown command %q\n\n", os.Args[1])
		fmt.Print(usage)
		os.Exit(2)
	}
}
