// Evert Boelaert
// S²E²C algorithm

// Sender mote broadcasts packets <Ai, lbl, dat>
// Receiver receives packets and puts them into arrays packet_set[] according to NMote ID.
// Receiver acknowledges packets by sending ACK <ldai, lbl> messages back to Sender.

// Ai = Alternating Index
// lbl = Label
// dat = data (message)
// ldai = Last Delivered Alternating Index

#include <printf.h>

configuration SendAppC {
}

implementation {
  components SendC;
  components MainC;
  components PrintfC;
  components SerialStartC;
  components ActiveMessageC;
  components new AMSenderC(AM_MSG);
  components new AMReceiverC(AM_ACK);
  components new TimerMilliC() as Timer0;

  SendC.Boot -> MainC;
  SendC.AMControl -> ActiveMessageC;
  SendC.AMSend -> AMSenderC;
  SendC.Receive -> AMReceiverC;
  SendC.Timer0 -> Timer0;
  SendC.Packet -> AMSenderC;
  SendC.AMPacket -> AMSenderC;
}
