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
      
      i = i<9?++i:0;
    }
    
    return msg;
  }
  
  /***************** AMSend Events ****************/
  event void AMSend.sendDone(message_t *msg, error_t error) {
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
    SECMsg* btrMsg = (SECMsg*)(call Packet.getPayload(&myMsg, sizeof(SECMsg)));
    btrMsg->ai = AltIndex;
    btrMsg->lbl = msgLbl;
    btrMsg->dat = m[i];
    btrMsg->nodeid = TOS_NODE_ID;

    if(call AMSend.send(AM_BROADCAST_ADDR, &myMsg, sizeof(SECMsg)) != SUCCESS) {
      post send();
    }
  }
}