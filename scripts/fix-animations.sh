#!/usr/bin/env bash
# Put the animation scales back to Fire OS defaults.
# Fixes "Settings / the side panel won't open" after a "speed up your Fire TV" tip set them
# to 0.5 or 0. Do NOT lower these on Fire OS 8 - see README > Things that look like a good idea.
. "$(dirname "$0")/lib.sh"
tv_connect
tvsh settings put global window_animation_scale 1.0 >/dev/null
tvsh settings put global transition_animation_scale 1.0 >/dev/null
tvsh settings delete global animator_duration_scale >/dev/null
echo "Animations restored: window=$(tvsh settings get global window_animation_scale)  transition=$(tvsh settings get global transition_animation_scale)  animator=$(tvsh settings get global animator_duration_scale)"
