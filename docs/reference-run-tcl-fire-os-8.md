# Reference run — TCL Fire TV, Fire OS 8.1.8.5

The complete log of the run this repo was built from, 31 October 2026. Device details, every batch with its result, the measurements, the two experiments that were reverted, and what was learned. Read it to calibrate expectations for your own TV.

## Device

| | |
|---|---|
| TV | TCL Fire TV, model `AFTDEC012E` (TCL "ginza" overlays, MediaTek SoC) |
| Fire OS | 8.1.8.5 (RS8185/3885), Android 11 |
| Hardware | 1.8 GB RAM, ~700 MB zram swap, 4 cores, ~9 GB storage |
| Packages installed before the run | 276 ([`tcl-fire-os-8-all-packages.txt`](tcl-fire-os-8-all-packages.txt)) |
| Disabled before the run | 0 |

Owner's choices: keep smart-home/Alexa extras, AirPlay, the Silk browser, Netflix, Disney+, Hulu, YouTube, Tubi and NordVPN. Remove Miracast, Prime Video fling, AirCast and the streaming apps not in use.

## Method

- `pm disable-user --user 0` only; never uninstall.
- Batches of at most 10, one `adb` call per package, each result logged.
- After each batch: reboot, wait for the home screen, then the owner tested Home (including Settings from the side panel), an HDMI input, the remote, and Alexa voice.
- "Cannot disable a protected package" → skipped and logged.

## Batches

### Batch 1 — tracking, logging, ads

| Package | Result |
|---|---|
| `com.amazon.tv.acr` | disabled |
| `com.amazon.device.crashmanager` | **protected** |
| `com.amazon.device.logmanager` | **protected** |
| `com.amazon.dp.logger` | disabled |
| `com.amazon.wirelessmetrics.service` | disabled |
| `com.amazon.device.telemetry.emitter` | disabled |
| `com.amazon.perfcollection` | disabled |
| `com.amazon.neo.minerva.logcat` | disabled |
| `com.amazon.hybridadidservice` | disabled |
| `com.amazon.ftvads.deeplinking` | **protected** |

