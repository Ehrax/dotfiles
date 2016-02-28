#! /bin/zsh
scrot '%Y-%m-%d_$wx$h_scrot.png' -e 'mv $f ~/Pictures/Screenshots'
sleep 0.1
Thunar ~/Pictures/Screenshots
