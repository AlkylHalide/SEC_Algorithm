/**
 * Test for radio acknowledgements
 * Program all motes up with ID 1
 *   Led0 = Received a message
 *   Led1 = Got an ack
 *   Led2 = Missed an ack
 * @author David Moss
 */
 
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
}