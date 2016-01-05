> /home/evert/tinyos-main/apps/SEC/logTest.txt
until [[ $BULLSEYE == true ]]; do
  if [[ $(grep 'Test script activated' /home/evert/tinyos-main/apps/SEC/output.txt) ]]; then
    BULLSEYE=true
    tosprint cooja 60002 > /home/evert/tinyos-main/apps/SEC/logTest.txt
  fi
done
