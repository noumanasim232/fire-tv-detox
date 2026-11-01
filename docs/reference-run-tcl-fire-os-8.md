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

## Home screen thin-out (1 November 2026)

The owner wanted the "only apps" home screen seen in YouTube videos. The first step was to look for a setting that does it. Every relevant Settings page was read: Preferences (Parental Controls, Privacy Settings, Data Usage Monitoring, Notification Settings, Featured Content, Time Zone, Language, Metric Units, Standby LED), Applications, Display & Sounds, and Live TV. **None of them has a switch for home-screen rows.**

Changed with the remote and read back afterwards:

| Setting | Before | After |
|---|---|---|
| Featured Content → Allow Video Autoplay | ON | **OFF** |
| Featured Content → Allow Audio Autoplay | ON | **OFF** |
| Privacy → Manage Sharing from Apps → Share App Viewing and Content Info | ON | **OFF** (this also hides *Manage Participating Apps* and *Sync Across Devices*) |
| Privacy → Interest-based Ads | OFF | OFF |
| Privacy → Device Usage Data, Collect App and Over-the-Air Usage Data | OFF | OFF |

Also found:

- Preferences → Notification Settings no longer opens. The log shows `ActivityNotFoundException ... NOTIFICATION_SETTING`, because the page belongs to `com.amazon.tv.notificationcenter`, which batch 5 disabled.
- `com.amazon.media.recommendations` had been disabled since batch 5, and the rows were all still there, so it doesn't feed them.
- Live TV showed 845 channels from synced sources. *Sync Sources* was left alone.

The home screen afterwards, top to bottom: featured banner (still images), Next up for you, Your apps and channels, Sponsored, Continue watching, 2026 Midterm Elections Latest News, Play games on Fire TV, Sponsored: This week on Fire TV, 2026 Elections: Get Ready, On now, Sponsored: More ways to enjoy your TV, Clips and videos for you, Sponsored: Entertainment, Recently used apps. That's 13 rows, 4 of them sponsored. It's calmer, but it's not "only apps".

While the pages were being mapped with ADB key presses, one press landed on *Interest-based Ads* while it was OFF and switched it ON with no confirmation. It was switched off again through its *Turn Off* dialog and checked (the settings store shows `interestBasedAds:value=0`). That's where the rule "read the value before every press" comes from.

## Apps-only home screen, second attempt (kept, 1 November 2026)

After the thin-out, the owner still wanted only *Your apps* and *Continue watching*. No setting removes the other rows, so the launcher went back on, this time set up for a clean screen:

