#!/bin/bash

> /home/evert/tinyos-main/apps/SEC/logTest.txt
BULLSEYE=false
until [[ $BULLSEYE == true ]]; do
  if [[ $(grep 'Test script activated' /home/evert/tinyos-main/apps/SEC/Scripts/sim_output.txt) ]]; then
    BULLSEYE=true
    # tosprint cooja 60002 > /home/evert/tinyos-main/apps/SEC/logTest.txt
    tosprint cooja 60002 | {
      while IFS= read -r line
      do
        echo "$line" >> /home/evert/tinyos-main/apps/SEC/logTest.txt
        if [[ $(grep '16000' /home/evert/tinyos-main/apps/SEC/logTest.txt) ]]; then
          kill $(ps | grep 'java' | awk '{print $1}')
          sed -i.bak '/Thread[Thread-1,5,main]/d' /home/evert/tinyos-main/apps/SEC/logTest.txt
          exit 0
          # kill $(ps au | grep 'java cooja.jar' | awk '{print $2}')
          # kill $(ps au | grep 'java net.tinyos.tools.PrintfClient' | awk '{print $2}')
        fi
      done
    }
  fi
done
