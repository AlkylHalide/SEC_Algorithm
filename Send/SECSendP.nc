// Evert Boelaert
// S²E²C algorithm

// Sender mote broadcasts packets <Ai, lbl, dat>
// Receiver receives packets and puts them into array packet_set[]
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

  /***************** Local variables ****************/
  // Boolean to check if channel is busy
  bool busy = FALSE;

  // Define capacity [NOT USED]
  // uint8_t capacity = 10;

  // Array to hold the ACK messages
  // The size of the array is equal to capacity+1
  nx_struct ACKMsg ACK_set[11];
  
  // We also define a loop variable to go through the array
  uint8_t j = 0;

  // AltIndex for the ABP protocol
  uint16_t AltIndex = 0;

  // Label variable
  uint16_t msgLbl = 1;

  // Message/data variable
  uint8_t i = 0;
  uint16_t m[] = {9,8,7,6,5,4,3,2,1,0};

  // Message to transmit
  message_t myMsg;
  
  /***************** Prototypes ****************/
  task void send();
  
  /***************** Boot Events ****************/
  event void Boot.booted() {
    call AMControl.start();
  }

  /***************** SplitControl Events ****************/
  event void AMControl.startDone(error_t error) {
    if (error == SUCCESS) {
      ACK_set[10].lbl = 0;
      post send();
    }
    else {
      call AMControl.start();
    }
  }
  
  event void AMControl.stopDone(error_t error) {
    // do nothing
  }
  
  /***************** Receive Events ****************/
  event message_t *Receive.receive(message_t *msg, void *payload, uint8_t len) {
    if (len != sizeof(ACKMsg)) {
      return msg;
    }
    else {
      ACKMsg* inMsg = (ACKMsg*)payload;
      printf("LastDeliveredAltIndex: \n");
      printf("%d\n", inMsg->ldai);
      printf("Label: \n");
      printf("%d\n", inMsg->lbl);
      printf("Node ID: \n");
      printf("%d\n", inMsg->nodeid);
      printfflush();

      // Add incoming packet to ACK_SET
      ACK_set[j].ldai = inMsg->ldai;  
      ACK_set[j].lbl = inMsg->lbl;
      ACK_set[j].nodeid = inMsg->nodeid;

      // Increment the loop variable for the array
      // The mod operation is necessary to keep the variable from going
      // outside of the array bounds
      ++j;
      j %= 11;

      // Below is a check for when we increment the Alternating Index
      // and start transmitting a new message.
      // As long as the ACK_set array is not full (checked by seeing if the lbl at position 11 is 0 or not),
      // we keep the label. From the moment it's full, aka 11 (capacity+1)
      // messages have been send, we put the label back at zero and increment
      // the alternating index in modulo 3.

      if (ACK_set[10].lbl != 0) {
        msgLbl = 1;
        ++AltIndex;
        AltIndex %= 3;
        ACK_set[10].lbl = 0;
        ++i;
        i %= 10;
      } else {
        ++msgLbl;
      }
      
      return msg;
    }
  }
  
  /***************** AMSend Events ****************/
  event void AMSend.sendDone(message_t *msg, error_t error) {
    busy = FALSE;
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
    if(!busy){
      SECMsg* btrMsg = (SECMsg*)(call Packet.getPayload(&myMsg, sizeof(SECMsg)));
      btrMsg->ai = AltIndex;
      btrMsg->lbl = msgLbl;
      btrMsg->dat = m[i];
      btrMsg->nodeid = TOS_NODE_ID;

      if(call AMSend.send(AM_BROADCAST_ADDR, &myMsg, sizeof(SECMsg)) != SUCCESS) {
        post send();
      } else {
        busy = TRUE;
      }
    }
  }
}