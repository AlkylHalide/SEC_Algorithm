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

configuration SECSendC {
}

implementation {
  components SECSendP,
      MainC,
      PrintfC,
      SerialStartC,  
      ActiveMessageC,
      new AMSenderC(128),
      new AMReceiverC(128),
      new TimerMilliC() as Timer0,
      LedsC;
      
  SECSendP.Boot -> MainC;
  SECSendP.AMControl -> ActiveMessageC;
  SECSendP.Leds -> LedsC;
  SECSendP.AMSend -> AMSenderC;
  //SECSendP.Receive -> AMReceiverC;
  SECSendP.PacketAcknowledgements -> ActiveMessageC;
  SECSendP.Timer0 -> Timer0;
  SECSendP.Packet -> AMSenderC;
}