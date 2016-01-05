#!/bin/bash

# Usage: ./automate src dest iteration [seed]
# This script was kindly provided to me by Henning Phan

###############################
#
# Functions
#
###############################

# $1 src, absolute path to .csc file
# $2 dest absolute path to destination folder
# $3 app value to be appended to file
move_all(){
  if (($# != 3)); then
    echo "usage: move_all src dest app"
    exit 1;
  fi
  cooja_log="${1:0:-3}cooja_log"
  mv "$cooja_log" "$2/${cooja_log##*/}$3"  || (echo "mv cooja_log failed" && exit 1)
  log="${1:0:-3}log"
  mv "$log" "$2/${log##*/}$3"  || (echo "mv log failed" && exit 1)

}

###############################
#
# Argument checking
#
###############################

# Number of arguments are valid
if (( $# < 3 || $# >4)) ;then
  echo "usage $0 src dest iteration [seed]";
  echo "seed is the base seed value, each iteration will increment it"
  echo "if no seed is provided seed will start at 0"
fi

# Does src file exist
src=$(readlink -f "$1")
if [[ ! -f "$1" ]]; then
  echo "error: file $1 does not exist"
  exit 1;
fi

# Does dest directory exist?
dest=$(readlink -f "$2")
if ! [[ -d $dest ]]; then
  echo "error: $2 is not a directory";
  exit 2;
fi
# is number of iteration a positive integer
if ! [[ $3 =~ ^[1-9]+[0-9]*$ ]] ;then
  echo "error: iteration must be positive integer"
  exit 1;
fi
iterations=$3

# is the seed a positive integer?
seed=0;
if (($#==4)) ; then
  if ! [[ $4 =~ ^[1-9]+[0-9]*$ ]] ;then
    echo "error: seed must be positive integer"
    exit 1;
  fi
  seed=$4
fi

###############################
#
# Execution
#
###############################

# cd /home/henning/contiki-2.7/tools/cooja/test/
cd /home/evert/Contiki/tools/cooja/test/
for (( i=1; i <= $iterations;++i ));do
  echo "############################## TEST iteration: $i seed: $seed ##############################"
  sed -i "s|<randomseed>.*</randomseed>|<randomseed>${seed}</randomseed>|" "$src"
  # run test and move files to correct folder :)
  ((++seed))
  time bash RUN_TEST ${src:0:-4} | grep "Test script at"
  move_all $src $dest $seed
done
echo "$1"
