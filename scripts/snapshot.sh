#!/usr/bin/env bash
# Save a snapshot of the TV to state/snapshots/<date>/ and refresh state/all-packages.txt.
# Run it once BEFORE changing anything (your "before"), and again whenever you like.
# Changes nothing on the TV.
. "$(dirname "$0")/lib.sh"
tv_connect

d="$STATE/snapshots/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$d"
tvsh pm list packages    | sed 's/^package://' | awk 'NF' | sort > "$d/all-packages.txt"
tvsh pm list packages -d | sed 's/^package://' | awk 'NF' | sort > "$d/disabled.txt"
{
  echo "model=$(tvsh getprop ro.product.model)"
  echo "manufacturer=$(tvsh getprop ro.product.manufacturer)"
  echo "fireos=$(tvsh getprop ro.build.version.name)"
  echo "android=$(tvsh getprop ro.build.version.release)"
} > "$d/device.txt"
tvsh "grep -E 'MemTotal|MemAvailable|SwapTotal|SwapFree' /proc/meminfo" > "$d/meminfo.txt"
for k in private_dns_mode private_dns_specifier window_animation_scale transition_animation_scale animator_duration_scale; do
  echo "$k=$(tvsh settings get global "$k")"
done > "$d/settings.txt"
cp "$d/all-packages.txt" "$STATE/all-packages.txt"

echo "Saved to $d"
echo "  packages: $(wc -l < "$d/all-packages.txt" | tr -d ' ')   disabled: $(wc -l < "$d/disabled.txt" | tr -d ' ')"
sed 's/^/  /' "$d/device.txt"
awk '{printf "  %s %d MB\n", $1, $2/1024}' "$d/meminfo.txt"
