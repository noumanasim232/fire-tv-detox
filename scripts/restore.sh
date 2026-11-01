#!/usr/bin/env bash
# Re-enable packages and take them out of state/disabled.txt.
#   scripts/restore.sh com.amazon.tv.acr             one package (or several)
#   scripts/restore.sh --all                         everything in state/disabled.txt
. "$(dirname "$0")/lib.sh"
[ $# -gt 0 ] || { echo "usage: scripts/restore.sh <package>... | --all" >&2; exit 2; }
if [ "$1" = "--all" ]; then
  # shellcheck disable=SC2046
  set -- $(cat "$STATE/disabled.txt" 2>/dev/null)
  [ $# -gt 0 ] || { echo "state/disabled.txt is empty - nothing to restore."; exit 0; }
fi

tv_connect
fail=0
for p in "$@"; do
  out="$(tvsh pm enable --user 0 "$p")"
  case "$out" in
    *"new state: enabled"*|*"new state: default"*)
      unlog "$STATE/disabled.txt" "$p"
      echo "ENABLED   $p" ;;
    *)
      echo "FAILED    $p: $(printf '%s\n' "$out" | head -1)"; fail=1 ;;
  esac
done
[ "$fail" -eq 0 ] && echo "Done. A reboot (scripts/wait-for-boot.sh --reboot) lets the restored services start cleanly."
exit $fail
