#!/bin/bash

# Instead of typing the whole printf + serial connection command
# everytime in the terminal, this script provides the easy
# function tosprint()

# USAGE: 'tosprint ARG1 ARG2'

# ARG1 is either "cooja" or "hw", without quotation marks
# cooja: specifies that you're using cooja and the serial server
# function of the mote
# hw: short for hardware, means you're working with physical motes

# ARG2 specifies the device you're going to connect to
# This depends on the input of ARG1
# ARG1 = cooja: ARG2 takes the serial port for the mote (e.g. 60001)
# ARG1 = hw: ARG2 takes the device name (e.g. ttyUSB0)

tosprint(){
	if [[ $1 == "cooja" ]]; then
		java net.tinyos.tools.PrintfClient -comm network@127.0.0.1:$2
	elif [[ $1 == "hw" ]]; then
		java net.tinyos.tools.PrintfClient -comm serial@/dev/$2:telosb
	fi
}
