> /home/evert/tinyos-main/apps/SEC/output.txt
excooja /home/evert/tinyos-main/apps/SEC/First-Attempt/Simulations/FirstAttempt.csc nogui | {
  while IFS= read -r line
  do
    echo "$line" >> /home/evert/tinyos-main/apps/SEC/output.txt
  done
}
