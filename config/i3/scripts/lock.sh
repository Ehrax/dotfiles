#!/bin/zsh
import -window root /tmp/lock-screen.png
convert -blur 0x8 /tmp/lock-screen.png /tmp/lock-screen.png
i3lock -i /tmp/lock-screen.png 
