#!/usr/bin/env sh
[[ -f "$1" ]] || { echo "Not a file."; exit 1; }
ffmpeg -v 0 -stats -i $1 output.mp3

[[ -d "./frames" ]] && rm -rf frames
mkdir -pv frames
ffmpeg -v 0 -stats -i $1 -r $2 -s $3 -f image2 frames/frame-%0d.png
