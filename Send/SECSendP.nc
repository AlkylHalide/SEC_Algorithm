/**
 * Test for radio acknowledgements
 * Program all motes up with ID 1
 *   Led0 = Missed an ack
 *   Led1 = Got an ack
 *   Led2 = Sent a message
 * @author David Moss
 */
 
/**
Haakjes <> versus quotes "" bij #include
--> Haakjes = zoeken in standaard directories (standaar libraries)
--> Quotes = zoeken in projectfolder
**/

#include <printf.h>
#include "SECSend.h"

module SECSendP {
  uses {
    interface Boot;
    interface SplitControl as AMControl;
    interface AMSend;
    interface Packet;
    interface Receive;
    interface Leds;
    interface PacketAcknowledgements;
    interface Timer<TMilli> as Timer0;
  }
}

implementation {

  /** Define capacity **/
  uint8_t capacity = 10;

  /** Array to hold the ACK messages **/
  // The size of the array needs to be capacity+1,
  // but we can't assign a variable to the size of an array.
  uint16_t ACK_set[11];
  // message_t ACK_set[];

  /** AltIndex for the ABP protocol **/
  uint16_t AltIndex = 0;

  /** Label variable **/
  uint16_t msgLbl = 0;

  /** Message/data variable **/
  uint8_t i = 0;
  uint16_t m[] = {9,8,7,6,5,4,3,2,1,0};

  /** Message to transmit */
  message_t myMsg;
  
  /***************** Prototypes ****************/
  task void send();
  
  /***************** Boot Events ****************/
  event void Boot.booted() {
    call AMControl.start();
  }

  /***************** SplitControl Events ****************/
  event void AMControl.startDone(error_t error) {
    post send();
  }
  
  event void AMControl.stopDone(error_t error) {
  }
  
  /***************** Receive Events ****************/
  event message_t *Receive.receive(message_t *msg, void *payload, uint8_t len) {
    ACKMsg* inMsg = (ACKMsg*)payload;
    printf("LastDeliveredAltIndex: \n");
    printf("%d\n", inMsg->ldai);
    printf("Label: \n");
    printf("%d\n", inMsg->lbl);
    printfflush();

    //TODO: Add incoming packet to ACK_SET

    if (msgLbl < 11) {
      ++msgLbl;
    } else {
      msgLbl = 0;
      ++AltIndex;
      AltIndex %= 3;
      if (i < 10) {
        ++i;
      } else {
        i = 0;
      }
    }
    
    return msg;
  }
  
  /***************** AMSend Events ****************/
  event void AMSend.sendDone(message_t *msg, error_t error) {
    // if(call PacketAcknowledgements.wasAcked(msg)) {
    //   printf("ACKED\n");
    //   printfflush();
    //   call Leds.led1Toggle();
    //   call Leds.led0Off();
    // } else {
    //   call Leds.led0Toggle();
    //   call Leds.led1Off();
    // }
    
    if(DELAY_BETWEEN_MESSAGES > 0) {
      call Timer0.startOneShot(DELAY_BETWEEN_MESSAGES);
    } else {
      post send();
    }
  }
  
  /***************** Timer Events ****************/
  event void Timer0.fired() {
    post send();
  }
  
  /***************** Tasks ****************/
  task void send() {
    // call PacketAcknowledgements.requestAck(&myMsg);

    SECMsg* btrMsg = (SECMsg*)(call Packet.getPayload(&myMsg, sizeof(SECMsg)));
    btrMsg->ai = AltIndex;
    btrMsg->lbl = msgLbl;
    btrMsg->dat = m[i];

    if(call AMSend.send(AM_BROADCAST_ADDR, &myMsg, sizeof(SECMsg)) != SUCCESS) {
      post send();
    }
  }
}