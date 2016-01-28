// Evert Boelaert
// S²E²C algorithm

// Sender mote broadcasts packets <Ai, lbl, dat>
// Receiver receives packets and puts them into arrays packet_set[] according to NMote ID.
// Receiver then acknowledges packets by sending ACK <ldai, lbl> messages back to Sender.

// Ai = Alternating Index
// lbl = Label
// dat = data (message)
// ldai = Last Delivered Alternating Index

#include <printf.h>

configuration SECSendC {
}

implementation {
  components SECSendP;
  components MainC;
  components new TimerMilliC() as Timer0;
  components RPLRankC;
  components RPLRoutingEngineC;
  components IPDispatchC;
  components RPLDAORoutingEngineC;
  components IPStackC;
  components IPProtocolsP;

  SECSendP.Boot -> MainC.Boot;
  SECSendP.AMControl -> IPStackC;
  SECSendP.RPLRoute -> RPLRoutingEngineC;
  SECSendP.RootControl -> RPLRoutingEngineC;
  SECSendP.RoutingControl -> RPLRoutingEngineC;

  components new UdpSocketC() as RPLUDP;
  SECSendP.RPLUDP -> RPLUDP;

  SECSendP.RPLDAO -> RPLDAORoutingEngineC;
  SECSendP.Timer0 -> Timer0;

#ifdef RPL_ROUTING
  components RPLRoutingC;
#endif

#ifdef PRINTFUART_ENABLED
  components PrintfC;
  components SerialStartC;
#endif
}
