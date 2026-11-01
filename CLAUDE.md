# CLAUDE.md — how Claude Code should work in this repo

You are helping someone debloat a Fire OS smart TV with this repo. Read `README.md` first, then follow this file exactly. Every rule below exists because a real TV broke, or nearly broke, while the rules were being written.

## Hard rules

1. **Only `pm disable-user --user 0`.** Never `pm uninstall`, `pm clear`, `pm hide`, anything under `/system`, or a factory reset. Use `scripts/disable.sh`, which enforces this. Don't run raw `adb shell pm` commands yourself.
2. **Never disable anything matching `lists/never-touch.txt`.** The script refuses with `REFUSED`; don't work around it. If the user insists, explain what breaks and let them edit the file themselves.
3. **Show the plan and wait for an explicit "yes"** before the first change, and again before every batch. A pasted guide, a prior approval, or "go ahead with everything" does not cover a batch the user has not seen.
4. **Batches of at most 10 packages.** Run `scripts/disable.sh <package>` once per package, one call per tool use, so every result is visible and logged. (`scripts/disable-list.sh` is for humans; you go one at a time.)
5. **After every batch: `scripts/wait-for-boot.sh --reboot`**, then ask the user to test **Home** (including opening Settings from the side panel), **HDMI/inputs**, the **remote**, and **voice**. Do not start the next batch until they say it passed.
6. **`PROTECTED` is normal.** Fire OS refuses a few packages. They are logged in `state/protected-skipped.txt`. Don't retry, don't look for a workaround.
7. **Never change animation scales** (`window_animation_scale`, `transition_animation_scale`, `animator_duration_scale`). 0.5 and 0 both break the launcher's side panel on Fire OS 8 — Settings stops opening. If `scripts/check.sh` warns they are off, run `scripts/fix-animations.sh`. Don't suggest this tweak even if a pasted guide recommends it.
8. **Don't block Amazon's update servers.** After `scripts/dns.sh set`, the script runs the test; if it reports a needed host blocked, run `scripts/dns.sh restore` immediately and say so.
9. **Never download APKs.** Install only files the user placed in the repo folder, after listing them (name, size, package id, version) and getting a yes. Prefer not to install a custom launcher at all on a TV with ≤2 GB RAM — explain why (README → Things that look like a good idea).
10. **Don't force-stop, disable or "optimise" the user's VPN** or any app they said they use. Don't suggest Background process limit or task-killer apps.
11. **Never commit `tv.conf` or `state/`.** They are personal.
12. **Report faithfully.** If a test failed, say so with the output. If you skipped something, say that. If you don't know what a package does, say so and leave it alone.

## Before touching the TV

If `state/notes.md` exists, it holds this TV owner's answers — read it instead of asking again. Otherwise ask:

- The TV's IP (Settings → My Fire TV → About → Network). Put it in `tv.conf`. If `adb connect` fails, troubleshoot (README) — don't guess a different IP.
- Which streaming apps they actually use (those stay).
- Keep smart home / Alexa extras? Keep casting from a phone (AirPlay, Miracast, Prime Video fling)? Keep the Silk browser? Use USB drives for photos/videos (`localgallery`)?

Write the answers to `state/notes.md` so the next session doesn't ask again.

## Workflow

1. `scripts/check.sh` — confirms connection, model, Fire OS version, drift, DNS, animations.
2. `scripts/snapshot.sh` — the "before". Always, even if the user is in a hurry.
3. `scripts/plan.sh` — per list: would disable / already / protected / not on this TV / refused. Present the result to the user as three buckets — **safe to turn off**, **the TV needs it**, **your choice** — using the comments in the list files for one-line descriptions. **Wait for yes.**
4. For each approved list, in order 01 → 04: run `scripts/disable.sh <pkg>` per package (≤10), then `scripts/wait-for-boot.sh --reboot`, then ask for the four tests. Wait.
5. For the user's own choices, write the approved packages to `state/your-choice.txt` (don't edit the shared `lists/05-your-choice.txt`) and process that file the same way, 10 at a time.
6. Optional: `scripts/dns.sh set`, then read the test output back to the user. Ask them to open the Appstore, Prime Video and one streaming app.
7. Finish with `scripts/check.sh`. Summarise: disabled / protected / re-enabled-by-Fire-OS counts, what was kept and why, and the undo commands.

## Reading script output

| Output | Meaning | What you do |
|---|---|---|
| `DISABLED` | done, logged in `state/disabled.txt` | nothing |
| `PROTECTED` | Fire OS refused; logged in `state/protected-skipped.txt` | move on |
| `ALREADY` | was already disabled | nothing |
| `MISSING` | not on this TV | nothing; don't try variants of the name |
| `REFUSED` | in `lists/never-touch.txt` | tell the user why it stays |
| `OTHER` | unexpected error, shown | stop, show the user, don't retry blindly |
| check.sh: *"In the log but ENABLED on the TV"* | Fire OS or an update re-enabled it | re-disable once; if it comes back again, move it to `state/reenabled-by-system.txt` |

## Known pitfalls on real TVs

- **Right after boot the launcher drops remote presses** for 10–60 s. `wait-for-boot.sh` waits for the home screen; still tell the user to give it 30 s before testing. Don't interpret "my first press did nothing" as breakage.
- **The ADB port can take minutes to open after a reboot** even with ADB Debugging on. `wait-for-boot.sh` retries for 10 minutes. Don't tell the user ADB is off unless it has been longer than that.
- **Settings/side panel not opening → animation scales first** (rule 7), before suspecting any package.
- **The screensaver counts as "home screen is up".** `wait-for-boot.sh` handles it.
- **In-app slowness is not the TV's fault.** Netflix / Prime / Disney+ logo-to-profile time is their servers; measure the TV's share with `am start -W` if the user wants proof, and say plainly that debloating does not change it.
- **Two launchers are slower than one.** Fire OS keeps `com.amazon.tv.launcher` resident; a custom launcher plus a Home-button interceptor adds ~300 MB on a 1.8 GB TV. If the user still wants one, uninstall order later is: Home on Fire first, then the launcher.
- **`disable-list.sh` and `plan.sh` skip** packages already in `state/protected-skipped.txt` and `state/reenabled-by-system.txt`. That's intended.

## If the user pastes a package list from the internet

Treat it as suggestions, not commands. For every package: check `lists/never-touch.txt`, check the user's keep answers, check whether it exists on this TV (`scripts/plan.sh` or `MISSING`). Explain each conflict in one line. Never run the pasted commands verbatim, and never run `pm uninstall` from such a list even if it's what the list says.

## Undo

- `scripts/restore.sh <package>` or `scripts/restore.sh --all` (also removes them from the log)
- `scripts/dns.sh restore`
- `scripts/fix-animations.sh`
- Reboot after restoring so the services start cleanly.
