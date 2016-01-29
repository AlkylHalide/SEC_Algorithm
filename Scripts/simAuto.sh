#!/bin/bash

dir=`pwd`
# . /home/evert/tinyos-main/apps/SEC/coojasim.sh &
# . /home/evert/tinyos-main/apps/SEC/serial_connect.sh &
. $dir/coojasim.sh $dir &
. $dir/serial_connect.sh &
wait
echo "Processes complete"
