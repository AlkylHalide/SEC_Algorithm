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

configuration SECSendC {
}

implementation {
  components SECSendP,
      MainC,
      PrintfC,
      SerialStartC,  
      ActiveMessageC,
      // new AMSenderC(128),
      // new AMReceiverC(128),
      new AMSenderC(AM_SECMSG),
      new AMReceiverC(AM_ACKMSG),
      new TimerMilliC() as Timer0,
      LedsC;
      
  SECSendP.Boot -> MainC;
  SECSendP.AMControl -> ActiveMessageC;
  SECSendP.Leds -> LedsC;
  SECSendP.AMSend -> AMSenderC;
  SECSendP.Receive -> AMReceiverC;
  SECSendP.PacketAcknowledgements -> ActiveMessageC;
  SECSendP.Timer0 -> Timer0;
  SECSendP.Packet -> AMSenderC;
  SECSendP.AMPacket -> AMSenderC;
}