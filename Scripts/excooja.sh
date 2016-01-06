#!/bin/bash

# I suggest putting the line below in your .bashrc file for ease of use
# The other option is to uncomment it, will work as well if you adjust it
# to match the location of your Contiki directory
# CONTIKI="/home/evert/Contiki"

# Usage: excooja ARG1 ARG2
# ARG1: *.csc simulation file
# ARG2: either leave this empty, or write "nogui" (without quotation marks)
# Leaving it empty starts Cooja with the selected simulation file opened
# Filling in "nogui" start Cooja from the command line, without a GUI

excooja(){
  CURRDIR=$(pwd)
  cd ~/Contiki/tools/cooja
	if [[ $1 == "run" ]]; then
		ant run 2> /home/evert/tinyos-main/apps/SEC/Scripts/textOutput/stderr.txt
	elif [[ ${1: -4} == ".csc" && -z "$2" ]]; then
    # java -mx512m -jar $CONTIKI/tools/cooja/dist/cooja.jar -quickstart=$CURRDIR"/"$1 -contiki=$CONTIKI
    java -mx512m -jar $CONTIKI/tools/cooja/dist/cooja.jar -quickstart=$1 -contiki=$CONTIKI 2> /home/evert/tinyos-main/apps/SEC/Scripts/textOutput/stderr.txt
  elif [[ ${1: -4} == ".csc" && $2 == "nogui" ]]; then
    # java -mx512m -jar $CONTIKI/tools/cooja/dist/cooja.jar -nogui=$CURRDIR"/"$1 -contiki=$CONTIKI
    java -mx512m -jar $CONTIKI/tools/cooja/dist/cooja.jar -nogui=$1 -contiki=$CONTIKI 2> /home/evert/tinyos-main/apps/SEC/Scripts/textOutput/stderr.txt
	fi
  cd $CURRDIR
}