- **Projectivy 4.73** reinstalled from the same APK (SHA-256 checked). Onboarding: allowed *read TV listings*; declined notification access and usage/crash reports.
- **Layout:** the *Favorites* category was made visible with eight apps: Disney+, Hulu, Netflix, NordVPN, Prime Video, YouTube, Silk and Tubi. *TV Apps*, *Mobile Apps* and *Settings* were hidden. Amazon's *Your apps and channels* row had 24 tiles, but most were promoted apps and channels that weren't installed.
- **Home button, try 1: Projectivy's own *Override current launcher*** (its accessibility service enabled with `settings put secure enabled_accessibility_services com.spocky.projengmenu/.services.ProjectivyAccessibilityService`). Home worked, but **Settings broke**. The log shows the chain: Projectivy's *Android settings* → `android.settings.SETTINGS` → `com.amazon.tv.settings.v2/.compliance.CTSDummySettingsHandler` → Amazon's `HomeActivity_vNext` → `MainSettingsActivity`. The override caught the HOME call and Settings closed again.
- **Home button, try 2: Home on Fire 1.5.2** (Projectivy's override off, its service removed). Target Projectivy, *Replace Home* on, *Escape to Amazon home* long-press on, double-press **off**, *Launch on boot* on. Everything worked: Home → Projectivy from apps and Settings, hold Home → Amazon's home screen, Netflix and Prime Video open normally. The owner tested Home, HDMI, remote and voice: all fine.
- **Timing:** Home still makes Fire OS start Amazon's home screen (uid 0), and Home on Fire (uid 10240) then starts Projectivy 1.4 s, 2.3 s and 4.2 s after the press in three runs. The 4.2 s run was with Amazon's launcher cold (it took 2.9 s to draw). The gear's *Android settings* still bounces, because Fire OS routes it through Amazon's home screen.
- **Memory after a reboot:** about 89 MB for Projectivy, about 7.5 MB for Home on Fire (idle; 58–86 MB while its settings screen is open) and about 134 MB for Amazon's launcher. Free memory was 612 MB, against 623 MB before the reinstall.
- **ADB after the reboot:** the port stayed closed for more than 10 minutes. Switching ADB Debugging off and on opened it immediately.

## Privacy audit: ACR and ad tracking (1 November 2026)

The owner asked whether the TV records what's on screen (ACR), as reported for LG and Samsung TVs. The findings:

- **`com.amazon.tv.acr` had been disabled since batch 1.** It's a 6.7 KB stub at `/system_ext/priv-app/com.amazon.tv.acr-stub/`, with a 516-byte `classes.dex` and no update installed (`lastUpdateTime` is the factory default). It contains no server names and no capture code, so ACR never ran on this TV. Its manifest still asks for `RECORD_AUDIO`, `HDMI_CEC`, key events and account access. Other stubs (Prime Video, Silk, AirPlay) had been replaced by full apps through updates, which is why it's worth keeping this one disabled.
- **There's no ACR switch** on this TV's Privacy Settings page, and no third-party ACR app is installed (Samba TV, Alphonso, Inscape, Gracenote or anything from TCL).
- **Ad tracking:** `limit_ad_tracking=1`, `amz_limit_ad_tracking=1` and Interest-based Ads `0`. The ad-ID service `com.amazon.hybridadidservice` is disabled. An undocumented key, `non_amz_limit_ad_tracking=0`, was left alone.
- **On-screen switches** (checked by reading the screen): Device Usage Data off, Collect App and Over-the-Air Usage Data off, Share App Viewing and Content Info off.
- **DNS:** AdGuard blocks `device-metrics-us.amazon.com` and `doubleclick.net`. `gateway-ink.amazon.com` (Fire TV's ACR server, according to the Northeastern study) still resolves, which doesn't matter while the ACR app is disabled.
- **Apps allowed to record audio or read the screen:** `vizzini` (Alexa), `tv.ime`, `tv.settings.v2`, `rtcsessioncontroller` (Alexa calling), `audiolatencymeasurer`, plus `kindleconnect` and `tv.acr` (both disabled). The one that stood out is **`com.amazon.hedwig`, Fire TV Channels**, updated 14 October 2026, which holds `READ_FRAME_BUFFER`, `CAPTURE_AUDIO_OUTPUT` and `RECORD_AUDIO`. A scan of its code found its own servers (`podiumedgeservice.amazon.com`, `podium-engagement-na.amazon.com`, metrics on `minerva.devices.a2z.com`) but no ACR server and no screen-capture calls. It was added to list 05 so owners can choose.

`scripts/privacy-check.sh` was written from this audit.

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

- Boot to home screen: ~40–50 s. ADB port open: anywhere from immediately to several minutes. Once it stayed closed for more than 10 minutes, and switching ADB Debugging off and on opened it at once.
- The launcher drops remote presses while finishing startup ("Still no focused window. Will drop the event in 4999ms"), for 10–60 s. The first "Settings won't open" report during this run was *this*, before the animation-scale breakage was found — don't confuse the two.
- `com.amazon.vizzini` (Alexa UI + screensaver) threw a 32 s ANR during one boot under memory pressure; it recovered on its own.
- NordVPN did not auto-start after a reboot (its own setting).

## Lessons

1. Disable only. Log everything. Reboot and test between batches. It is slower and it is why nothing broke.
2. Fire OS protects some packages and re-enables others at boot. Skip them; use DNS for what they talk to.
3. Animation-scale tweaks are not harmless here.
4. Wait for the home screen after a reboot before judging anything.
5. A custom launcher won't make a 1.8 GB TV faster: Amazon's launcher stays loaded and still opens on every Home press. Install one for a clean screen, use Home on Fire for the Home button, and never use Projectivy's own override.
6. The detox makes the OS lighter; it cannot make Netflix's servers faster. Say so up front.
7. No setting removes the stock launcher's rows. The settings can stop autoplay and personalisation; for "only apps" you need a different launcher.
8. On Fire TV settings pages, one press on a switch changes it. Read the value first.
