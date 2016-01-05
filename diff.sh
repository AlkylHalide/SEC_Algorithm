#!/bin/bash

orig="/home/evert/tinyos-main/apps/SEC/logTest.txt"
testfile="/home/evert/tinyos-main/apps/SEC/DIFF_TEST.txt"

> $testfile

i=$(head -n 1 $orig)

cat $orig | {
  while IFS= read -r line
  do
    if [[ $line != $i ]]; then
      echo $line >> /home/evert/tinyos-main/apps/SEC/DIFF_TEST.txt
    fi
    i=$i+1
  done
}
