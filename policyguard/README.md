# policyguard

A small self-binding daemon that keeps forbidden sites (YouTube, by default) out
of the Firefox `WebsiteFilter` policy. If a broad exception ever creeps into the
policy file — you edit it in a weak moment, some tool adds it — policyguard
strips it back out on a schedule, keeping only the deliberate embed-only
exceptions.

It pairs with the `~/.claude/hooks/block-youtube-policy.py` PreToolUse hook: the
hook stops *Claude* from adding such entries; policyguard cleans up anything that
gets in by any other route.

## How it works

- A **systemd user timer** runs `policyguard enforce` every couple of minutes.
- `enforce` reads each target policy file, removes any exception that matches a
  blocklist substring and is not in the allowlist, and rewrites the file
  (atomically, preserving formatting and `<all_urls>`).
- A **password** gates the only escape hatch, `pause`. Without the password the
  daemon just keeps enforcing.

## Blocklist / allowlist

- `blocklist.txt` — substrings (host fragments) that are stripped. Baked into the
  binary at build time. Extend per-machine without rebuilding via
  `~/.config/policyguard/blocklist.local.txt`.
- `allowlist.txt` — exact exception strings always kept (the `/embed/*` lines).
  Per-machine extension: `~/.config/policyguard/allowlist.local.txt`.

## Install

```sh
cd ~/.dotfiles/policyguard
./install.sh            # default: re-check every 2 minutes
./install.sh 90s        # or pick your own interval
policyguard set-password
```

Requires Go (build-time only) and systemd. Builds with the standard library
only — no module downloads, so it works behind the restrictive firewall policy.

## Commands

| command | what it does |
|---|---|
| `policyguard status` | show enforcing/paused state, timer state, any offenders |
| `policyguard enforce` | one sanitizing pass (what the timer runs) |
| `policyguard pause 30m` | pause enforcement for a while — asks for the password |
| `policyguard resume` | resume now — asks for the password |
| `policyguard set-password` | set or change the password (change needs the old one) |
| `policyguard watch [interval]` | run enforce forever in the foreground (timer alternative) |

## Honest limits

policyguard runs as **your own user**, so it is friction, not a vault:

- Killing the process does nothing lasting — the timer restarts it.
- To actually stop it you must run `systemctl --user disable --now
  policyguard.timer`. That deliberate step *is* the guardrail.
- You own the files, so with enough determination you can edit the blocklist,
  the policy file, or the units. A truly tamper-resistant version would need a
  **root-owned** system service (so undoing it needs `sudo`); ask if you want
  that variant.

## Files

- `~/.local/bin/policyguard` — the compiled binary
- `~/.config/systemd/user/policyguard.{service,timer}` — the schedule
- `~/.config/policyguard/auth.json` — salted password hash (mode 0600)
- `~/.local/state/policyguard/state.json` — pause state
- `~/.local/state/policyguard/enforce.log` — what was removed, and when
