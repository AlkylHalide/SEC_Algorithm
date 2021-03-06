#!/bin/bash

reset
# set style line 1 lc rgb '#8b1a0e' pt 1 ps 1 lt 1 lw 2 # --- red
# set style line 11 lc rgb '#808080' lt 1
set style line 1 lc rgb '#8b1a0e' pt 1 ps 1 lt 1 lw 2 # --- red
set style line 2 lc rgb '#5e9c36' pt 6 ps 1 lt 1 lw 2 # --- green
set border 3 back ls 11
set tics nomirror
set style line 12 lc rgb '#808080' lt 0 lw 1
set grid back ls 12
# set title "Packet labels vs. data - unaltered communication"
set title "Packet labels vs. data - altered communication"
set xlabel "Packet data"
set ylabel "Packet label"
set key off
set term png
set output "lblvsdataAlt.png"
# set output "lblvsdata.png"
plot 'Input/lblVsData.txt' using 1:2 with lines, 'Input/lblVsDataAlt.txt' using 1:2 with points
# plot "Input/lblVsData.txt" using 1:2 with lines
