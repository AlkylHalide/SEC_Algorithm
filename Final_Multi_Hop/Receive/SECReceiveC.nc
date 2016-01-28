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

configuration SECReceiveC {
}

implementation {
  components SECReceiveP;
  components MainC;
  components new TimerMilliC() as Timer0;
  components RPLRankC;
  components RPLRoutingEngineC;
  components IPDispatchC;
  components RPLDAORoutingEngineC;
  components IPStackC;
  components IPProtocolsP;

  SECReceiveP.Boot -> MainC.Boot;
  SECReceiveP.AMControl -> IPStackC;
  SECReceiveP.RPLRoute -> RPLRoutingEngineC;
  SECReceiveP.RootControl -> RPLRoutingEngineC;
  SECReceiveP.RoutingControl -> RPLRoutingEngineC;

  components new UdpSocketC() as RPLUDP;
  SECReceiveP.RPLUDP -> RPLUDP;

  SECReceiveP.RPLDAO -> RPLDAORoutingEngineC;
  SECReceiveP.Timer0 -> Timer0;

#ifdef RPL_ROUTING
  components RPLRoutingC;
#endif

#ifdef PRINTFUART_ENABLED
  components PrintfC;
  components SerialStartC;
#endif
}
