#!/usr/bin/env bash
# Private DNS (DNS over TLS) for ad and tracker blocking. Default server: AdGuard DNS.
#   scripts/dns.sh status
#   scripts/dns.sh set [server]    backs up the current values (first time only), sets Private DNS,
#                                  then runs the test
#   scripts/dns.sh test            resolves a few hosts; fails loudly if a host the TV needs is blocked
#   scripts/dns.sh restore         puts back state/dns-backup.txt
# Needs Android 9+ (Fire OS 7 or newer).
. "$(dirname "$0")/lib.sh"
cmd="${1:-status}"
server="${2:-${DNS_SERVER:-dns.adguard-dns.com}}"
B="$STATE/dns-backup.txt"

status() {
  echo "private_dns_mode=$(tvsh settings get global private_dns_mode)"
  echo "private_dns_specifier=$(tvsh settings get global private_dns_specifier)"
}

tv_connect
case "$cmd" in
  status) status ;;

  set)
    android="$(tvsh getprop ro.build.version.release | cut -d. -f1)"
    if ! [ "${android:-0}" -ge 9 ] 2>/dev/null; then
      echo "Private DNS needs Android 9+ (Fire OS 7+). This TV reports Android '${android}'." >&2; exit 1
    fi
    if [ ! -f "$B" ]; then status > "$B"; echo "Backed up the current values to state/dns-backup.txt"; fi
    tvsh settings put global private_dns_mode hostname >/dev/null
    tvsh settings put global private_dns_specifier "$server" >/dev/null
    status
    echo
    exec "$0" test ;;

  test)
    echo "Resolving through the TV (a blocked host shows 0.0.0.0 or 127.0.0.1):"
    bad=0
    for h in www.google.com www.netflix.com softwareupdates.amazon.com amzdigitaldownloads.edgesuite.net \
             atv-ext.amazon.com doubleclick.net device-metrics-us.amazon.com; do
      ip="$(tvsh ping -c1 -W3 "$h" | head -1 | sed -n 's/^PING [^ ]* (\([0-9.]*\)).*/\1/p')"
      case "$h" in doubleclick.net|device-metrics-us.amazon.com) want=blocked ;; *) want=ok ;; esac
      case "$ip" in ""|0.0.0.0|127.0.0.1) got=blocked ;; *) got=ok ;; esac
      mark="  "; [ "$want" = ok ] && [ "$got" = blocked ] && { mark="!!"; bad=1; }
      printf '%s %-36s %-8s %s\n' "$mark" "$h" "$got" "${ip:-no answer}"
    done
    echo
    if [ "$bad" -eq 1 ]; then
      echo "!! A host the TV needs is blocked or not resolving. Undo with: scripts/dns.sh restore" >&2; exit 1
    fi
    echo "OK: Amazon update/content servers and normal sites resolve. (Ad hosts show 'blocked' only if your DNS blocks them.)" ;;

  restore)
    [ -f "$B" ] || { echo "No state/dns-backup.txt - nothing to restore." >&2; exit 1; }
    while IFS== read -r k v; do
      [ -n "$k" ] || continue
      if [ "$v" = "null" ] || [ -z "$v" ]; then tvsh settings delete global "$k" >/dev/null
      else tvsh settings put global "$k" "$v" >/dev/null; fi
    done < "$B"
    status ;;

  *) echo "usage: scripts/dns.sh status | set [server] | test | restore" >&2; exit 2 ;;
esac
