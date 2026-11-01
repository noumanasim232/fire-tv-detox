#!/usr/bin/env bash
# Disable the packages in a list file, one at a time, at most 10 per run.
#   scripts/disable-list.sh lists/01-tracking-and-ads.txt          asks "yes" first
#   scripts/disable-list.sh lists/01-tracking-and-ads.txt --yes    no prompt
#
# Skips packages that are not on this TV, already disabled, or in lists/never-touch.txt.
# If more than 10 remain, it does the first 10 and tells you to reboot, test, and run again.
. "$(dirname "$0")/lib.sh"
list="${1:?usage: scripts/disable-list.sh <list-file> [--yes]}"
[ -f "$list" ] || { echo "No such file: $list" >&2; exit 2; }
yes="${2:-}"

tv_connect
all="$(tvsh pm list packages | sed 's/^package://')"
dis="$(tvsh pm list packages -d | sed 's/^package://')"
prot="$(cat "$STATE/protected-skipped.txt" 2>/dev/null)"
reen="$(cat "$STATE/reenabled-by-system.txt" 2>/dev/null)"

pending=""; skipped=""
while IFS= read -r p; do
  if is_never_touch "$p"; then skipped="$skipped  $p  (never-touch)\n"; continue; fi
  if ! printf '%s\n' "$all" | grep -qx -- "$p"; then skipped="$skipped  $p  (not on this TV)\n"; continue; fi
  if printf '%s\n' "$dis" | grep -qx -- "$p"; then skipped="$skipped  $p  (already disabled)\n"; continue; fi
  if printf '%s\n' "$prot" | grep -qx -- "$p"; then skipped="$skipped  $p  (protected - Fire OS refused before)\n"; continue; fi
  if printf '%s\n' "$reen" | grep -qx -- "$p"; then skipped="$skipped  $p  (Fire OS turns it back on at boot)\n"; continue; fi
  pending="$pending$p\n"
done < <(read_list "$list")

[ -n "$skipped" ] && { echo "Skipping:"; printf "$skipped"; echo; }
if [ -z "$pending" ]; then echo "Nothing left to do in $list."; exit 0; fi

batch="$(printf "$pending" | head -10)"
n=$(printf '%s\n' "$batch" | wc -l | tr -d ' ')
rest=$(( $(printf "$pending" | wc -l | tr -d ' ') - n ))

echo "Will disable these $n package(s) on $TV:"
printf '%s\n' "$batch" | sed 's/^/  /'
[ "$rest" -gt 0 ] && echo "($rest more in this list wait for the next run - max 10 per batch.)"
if [ "$yes" != "--yes" ]; then
  printf 'Type yes to continue: '; read -r ans
  [ "$ans" = "yes" ] || { echo "Aborted - nothing changed."; exit 1; }
fi
echo

for p in $batch; do "$ROOT/scripts/disable.sh" "$p"; done

echo
echo "Batch done. Next: scripts/wait-for-boot.sh --reboot, then test Home, HDMI, remote and voice."
[ "$rest" -gt 0 ] && echo "After that, run the same command again for the remaining $rest."
exit 0
