// Evert Boelaert
// S²E²C algorithm

// Sender mote broadcasts packets <Ai, lbl, dat>
// Receiver receives packets and puts them into arrays packet_set[] according to NMote ID.
// Receiver then acknowledges packets by sending ACK <ldai, lbl> messages back to Sender.

// Ai = Alternating Index
// lbl = Label
// dat = data (message)
// ldai = Last Delivered Alternating Index
 
#define NEW_PRINTF_SEMANTICS
#include <printf.h>

configuration SECReceiveC {
}

implementation {
  components SECReceiveP,
      MainC,
      PrintfC,
      SerialStartC,  
      ActiveMessageC,
      new AMSenderC(128),
      new AMReceiverC(128),
      new TimerMilliC() as Timer0,
      LedsC;
      
  SECReceiveP.Boot -> MainC;
  SECReceiveP.AMControl -> ActiveMessageC;
  SECReceiveP.Leds -> LedsC;
  SECReceiveP.AMSend -> AMSenderC;
  SECReceiveP.Receive -> AMReceiverC;
  SECReceiveP.PacketAcknowledgements -> ActiveMessageC;
  SECReceiveP.Timer0 -> Timer0;
  SECReceiveP.Packet -> AMSenderC;
  SECReceiveP.AMPacket -> AMSenderC;
}