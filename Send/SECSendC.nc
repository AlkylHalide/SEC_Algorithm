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
      new AMSenderC(AM_SECMSG),
      new AMReceiverC(AM_ACKMSG),
      new TimerMilliC() as Timer0,
      LedsC;
      // new PacketLogC(100) as Log;

  /******** RPL ROUTING **********/
  components RPLRankC;
  components RPLRoutingEngineC;
  components IPDispatchC;
  //components RPLForwardingEngineC;
  components RPLDAORoutingEngineC;
  components IPStackC;
  components IPProtocolsP;
  /******** RPL ROUTING **********/
      
  SECSendP.Boot -> MainC;
  // SECSendP.AMControl -> ActiveMessageC;
  SECSendP.Leds -> LedsC;
  SECSendP.AMSend -> AMSenderC;
  // SECSendP.Receive -> AMReceiverC;
  // SECSendP.Receive -> Log;
  // Log.Receive -> AMReceiverC;
  // SECSendP.PacketAcknowledgements -> ActiveMessageC;
  SECSendP.Timer0 -> Timer0;
  SECSendP.Packet -> AMSenderC;
  SECSendP.AMPacket -> AMSenderC;

  /******** RPL ROUTING **********/
  SECSendP.AMControl -> IPStackC;//IPDispatchC;
  SECSendP.RPLRoute -> RPLRoutingEngineC;
  SECSendP.RootControl -> RPLRoutingEngineC;
  SECSendP.RoutingControl -> RPLRoutingEngineC;

  components new UdpSocketC() as RPLUDP;
  SECSendP.RPLUDP -> RPLUDP;

  SECSendP.RPLDAO -> RPLDAORoutingEngineC;
  // SECSendP.Random -> RandomC;

  #ifdef RPL_ROUTING
    components RPLRoutingC;
  #endif

  // #ifdef PRINTFUART_ENABLED
  //   components PrintfC;
  //   components SerialStartC;
  // #endif
  /******** RPL ROUTING **********/
}