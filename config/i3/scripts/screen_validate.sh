#!/bin/sh
if xrandr | grep -i "HDMI1 connected 2560x1440"; then
xrandr --output HDMI1 --mode 2560x1440 --pos 0x0 --rotate normal --output VIRTUAL1 --off --output eDP1 --mode 1366x768 --pos 496x1440 --rotate normal
else
	echo 'Monitor not detected'
fi
