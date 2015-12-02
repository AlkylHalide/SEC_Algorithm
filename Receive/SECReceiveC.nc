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
      new AMSenderC(AM_ACKMSG),
      new AMReceiverC(AM_SECMSG),
      new TimerMilliC() as Timer0,
      LedsC;

  /******** RPL ROUTING **********/
  components RPLRankC;
  components RPLRoutingEngineC;
  components IPDispatchC;
  //components RPLForwardingEngineC;
  components RPLDAORoutingEngineC;
  components IPStackC;
  components IPProtocolsP;
  /******** RPL ROUTING **********/
      
  SECReceiveP.Boot -> MainC;
  // SECReceiveP.AMControl -> ActiveMessageC;
  SECReceiveP.Leds -> LedsC;
  SECReceiveP.AMSend -> AMSenderC;
  // SECReceiveP.Receive -> AMReceiverC;
  // SECReceiveP.PacketAcknowledgements -> ActiveMessageC;
  SECReceiveP.Timer0 -> Timer0;
  SECReceiveP.Packet -> AMSenderC;      
  SECReceiveP.AMPacket -> AMSenderC;

  /******** RPL ROUTING **********/
  SECReceiveP.AMControl -> IPStackC;//IPDispatchC;
  SECReceiveP.RPLRoute -> RPLRoutingEngineC;
  SECReceiveP.RootControl -> RPLRoutingEngineC;
  SECReceiveP.RoutingControl -> RPLRoutingEngineC;

  components new UdpSocketC() as RPLUDP;
  SECReceiveP.RPLUDP -> RPLUDP;

  SECReceiveP.RPLDAO -> RPLDAORoutingEngineC;
  // SECReceiveP.Random -> RandomC;

  #ifdef RPL_ROUTING
    components RPLRoutingC;
  #endif

  // #ifdef PRINTFUART_ENABLED
  //   components PrintfC;
  //   components SerialStartC;
  // #endif
  /******** RPL ROUTING **********/
}