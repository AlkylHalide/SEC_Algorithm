// Evert Boelaert
// S²E²C algorithm

// Sender mote broadcasts packets <Ai, lbl, dat>
// Receiver receives packets and puts them into arrays packet_set[] according to NMote ID.
// Receiver then acknowledges packets by sending ACK <ldai, lbl> messages back to Sender.

// Ai = Alternating Index
// lbl = Label
// dat = data (message)
// ldai = Last Delivered Alternating Index

#include "SECReceive.h"
#include <printf.h>

configuration SECReceiveC {
}

implementation {
  components SECReceiveP;
  components MainC;
  components LedsC;
  // components ActiveMessageC;
  // components new AMSenderC(AM_ACKMSG);
  // components new AMReceiverC(AM_SECMSG);
  components new TimerMilliC() as Timer0;

  components RPLRankC;
  components RPLRoutingEngineC;
  components IPDispatchC;
  components RPLDAORoutingEngineC;
  components IPStackC;
  components IPProtocolsP;
  components new UdpSocketC() as RPLUDP;
      
  SECReceiveP.Boot -> MainC;
  // SECReceiveP.AMControl -> ActiveMessageC;
  SECReceiveP.AMControl -> IPStackC;
  SECReceiveP.Leds -> LedsC;
  // SECReceiveP.AMSend -> AMSenderC;
  // SECReceiveP.Receive -> AMReceiverC;
  SECReceiveP.Timer0 -> Timer0;
  // SECReceiveP.Packet -> AMSenderC;      
  // SECReceiveP.AMPacket -> AMSenderC;

  SECReceiveP.RPLRoute -> RPLRoutingEngineC;
  SECReceiveP.RootControl -> RPLRoutingEngineC;
  SECReceiveP.RoutingControl -> RPLRoutingEngineC;
  SECReceiveP.RPLUDP -> RPLUDP;
  SECReceiveP.RPLDAO -> RPLDAORoutingEngineC;

  #ifdef RPL_ROUTING
    components RPLRoutingC;
  #endif

  #ifdef PRINTFUART_ENABLED
    components PrintfC;
    components SerialStartC;
  #endif
}