#!/usr/bin/env bash
# Privacy audit: ACR (automatic content recognition), ad tracking, telemetry, apps that can
# listen or capture the screen, and DNS. Changes nothing. Run it again after every Fire OS
# update, because updates can switch settings back on.
#   scripts/privacy-check.sh
. "$(dirname "$0")/lib.sh"
tv_connect

ok=0; todo=0
pass() { printf '  OK     %s\n' "$*"; ok=$((ok+1)); }
flag() { printf '  CHECK  %s\n' "$*"; todo=$((todo+1)); }
note() { printf '         %s\n' "$*"; }

installed="$(tvsh pm list packages | sed 's/^package://')"
disabled="$(tvsh pm list packages -d | sed 's/^package://')"
has()    { printf '%s\n' "$installed" | grep -qx -- "$1"; }
is_off() { printf '%s\n' "$disabled" | grep -qx -- "$1"; }
# A setting can live in secure, global or system; return the first value found.
setting() {
  local ns v
  for ns in secure global system; do
    v="$(tvsh settings get "$ns" "$1")"
    if [ -n "$v" ] && [ "$v" != "null" ]; then echo "$v"; return; fi
  done
  echo null
}

echo "ACR - automatic content recognition (fingerprints antenna TV and HDMI input)"
acr=com.amazon.tv.acr
if ! has "$acr"; then
  pass "$acr is not installed"
else
  path="$(tvsh pm path "$acr" | sed 's/^package://' | head -1)"
  case "$path" in
    /data/*) kind="full app, downloaded as an update" ;;
    *-stub*) kind="placeholder stub with no capture code; an update can replace it" ;;
    *)       kind="system app" ;;
  esac
  if is_off "$acr"; then pass "$acr is disabled ($kind)"
  else flag "$acr is ENABLED ($kind) - run: scripts/disable.sh $acr"; fi
fi
others="$(printf '%s\n' "$installed" | grep -iE 'samba|alphonso|inscape|gracenote' || true)"
if [ -z "$others" ]; then pass "no third-party ACR apps (Samba TV, Alphonso, Inscape, Gracenote)"
else flag "third-party ACR app(s) installed: $(printf '%s' "$others" | tr '\n' ' ')"; fi

echo; echo "Advertising ID"
lat="$(setting limit_ad_tracking)"
if [ "$lat" = "1" ]; then pass "limit_ad_tracking=1 - apps are told not to use the ad ID for interest-based ads"
else flag "limit_ad_tracking=$lat - turn Interest-based Ads off (Settings > Preferences > Privacy Settings)"; fi
iba="$(setting 'advertisingIdApp:interestBasedAds:value')"
case "$iba" in
  0)    pass "Interest-based Ads is off" ;;
  null) note "Interest-based Ads: not readable over ADB on this TV - check it on screen" ;;
  *)    flag "Interest-based Ads is on ($iba) - Settings > Preferences > Privacy Settings" ;;
esac
if has com.amazon.hybridadidservice; then
  if is_off com.amazon.hybridadidservice; then pass "advertising-ID service (com.amazon.hybridadidservice) is disabled"
  else flag "advertising-ID service is enabled - it's in lists/01-tracking-and-ads.txt"; fi
fi

echo; echo "Telemetry and ad services (lists/01-tracking-and-ads.txt)"
n_off=0; n_prot=0; n_gone=0; on=""
while IFS= read -r p; do
  if ! has "$p"; then n_gone=$((n_gone+1))
  elif is_off "$p"; then n_off=$((n_off+1))
  elif grep -qx -- "$p" "$STATE/protected-skipped.txt" 2>/dev/null; then n_prot=$((n_prot+1))
  else on="$on $p"; fi
done < <(read_list "$LISTS/01-tracking-and-ads.txt")
if [ -z "$on" ]; then pass "$n_off disabled, $n_prot protected by Fire OS (can't be disabled), $n_gone not on this TV"
else flag "still enabled:$on - run: scripts/disable-list.sh lists/01-tracking-and-ads.txt"; fi

echo; echo "Apps allowed to record audio or capture the screen (information only)"
tvsh dumpsys package | awk '
  /^  Package \[/ { pkg = $2; gsub(/\[|\]/, "", pkg); next }
  /: granted=true/ {
    if (match($0, /(RECORD_AUDIO|CAPTURE_AUDIO_OUTPUT|CAPTURE_AUDIO_HOTWORD|CAPTURE_VIDEO_OUTPUT|CAPTURE_SECURE_VIDEO_OUTPUT|READ_FRAME_BUFFER):/)) {
      perm = substr($0, RSTART, RLENGTH - 1)
      if (index("," perms[pkg] ",", "," perm ",") == 0) perms[pkg] = (perms[pkg] == "" ? perm : perms[pkg] "," perm)
    }
  }
  END { for (p in perms) print p, perms[p] }' | sort | while read -r p perms; do
    if is_off "$p"; then state="disabled"; else state="enabled"; fi
    printf '         %-42s %-9s %s\n' "$p" "$state" "$perms"
  done
note "Alexa (vizzini), the keyboard (tv.ime) and Settings need the remote's microphone for voice."
if has com.amazon.hedwig && ! is_off com.amazon.hedwig; then
  note "com.amazon.hedwig is Fire TV Channels (free live channels). No ACR was found in its code, but it can"
  note "read the screen; if you don't watch those channels, it's in lists/05-your-choice.txt."
fi

echo; echo "DNS"
mode="$(tvsh settings get global private_dns_mode)"; srv="$(tvsh settings get global private_dns_specifier)"
if [ "$mode" = "hostname" ]; then pass "Private DNS: $srv"
else note "Private DNS is off (mode=$mode) - optional: scripts/dns.sh set"; fi
for h in gateway-ink.amazon.com device-metrics-us.amazon.com doubleclick.net; do
  ip="$(tvsh ping -c1 -W3 "$h" | head -1 | sed -n 's/^PING [^ ]* (\([0-9.]*\)).*/\1/p')"
  case "$ip" in ""|0.0.0.0|127.0.0.1) note "$h -> blocked" ;; *) note "$h -> reachable ($ip)" ;; esac
done
note "gateway-ink.amazon.com is Fire TV's ACR server (Northeastern University, 2026). Public AdGuard"
note "doesn't block it; that's fine while the ACR app is disabled. Add it to a Pi-hole or NextDNS list to block it too."

echo; echo "On-screen switches ADB can't read - check them once on the TV (Settings > Preferences > Privacy Settings):"
note "[ ] Automatic Content Recognition -> Off   (only some Fire TV models have this switch)"
note "[ ] Device Usage Data -> Off"
note "[ ] Collect App and Over-the-Air Usage Data -> Off"
note "[ ] Manage Sharing from Apps > Share App Viewing and Content Info -> Off"

echo; echo "Summary: $ok OK, $todo to check."
