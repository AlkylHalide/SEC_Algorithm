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
#include "SECReceive.h"

module SECReceiveP {
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
  
  /**  AltIndex for the ABP protocol **/
  uint16_t AltIndex = 0;

  /** Label variable **/
  uint16_t msgLbl = 0;

  /** Message to transmit */
  message_t ackMsg;
  
  /***************** Prototypes ****************/
  // task void send();
  
  /***************** Boot Events ****************/
  event void Boot.booted() {
    call AMControl.start();
  }

  /***************** SplitControl Events ****************/
  event void AMControl.startDone(error_t error) {
    //post send();
  }
  
  event void AMControl.stopDone(error_t error) {
  }
  
  /***************** Receive Events ****************/
  event message_t *Receive.receive(message_t *msg, void *payload, uint8_t len) {
    SECMsg* btrMsg = (SECMsg*)payload;
    printf("AltIndex: \n");
    printf("%d\n", btrMsg->ai);
    printf("Label: \n");
    printf("%d\n", btrMsg->lbl);
    printfflush();
    
    call Leds.led2Toggle();
    return msg;
  }
  
  /***************** AMSend Events ****************/
  event void AMSend.sendDone(message_t *msg, error_t error) {
    if(call PacketAcknowledgements.wasAcked(msg)) {
      call Leds.led1Toggle();
      call Leds.led0Off();
    } else {
      call Leds.led0Toggle();
      call Leds.led1Off();
    }
    
    if(DELAY_BETWEEN_MESSAGES > 0) {
      call Timer0.startOneShot(DELAY_BETWEEN_MESSAGES);
    } else {
      //post send();
    }
  }
  
  /***************** Timer Events ****************/
  event void Timer0.fired() {
    // SECMsg* btrMsg = (SECMsg*)(call Packet.getPayload(&myMsg, sizeof(SECMsg)));
    // btrMsg->ai = AltIndex;
    // btrMsg->lbl = ++msgLbl;
    // post send();
  }
  
  /***************** Tasks ****************/
  // task void send() {
  //   call PacketAcknowledgements.requestAck(&myMsg);
  //   // if(call AMSend.send(1, &myMsg, 0) != SUCCESS) {
  //   //   post send();
  //   // }
  //   if(call AMSend.send(AM_BROADCAST_ADDR, &myMsg, sizeof(SECMsg)) != SUCCESS) {
  //     post send();
  //   }
  // }
}