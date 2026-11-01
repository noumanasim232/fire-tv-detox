#!/usr/bin/env bash
# Health check. Changes nothing.
# Shows: connection, model, Fire OS version, uptime, disabled-vs-log drift, Private DNS,
# animation scales (warns if not default), free memory.
. "$(dirname "$0")/lib.sh"
tv_connect

up="$(tvsh cat /proc/uptime | cut -d. -f1)"; up="${up:-0}"
echo "TV         $TV"
echo "Model      $(tvsh getprop ro.product.model) ($(tvsh getprop ro.product.manufacturer))"
echo "Fire OS    $(tvsh getprop ro.build.version.name)   Android $(tvsh getprop ro.build.version.release)"
echo "Uptime     $((up/3600))h $((up%3600/60))m"
echo

on_tv="$(tvsh pm list packages -d | sed 's/^package://' | awk 'NF' | sort)"
logged="$(sort "$STATE/disabled.txt" 2>/dev/null | awk 'NF')"
echo "Disabled on TV: $(printf '%s\n' "$on_tv" | awk 'NF' | wc -l | tr -d ' ')   logged in state/disabled.txt: $(printf '%s\n' "$logged" | awk 'NF' | wc -l | tr -d ' ')"
in_log_only="$(comm -23 <(printf '%s\n' "$logged") <(printf '%s\n' "$on_tv") | awk 'NF')"
on_tv_only="$(comm -13 <(printf '%s\n' "$logged") <(printf '%s\n' "$on_tv") | awk 'NF')"
if [ -z "$in_log_only$on_tv_only" ]; then
  echo "  state/disabled.txt matches the TV."
fi
if [ -n "$in_log_only" ]; then
  echo "  In the log but ENABLED on the TV (Fire OS or an update turned these back on):"
  printf '%s\n' "$in_log_only" | sed 's/^/    /'
  echo "  -> re-run scripts/disable.sh on them, or move them to state/reenabled-by-system.txt if Fire OS keeps undoing it."
fi
if [ -n "$on_tv_only" ]; then
  echo "  Disabled on the TV but not in the log (done outside this tool):"
  printf '%s\n' "$on_tv_only" | sed 's/^/    /'
fi
echo

m="$(tvsh settings get global private_dns_mode)"; s="$(tvsh settings get global private_dns_specifier)"
echo "Private DNS   mode=$m  server=$s"

w="$(tvsh settings get global window_animation_scale)"
t="$(tvsh settings get global transition_animation_scale)"
a="$(tvsh settings get global animator_duration_scale)"
echo "Animations    window=$w  transition=$t  animator=$a"
case "$w|$t|$a" in
  "1.0|1.0|null"|"1.0|1.0|1.0"|"null|null|null") ;;
  *) echo "  WARNING: not at defaults. If Settings or the side panel will not open, run scripts/fix-animations.sh" ;;
esac

echo "Memory        $(tvsh "grep -E 'MemAvailable|SwapFree' /proc/meminfo" | awk '{printf "%s %d MB   ", $1, $2/1024}')"
