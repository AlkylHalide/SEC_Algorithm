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

#define CAPACITY 16
#define SENDNODES 1

module SECSendP {
  uses {
    interface Boot;
    interface SplitControl as AMControl;
    interface AMSend;
    interface Packet;
    interface AMPacket;
    interface Receive;
    interface Timer<TMilli> as Timer0;
  }
}

implementation {
  /***************** Local variables ****************/
  // Boolean to check if channel is busy
  bool busy = FALSE;

  // Array to hold the ACK messagess
  nx_struct ACKMsg ACK_set[CAPACITY];

  // Define some loop variables to go through arrays
  uint8_t i = 0;
  uint8_t j = 0;

  // AltIndex for the ABP protocol
  uint16_t AltIndex = 0;

  // Label variable
  uint16_t msgLbl = 1;

  // Message/data variable as a counter
  uint16_t counter = 0;

  // Pointers to an int for the messages and packet_set arrays
  uint16_t *p;

  // Message to transmit
  message_t myMsg;

  /***************** Prototypes ****************/
  task void send();

  // declaration of fetch function to get an array of new messages
  uint16_t * fetch(uint8_t pl);

  /***************** Boot Events ****************/
  event void Boot.booted() {
    call AMControl.start();
  }

  /***************** SplitControl Events ****************/
  event void AMControl.startDone(error_t error) {
    if (error == SUCCESS) {

      // Initialize the ACK_set array with zeroes
      memset(ACK_set, 0, sizeof(ACK_set));
      // Get a new messages array
      p = fetch(CAPACITY);

      // Reset the loop variable
      i = 0;

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
    if(call AMPacket.type(msg) != AM_ACKMSG) {
      return msg;
    }
    else {
      ACKMsg* inMsg = (ACKMsg*)payload;

      // Check if LastDeliveredIndex is equal to the current Alternating Index and
      // check if label lies in [1 10] interval
      if ((inMsg->ldai == AltIndex) && (inMsg->lbl > 0) && (inMsg->lbl < (CAPACITY + 1)) && (inMsg->nodeid == (TOS_NODE_ID + SENDNODES))) {
        // Add incoming packet to ACK_set
        j = inMsg->lbl - 1;
        ACK_set[j].ldai = inMsg->ldai;
        ACK_set[j].lbl = inMsg->lbl;
        ACK_set[j].nodeid = inMsg->nodeid;

        // Increment the label
        ++msgLbl;

        // Increment the index for the data sent
        ++i;
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

      // Below is a check for when we increment the Alternating Index
      // and start transmitting a new message.
      // As long as the ACK_set array is not full (checked by seeing if the lbl at position 11 is 0 or not),
      // we keep the label. From the moment it's full, aka 11 (CAPACITY)
      // messages have been send, we put the label back at zero and increment
      // the alternating index in modulo 3.

      // If array is filled with 'CAPACITY' packets:
      if ((ACK_set[(CAPACITY-1)].lbl != 0) && (ACK_set[(CAPACITY-1)].ldai == AltIndex)) {

        // Put variable msgLbl back to 1 (starting point)
        msgLbl = 1;

        // Increment the Alternating Index in modulo 3
        ++AltIndex;
        AltIndex %= 3;

        // Clear the ACK_set array
        memset(ACK_set, 0, sizeof(ACK_set));

        // Get a new messages array
        p = fetch(CAPACITY);

        // Reset the loop variable
        i = 0;
      }

      // The message to send is filled with the appropriate data
      btrMsg->ai = AltIndex;
      btrMsg->lbl = msgLbl;
      btrMsg->dat = *(p + i);
      btrMsg->nodeid = TOS_NODE_ID;

      if(call AMSend.send((TOS_NODE_ID + SENDNODES), &myMsg, sizeof(SECMsg)) != SUCCESS) {
        post send();
      } else {
        busy = TRUE;
      }
    }
  }

  /***************** User-defined functions ****************/
  // function returning messages array
  uint16_t * fetch(uint8_t pl) {
    static uint16_t messages[CAPACITY];

    for ( i = 0; i < pl; ++i) {
      messages[i] = counter;
      // Increment the counter (for pl amount of messages)
      ++counter;
    }
    return messages;
  }
}
