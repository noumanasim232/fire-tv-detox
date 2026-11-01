#!/usr/bin/env bash
# Show what each list would do on THIS TV. Changes nothing.
# For every lists/0*.txt: would disable / already disabled / not on this TV / refused by never-touch.
# Also counts the packages that are in no list (they are left alone) -> state/not-in-any-list.txt
. "$(dirname "$0")/lib.sh"
tv_connect

all="$(tvsh pm list packages    | sed 's/^package://' | awk 'NF' | sort)"
dis="$(tvsh pm list packages -d | sed 's/^package://' | awk 'NF' | sort)"
prot="$(cat "$STATE/protected-skipped.txt" 2>/dev/null)"
reen="$(cat "$STATE/reenabled-by-system.txt" 2>/dev/null)"
listed=""

for f in "$LISTS"/0*.txt; do
  would=""; already=""; missing=""; guarded=""; protected=""; reenabled=""
  while IFS= read -r p; do
    listed="$listed$p\n"
    if is_never_touch "$p"; then guarded="$guarded$p\n"
    elif ! printf '%s\n' "$all" | grep -qx -- "$p"; then missing="$missing$p\n"
    elif printf '%s\n' "$dis" | grep -qx -- "$p"; then already="$already$p\n"
    elif printf '%s\n' "$prot" | grep -qx -- "$p"; then protected="$protected$p\n"
    elif printf '%s\n' "$reen" | grep -qx -- "$p"; then reenabled="$reenabled$p\n"
    else would="$would$p\n"; fi
  done < <(read_list "$f")

  echo "== lists/$(basename "$f")"
  [ -n "$would" ]     && { echo "  would disable:";                                        printf "$would"     | sed 's/^/    /'; }
  [ -n "$already" ]   && { echo "  already disabled:";                                     printf "$already"   | sed 's/^/    /'; }
  [ -n "$protected" ] && { echo "  protected on this TV (Fire OS refused before - skipped):"; printf "$protected" | sed 's/^/    /'; }
  [ -n "$reenabled" ] && { echo "  Fire OS turns these back on at boot (skipped):";         printf "$reenabled" | sed 's/^/    /'; }
  [ -n "$missing" ]   && { echo "  not on this TV:";                                       printf "$missing"   | sed 's/^/    /'; }
  [ -n "$guarded" ]   && { echo "  refused by lists/never-touch.txt:";                     printf "$guarded"   | sed 's/^/    /'; }
  [ -z "$would$already$missing$guarded$protected$reenabled" ] && echo "  (nothing active - every line in this file is commented out; uncomment what you want gone)"
  echo
done

unlisted="$(comm -23 <(printf '%s\n' "$all") <(printf "$listed" | awk 'NF' | sort -u) | awk 'NF')"
printf '%s\n' "$unlisted" > "$STATE/not-in-any-list.txt"
echo "== $(printf '%s\n' "$unlisted" | awk 'NF' | wc -l | tr -d ' ') packages are in no list and will be left alone (state/not-in-any-list.txt)."
echo "   Disabled on the TV right now: $(printf '%s\n' "$dis" | awk 'NF' | wc -l | tr -d ' ')"
