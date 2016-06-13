#! /bin/zsh
scrot '%Y-%m-%d-%H:%M:%S_$wx$h_scrot.png' -e 'mv $f ~/Media/Pictures/Screenshots'
sleep 0.1
Thunar ~/Media/Pictures/Screenshots