Tests: all passed. (Voice worked but reported the weather for a city from the account's old device location — an Alexa-app setting, unrelated.)

### Batch 2 — promos and tutorials

| Package | Result |
|---|---|
| `com.amazon.kso.blackbird` | disabled |
| `com.amazon.tmm.tutorial` | disabled |
| `com.amazon.storm.lightning.tutorial` | disabled |
| `com.amazon.sneakpeek` | disabled |
| `com.amazon.tv.easyupgrade` | disabled |
| `com.amazon.tv.earlyaccess` | disabled |
| `com.amazon.tv.releasenotes` | disabled |
| `com.amazon.tv.democontent.provider` | disabled |
| `com.amazon.tv.csapp` | **protected** |
| `com.amazon.tv.support` | disabled |

Tests: all passed.

### Batch 3 — Amazon extras and AirCast

`smarthomemapviewapp` was left out at the owner's request (smart home kept).

| Package | Result |
|---|---|
| `com.amazon.shoptv.client` | disabled |
| `com.amazon.gamehub` | disabled |
| `com.amazon.minitv.android.app` | disabled |
| `com.amazon.bueller.photos` | disabled |
| `com.amazon.bueller.music` | disabled |
| `com.amazon.ods.kindleconnect` | disabled |
| `com.amazon.tv.website_launcher` | disabled |
| `com.amazon.tv.localgallery` | disabled |
| `com.azone.aircast` | disabled |

Tests: all passed.

### Batch 4 — casting and unused third-party apps

| Package | Result |
|---|---|
| `com.amazon.cast.sink` | disabled |
| `com.amazon.awvflingreceiver` | disabled |
| `com.discovery.discoveryplus.firetv` | disabled |
| `com.instagram.airwave` | disabled |
| `com.spotify.tv.android` | disabled |
| `com.amazon.spotify.mediabrowserservice` | disabled |
| `com.viki.kindle` | disabled |
| `tv.pluto.android` | disabled |
| `com.xite.amazon.coda` | disabled |
| `com.fox.fts.android` | disabled |

Tests (after reboot): all passed, including AirPlay.

### Batch 5 — remaining apps and community-list extras

| Package | Result |
|---|---|
| `com.fox.foxone` | disabled |
| `com.peacock.peacockfiretv` | disabled |
| `com.amazon.perfc` | disabled |
| `com.amazon.connectivitydiag` | disabled |
| `com.amazon.ceviche` | disabled |
| `com.amazon.privacypassservice` | disabled |
| `com.amazon.media.recommendations` | disabled — home rows stayed filled |
| `com.amazon.tv.notificationcenter` | disabled |
| `com.amazon.systemnotices` | disabled → **re-enabled by Fire OS at the next boot** |
| `com.amazon.tv.developer.dataservice` | disabled → **re-enabled by Fire OS at the next boot**; ADB kept working throughout |

Tests: all passed.

### Rejected from the community lists the owner pasted

| Package(s) | Why not |
|---|---|
| `com.amazon.cloud9` | the owner keeps the browser |
| `tv.alexaalerts`, `tv.alexanotifications`, `rtcsessioncontroller` | owner keeps smart home |
| `alexamediaplayer.runtime.ftv`, `alexa.externalmediaplayer.fireos`, `androidskillconnectioncapability`, `aca`, `audiohome` | Alexa core — voice would stop working |
| `com.amazon.shoptv.firetv.client`, `com.amazon.tv.fw.metrics` | not present on this TV |

### Totals

| | Count |
|---|---|
| Disabled and still disabled after the final reboot | **43** |
| Refused by Fire OS (protected) | 4 |
| Re-enabled by Fire OS at boot | 2 |
| Untouched | 227 |

## Ad and tracker blocking — AdGuard Private DNS

Before: `private_dns_mode=null`, `private_dns_specifier=null` (never set). Applied:

```
settings put global private_dns_mode hostname
settings put global private_dns_specifier dns.adguard-dns.com
```

Verified with the VPN connected and disconnected (`UsePrivateDns: true` reported by the TV):

| Host | Result |
|---|---|
| `www.google.com` | resolves |
| `softwareupdates.amazon.com`, `amzdigitaldownloads.edgesuite.net` (OTA) | resolve — **not blocked** |
| `atv-ext.amazon.com` (launcher content / Prime Video) | resolves |
| `doubleclick.net`, `device-metrics-us.amazon.com` | **blocked** (answer `127.0.0.1`) |

The owner confirmed the Appstore, Prime Video and Netflix all worked afterwards. The TV's own `/system/etc/hosts` was empty, so the blocking was the resolver's doing, not a local list.

## Experiment 1 — animation scales at 0.5 (reverted)

A common "cheap speed boost" tip: set `window_animation_scale`, `transition_animation_scale` and `animator_duration_scale` to 0.5.

**Result:** the launcher's left slide-out panel broke. Selecting *Settings*, *Appstore* or any other item just closed the panel back to Home; the owner tried ~15 times. The log showed `NavigationActivity: onStop with slideoutState=false, finishing to prevent stuck menu` on every press — the panel's close animation now finished before its selection handler ran. Settings launched fine via `am start` from ADB, which is how the cause was narrowed down to the launcher's own timing.

Restoring the defaults (1.0 / 1.0 / unset) fixed it on the next press. **Don't lower the animation scales on Fire OS 8.**

## Experiment 2 — custom launcher (reverted)

Installed from APKs the owner supplied: Projectivy Launcher 4.73 (`com.spocky.projengmenu`) and Home on Fire 1.5.2 (`io.github.toolicious.homeonfire`), with `pm grant io.github.toolicious.homeonfire android.permission.WRITE_SECURE_SETTINGS`. Setup on the TV: Accessibility service ON → target app Projectivy → Replace Home button ON → Escape to Amazon home = long-press → Launch on boot ON. It worked: Home opened Projectivy, long-press Home opened the stock launcher.

**Result:** the owner found it slightly *slower* than the (now debloated) stock launcher. Memory explained it:

| Resident | RSS |
|---|---|
| Projectivy | 137 MB |
| `com.amazon.tv.launcher` (cannot be disabled, stays resident) | 114 MB |
| Home on Fire | 58 MB |

~310 MB of a 1.8 GB TV on launchers, and every Home press takes an extra hop through the interceptor. Both were uninstalled (Home on Fire first, which returns the Home button to the stock launcher). Memory immediately after: 546 → 622 MB free.

## Measurements

| | Value |
|---|---|
| Free RAM after the final reboot (85 s uptime) | ~632 MB |
| Free swap after the final reboot | ~536 MB of ~700 MB |
| Swap in use, with two launchers vs. after removal | ~430 MB → ~180 MB |
| Netflix cold start → first screen (`am start -W`) | 1.4–1.6 s, unchanged by any of the above |
| Settings from the side panel | ~0.2–0.4 s |

No pre-detox memory baseline was captured (the snapshot script now does this for you). Subjectively: home screen and Settings noticeably snappier; in-app speed unchanged, because the slow part is the app talking to its servers.

## Reboot behaviour worth knowing

- Boot to home screen: ~40–50 s. ADB port open: anywhere from immediately to several minutes.
- The launcher drops remote presses while finishing startup ("Still no focused window. Will drop the event in 4999ms"), for 10–60 s. The first "Settings won't open" report during this run was *this*, before the animation-scale breakage was found — don't confuse the two.
- `com.amazon.vizzini` (Alexa UI + screensaver) threw a 32 s ANR during one boot under memory pressure; it recovered on its own.
- NordVPN did not auto-start after a reboot (its own setting).

## Lessons

1. Disable only. Log everything. Reboot and test between batches. It is slower and it is why nothing broke.
2. Fire OS protects some packages and re-enables others at boot. Skip them; use DNS for what they talk to.
3. Animation-scale tweaks are not harmless here.
4. Wait for the home screen after a reboot before judging anything.
5. A custom launcher on a 1.8 GB TV costs more than it saves, because the stock launcher never leaves memory.
6. The detox makes the OS lighter; it cannot make Netflix's servers faster. Say so up front.
