#!/usr/bin/env bash
# Shared helpers for the fire-tv-detox scripts. Source it from a script; don't run it.
#   . "$(dirname "$0")/lib.sh"
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE="$ROOT/state"
LISTS="$ROOT/lists"
mkdir -p "$STATE"

# TV address: the TV environment variable wins, then tv.conf in the repo root.
if [ -z "${TV:-}" ] && [ -f "$ROOT/tv.conf" ]; then
  # shellcheck disable=SC1091
  . "$ROOT/tv.conf"
fi
if [ -z "${TV:-}" ]; then
  echo "No TV address set. Copy tv.conf.example to tv.conf and put your TV's IP in it" >&2
  echo "(Settings > My Fire TV > About > Network), or run with TV=192.168.1.xx:5555." >&2
  exit 2
fi
case "$TV" in *:*) ;; *) TV="$TV:5555" ;; esac

if ! command -v adb >/dev/null 2>&1; then
  echo "adb is not installed. See README.md > What you need." >&2
  exit 2
fi

# adb against this TV. tvsh runs a shell command on the TV and strips carriage returns.
tv()   { adb -s "$TV" "$@"; }
tvsh() { adb -s "$TV" shell "$@" 2>&1 | tr -d '\r'; }

tv_connect() {
  adb connect "$TV" >/dev/null 2>&1
  if [ "$(adb -s "$TV" get-state 2>/dev/null | tr -d '\r')" != "device" ]; then
    cat >&2 <<EOF
Cannot reach $TV over ADB.
  - Is the TV on, and on the same network as this computer? Is the IP right?
    (Settings > My Fire TV > About > Network)
  - Is ADB Debugging ON?  (Settings > My Fire TV > Developer Options)
  - Is there an "Allow USB debugging?" prompt on the TV screen? Choose "Always allow".
  - Just rebooted? The ADB port can take a few minutes to open. Try again.
EOF
    exit 1
  fi
}

# Read a package list file: drop comments and blank lines, one package per line.
read_list() {
  sed -e 's/#.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' "$1" | awk 'NF'
}

# True if $1 matches lists/never-touch.txt (exact name, or "<entry>." as a prefix).
is_never_touch() {
  local pkg="$1" pat
  while IFS= read -r pat; do
    case "$pkg" in "$pat"|"$pat".*) return 0 ;; esac
  done < <(read_list "$LISTS/never-touch.txt")
  return 1
}

# Append line $2 to file $1 unless it is already there.
log_once() { grep -qxF -- "$2" "$1" 2>/dev/null || echo "$2" >> "$1"; }

# Remove the exact line $2 from file $1.
unlog() {
  [ -f "$1" ] || return 0
  grep -vxF -- "$2" "$1" > "$1.tmp" || true
  mv "$1.tmp" "$1"
}
