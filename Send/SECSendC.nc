// Evert Boelaert
// S²E²C algorithm

// Sender mote broadcasts packets <Ai, lbl, dat>
// Receiver receives packets and puts them into arrays packet_set[] according to NMote ID.
// Receiver then acknowledges packets by sending ACK <ldai, lbl> messages back to Sender.

// Ai = Alternating Index
// lbl = Label
// dat = data (message)
// ldai = Last Delivered Alternating Index

#include "SECSend.h"
#include <printf.h>

configuration SECSendC {
}

implementation {
  components SECSendP;
  components MainC;
  components LedsC;
  // components ActiveMessageC;
  // components new AMSenderC(AM_SECMSG);
  // components new AMReceiverC(AM_ACKMSG);
  components new TimerMilliC() as Timer0;

  components RPLRankC;
  components RPLRoutingEngineC;
  components IPDispatchC;
  components RPLDAORoutingEngineC;
  components IPStackC;
  components IPProtocolsP;
  components new UdpSocketC() as RPLUDP;
      
  SECSendP.Boot -> MainC;
  // SECSendP.AMControl -> ActiveMessageC;
  SECSendP.AMControl -> IPStackC;
  SECSendP.Leds -> LedsC;
  // SECSendP.AMSend -> AMSenderC;
  // SECSendP.Receive -> AMReceiverC;
  SECSendP.Timer0 -> Timer0;
  // SECSendP.Packet -> AMSenderC;
  // SECSendP.AMPacket -> AMSenderC;

  SECSendP.RPLRoute -> RPLRoutingEngineC;
  SECSendP.RootControl -> RPLRoutingEngineC;
  SECSendP.RoutingControl -> RPLRoutingEngineC;
  SECSendP.RPLUDP -> RPLUDP;
  SECSendP.RPLDAO -> RPLDAORoutingEngineC;

  #ifdef RPL_ROUTING
    components RPLRoutingC;
  #endif

  #ifdef PRINTFUART_ENABLED
    components PrintfC;
    components SerialStartC;
  #endif
}