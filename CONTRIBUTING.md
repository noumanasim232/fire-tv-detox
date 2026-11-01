# Contributing

The lists were verified on one TV. The most useful contribution is a report from a different one.

## Report a run

Open an issue (or a PR adding `docs/reference-run-<model>.md`) with:

1. The first four lines of `scripts/check.sh` (TV model, Fire OS version).
2. Which lists ran clean, and the four tests (Home, HDMI, remote, voice) passing after each.
3. Packages that came back `PROTECTED` (`state/protected-skipped.txt`).
4. Packages Fire OS re-enabled at boot (`scripts/check.sh` → "In the log but ENABLED").
5. Anything that broke, and which `scripts/restore.sh` fixed it.
6. Optional: `state/snapshots/<date>/meminfo.txt` before and after.
7. The output of `scripts/privacy-check.sh`. It never prints your advertising ID, and the IPs it shows are public server addresses.

Don't paste `tv.conf` or your snapshots' full package list unless you're happy with the apps you have installed being public.

## Package descriptions

The comments in `lists/*.txt` are best-effort. If you know what a package actually does, a one-line PR fixing the comment is welcome. Keep the format: `package  # description`.

## Adding a package to a list

Only after it has been disabled on a real TV, survived a reboot, and passed the four tests. Say which TV in the PR. Anything that touches input, HDMI, the remote, Alexa core, identity or updates belongs in `never-touch.txt`, not in a batch.

## Scripts

Bash 3.2-compatible (macOS ships that), no `mapfile`, no associative arrays. `bash -n scripts/*.sh` must pass. Keep each script short and single-purpose; `lib.sh` holds anything shared.
