#!/usr/bin/env bash
# Wait until the TV has booted AND the home screen is in front, so remote presses are not dropped.
#   scripts/wait-for-boot.sh            just wait
#   scripts/wait-for-boot.sh --reboot   reboot the TV first, then wait
. "$(dirname "$0")/lib.sh"

if [ "${1:-}" = "--reboot" ]; then
  tv_connect
  echo "Rebooting $TV ..."
  adb -s "$TV" reboot >/dev/null 2>&1
  sleep 30
fi

printf 'Waiting for boot '
booted=0
for _ in $(seq 1 60); do
  adb connect "$TV" >/dev/null 2>&1
  if [ "$(adb -s "$TV" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; then booted=1; break; fi
  printf '.'; sleep 10
done
echo
if [ "$booted" -ne 1 ]; then
  echo "No ADB after 10 minutes. The TV may be up with its ADB port still closed:" >&2
  echo "check Settings > My Fire TV > Developer Options > ADB Debugging - if it is already ON, switch it" >&2
  echo "off and on again (that opens the port at once on some TVs) - then run scripts/check.sh." >&2
  exit 1
fi

printf 'Waiting for the home screen '
front=""
for _ in $(seq 1 12); do
  front="$(adb -s "$TV" shell dumpsys activity activities 2>/dev/null | tr -d '\r' | grep -m1 mResumedActivity | sed -n 's/.* u0 \([^ ]*\) .*/\1/p')"
  case "$front" in *HomeActivity*|*launcher*|*projengmenu*|*vizzini*|*creensaver*|*Dream*) break ;; esac
  printf '.'; sleep 5
done
echo
case "$front" in
  *HomeActivity*|*launcher*|*projengmenu*)
    echo "Home screen is up. Give it another 30 seconds before testing - right after boot the launcher can drop remote presses." ;;
  *vizzini*|*creensaver*|*Dream*)
    echo "Booted; the screensaver is showing (the TV is idle - that is fine). Press any button on the remote to wake it." ;;
  "")
    echo "Booted, but could not read what is on screen. Press Home on the remote and try." ;;
  *)
    echo "Booted, but something else is in front: $front. Press Home on the remote." ;;
esac
echo "Disabled packages on the TV now: $(adb -s "$TV" shell pm list packages -d 2>/dev/null | tr -d '\r' | awk 'NF' | wc -l | tr -d ' ')"
