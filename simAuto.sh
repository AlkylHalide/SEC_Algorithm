# AUTOMATIC SIMULATION SCRIPT OUTLINE

# TO_DO/IDEAS
# Scan 'excooja' output for certain strings and note corresponding values
# 1) seed: "Simulation random seed: X"
# 2) receiver serial port: delete the sender serial sender module. The only
# output will then be of the receiver serial module
# --> INFO [main] (SerialSocketServer.java:389) - Listening on port: 60002


# ARG1 = simulation XML bv. First-Attempt/Simulations/FirstAttempt.csc

# i=0
# while(i<50){
#   # Open new terminal that connects to serial port
  #  gnome-terminal -e command
#   tosprint cooja PORT_NUMBER
#
#   # Switch back to first terminal
#   excooja $1 nogui
# }

> /home/evert/tinyos-main/apps/SEC/PID.txt

. /home/evert/tinyos-main/apps/SEC/coojasim.sh &
. /home/evert/tinyos-main/apps/SEC/serial_connect.sh &
wait
echo "Processes complete"
