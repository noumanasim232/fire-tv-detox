#!/usr/bin/env bash
# Disable ONE package with `pm disable-user --user 0` and log the result.
#   scripts/disable.sh com.amazon.tv.acr
#
# Prints one of:
#   DISABLED   done, logged in state/disabled.txt
#   PROTECTED  Fire OS refused ("Cannot disable a protected package") - normal, logged in
#              state/protected-skipped.txt
#   ALREADY    was already disabled
#   MISSING    not installed on this TV
#   REFUSED    matches lists/never-touch.txt - nothing was sent to the TV
#   OTHER      something unexpected; the error is shown
. "$(dirname "$0")/lib.sh"
pkg="${1:?usage: scripts/disable.sh <package>}"

if is_never_touch "$pkg"; then
  echo "REFUSED   $pkg  (matches lists/never-touch.txt - the TV needs it)"
  exit 3
fi

tv_connect
if ! tvsh pm list packages | grep -qx "package:$pkg"; then
  echo "MISSING   $pkg  (not on this TV - fine, skip it)"
  exit 0
fi
if tvsh pm list packages -d | grep -qx "package:$pkg"; then
  log_once "$STATE/disabled.txt" "$pkg"
  echo "ALREADY   $pkg  (already disabled)"
  exit 0
fi

out="$(tvsh pm disable-user --user 0 "$pkg")"
case "$out" in
  *"disabled-user"*)
    log_once "$STATE/disabled.txt" "$pkg"
    echo "DISABLED  $pkg" ;;
  *"protected package"*)
    log_once "$STATE/protected-skipped.txt" "$pkg"
    echo "PROTECTED $pkg  (Fire OS will not allow it - normal, skipped)" ;;
  *)
    echo "OTHER     $pkg: $(printf '%s\n' "$out" | grep -v '^[[:space:]]*at ' | head -2 | tr '\n' ' ')"
    exit 1 ;;
esac
