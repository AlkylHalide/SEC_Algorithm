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
  
  /**  Variable to keep track of the last delivered alternating index in the ABP protocol **/
  uint16_t LastDeliveredAltIndex = 0;

  /** Label variable **/
  uint16_t recLbl = 0;

  /** Message to transmit */
  message_t ackMsg;
  
  /***************** Prototypes ****************/
  task void send();
  
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
    SECMsg* inMsg = (SECMsg*)payload;
    printf("AltIndex: \n");
    printf("%d\n", inMsg->ai);
    printf("Label: \n");
    printf("%d\n", inMsg->lbl);
    recLbl = inMsg->lbl;
    printf("Data: \n");
    printf("%d\n", inMsg->dat);
    printfflush();

    if (inMsg->lbl == 11) {
    } else {
      LastDeliveredAltIndex = inMsg->ai;
    }

    post send();

    //TODO: Add incoming SECMsg to packet_set[]
    
    return msg;
  }
  
  /***************** AMSend Events ****************/
  event void AMSend.sendDone(message_t *msg, error_t error) {
    // if(DELAY_BETWEEN_MESSAGES > 0) {
    //   call Timer0.startOneShot(DELAY_BETWEEN_MESSAGES);
    // } else {
    //   post send();
    // }
  }
  
  /***************** Timer Events ****************/
  event void Timer0.fired() {
    //post send();
  }
  
  /***************** Tasks ****************/
  task void send() {
    ACKMsg* outMsg = (ACKMsg*)(call Packet.getPayload(&ackMsg, sizeof(ACKMsg)));
    outMsg->ldai = LastDeliveredAltIndex;
    outMsg->lbl = recLbl;

    // TODO: AM_BROADCAST_ADDR is niet correct denk ik,
    // ACK messages moeten enkel teruggestuurd worden naar
    // de bron van originele incoming message

    if(call AMSend.send(AM_BROADCAST_ADDR, &ackMsg, sizeof(ACKMsg)) != SUCCESS) {
      post send();
    }
  }
}