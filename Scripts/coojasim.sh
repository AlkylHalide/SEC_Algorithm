#!/bin/bash

# dir=`pwd`
> $1/sim_output.txt
. $1/excooja.sh /home/evert/tinyos-main/apps/SEC/First_Attempt/Simulations/FirstAttempt.csc nogui $1 | {
  while IFS= read -r line
  do
    echo "$line" >> $1/sim_output.txt
  done
}
