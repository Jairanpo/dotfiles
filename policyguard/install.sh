#!/usr/bin/env bash
# Build and install policyguard as a systemd *user* timer.
#
#   ./install.sh [interval]
#
# interval is a systemd time span for how often to re-sanitize (default 2min),
# e.g. 90s, 5min, 1h.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INTERVAL="${1:-2min}"
BIN_DIR="$HOME/.local/bin"
BIN="$BIN_DIR/policyguard"
UNIT_DIR="$HOME/.config/systemd/user"

echo ">> building policyguard"
mkdir -p "$BIN_DIR"
( cd "$HERE" && go build -o "$BIN" . )

echo ">> installing systemd user units to $UNIT_DIR (interval: $INTERVAL)"
mkdir -p "$UNIT_DIR"
cp "$HERE/systemd/policyguard.service" "$UNIT_DIR/policyguard.service"
sed "s/^OnUnitActiveSec=.*/OnUnitActiveSec=$INTERVAL/" \
	"$HERE/systemd/policyguard.timer" >"$UNIT_DIR/policyguard.timer"

echo ">> enabling timer"
systemctl --user daemon-reload
systemctl --user enable --now policyguard.timer

echo ">> first enforcement pass"
"$BIN" enforce || true

# Keep the timer running even when you're not logged in graphically.
if command -v loginctl >/dev/null 2>&1; then
	loginctl enable-linger "$USER" >/dev/null 2>&1 || true
fi

cat <<EOF

policyguard installed.

  status:        policyguard status
  set password:  policyguard set-password   # needed before you can pause
  pause:         policyguard pause 30m       # asks for the password
  resume:        policyguard resume
  timer:         systemctl --user list-timers policyguard.timer

To fully stop enforcement you must deliberately run:
  systemctl --user disable --now policyguard.timer
(That is the intended friction — there is no way to make it un-disableable
 while it runs as your own user.)
EOF
