#!/bin/bash

reset

set boxwidth 0.5
set style fill solid
set xlabel "Probability"
set ylabel "Iterations"
set title "First Attempt - Inital results with improved probability"
set yrange [0:19000]
set key off
set style line 1 lc rgb "#E62B17"
set style line 2 lc rgb "#1D4599"
set term png
set output "/home/evert/tinyos-main/apps/SEC/Graphs/TEST.png"
plot "/home/evert/tinyos-main/apps/SEC/Graphs/Input/TEST.dat" every ::0::0 using 1:3:xtic(2) with boxes ls 1, "/home/evert/tinyos-main/apps/SEC/Graphs/Input/TEST.dat" every ::1::9 using 1:3:xtic(2) with boxes ls 2
replot