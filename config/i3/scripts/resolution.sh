#!/bin/bash
case "$1" in
    university)
        xrandr --output HDMI1 --mode 2560x1440 --pos 0x0 --rotate normal --output VIRTUAL1 --off --output eDP1 --primary --mode 1366x768 --pos 608x1440 --rotate normal
        nitrogen --restore
        ;;
        *)
        echo "Usage: $0 {university}"
        exit 2 2
esac
