#!/bin/bash

reset

set boxwidth 0.5
set style fill solid
set xlabel "Probability"
set ylabel "Iterations"
set title "Omitting packets"
set yrange [0:1100000]
# set title $1
set key off
set style line 1 lc rgb "blue"
set style line 2 lc rgb "red"
set term png
set output "/home/evert/tinyos-main/apps/SEC/Graphs/omitting_advanced.png"
# set output $2
# plot "Graphs/Input/omitting_advanced.dat" using 1:3:xtic(2) with boxes
plot "/home/evert/tinyos-main/apps/SEC/Graphs/omitting_advanced.dat" every ::0::0 using 1:3:xtic(2) with boxes ls 1, "/home/evert/tinyos-main/apps/SEC/Graphs/omitting_advanced.dat" every ::1::2 using 1:3:xtic(2) with boxes ls 2
# plot $3 using 1:3:xtic(2) with boxes
replot

set style fill solid
set boxwidth 0.5
