#!/bin/sh

#composite -compose bumpmap -gravity center $1 paper.png /tmp/1.png
composite -gravity center $1 paper.png /tmp/1.png

convert /tmp/1.png \
    \( +clone -threshold -1 -virtual-pixel black \
         -spread 10 -blur 0x3 -threshold 50% -spread 1 -blur 0x.7 \) \
           +matte -compose Copy_Opacity -composite /tmp/2.png
           #+matte -compose Copy_Opacity -composite /tmp/2.png

#convert /tmp/2.png -matte \( +clone -fill red -shadow 40x0+2+2 \) +swap \
  #-background none -mosaic -crop 80x60+0+0 /tmp/3.png

convert /tmp/2.png -fill white -font FreeSans-Bold -stroke black -pointsize 14 \
    -annotate +0+58 "Lvl $3" /tmp/3.png

composite -gravity NorthEast \( -resize 24x24 -sharpen 2 ../meta/icon.png \) /tmp/3.png $2
