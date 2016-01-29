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
    interface AMPacket;
    interface Receive;
    interface Timer<TMilli> as Timer0;
  }
}

implementation {
  // Packet generation variables
  #define pl 16               // amount of messages to get from application layer

  // <capacity> amount of messages
  #define capacity (pl-1)

  /***************** Local variables ****************/
  // Boolean to check if channel is busy
  bool busy = FALSE;

  // Array to hold the ACK messagess
  nx_struct ACKMsg ACK_set[(capacity + 1)];

  // Define some loop variables to go through arrays
  uint8_t i = 0;
  uint8_t j = 0;
  uint8_t msgIndex = 0;

  // AltIndex for the ABP protocol
  uint16_t AltIndex = 0;

  // Label variable
  uint16_t msgLbl = 1;

  // Message/data variable as a counter
  uint16_t counter = 0;

  // Pointers to an int for the messages and packet_set arrays
  uint16_t *messages;

  // Message to transmit
  message_t myMsg;

  /***************** Prototypes ****************/
  task void send();

  // declaration of fetch function to get an array of new messages
  uint16_t * fetch(uint8_t NumOfMessages);

  // Boolean function to check the contents of the ACK array
  bool checkAckSet();

  /***************** Boot Events ****************/
  event void Boot.booted() {
    call AMControl.start();
  }

  /***************** SplitControl Events ****************/
  event void AMControl.startDone(error_t error) {
    if (error == SUCCESS) {
      atomic {
        // Initialize the ACK_set array with zeroes
        memset(ACK_set, 0, sizeof(ACK_set));

        // Get a new messages array
        messages = fetch(pl);

        // Execute the send task next
        post send();
      }
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
      atomic {
        ACKMsg* inMsg = (ACKMsg*)payload;

        // Check if LastDeliveredIndex is equal to the current Alternating Index and
        // check if label lies in [1, <capacity> + 1] interval
        if ((inMsg->ldai == AltIndex) && (inMsg->lbl > 0) && (inMsg->lbl < (capacity + 2)) && (inMsg->nodeid == (TOS_NODE_ID + sendnodes))) {
          // Add incoming packet to ACK_set
          ACK_set[(inMsg->lbl - 1)].ldai = inMsg->ldai;
          ACK_set[(inMsg->lbl - 1)].lbl = inMsg->lbl;
          ACK_set[(inMsg->lbl - 1)].nodeid = inMsg->nodeid;
        }
      }

      return msg;
    }
  }

  /***************** AMSend Events ****************/
  event void AMSend.sendDone(message_t *msg, error_t error) {
    atomic {
      busy = FALSE;

      // Increment the label
      ++msgLbl;
      if ( (msgLbl % (capacity + 2)) == 0 ) {
        ++msgLbl;
      }
      msgLbl %= (capacity + 2);

      // Increment the index for the data sent
      ++msgIndex;
      msgIndex %= pl;
    }

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
      atomic {
        SECMsg* btrMsg = (SECMsg*)(call Packet.getPayload(&myMsg, sizeof(SECMsg)));

        // Below is a check for when we increment the Alternating Index
        // and start transmitting a new message.
        // As long as the ACK_set array is not full (checked by seeing if the lbl at position 11 is 0 or not),
        // we keep the label. From the moment it's full, aka 11 (CAPACITY)
        // messages have been send, we put the label back at zero and increment
        // the alternating index in modulo 3.

        // If array is filled with 'CAPACITY' packets:
        if (checkAckSet()) {
          // Put variable msgLbl back to 1 (starting point)
          msgLbl = 1;

          // Increment the Alternating Index in modulo 3
          ++AltIndex;
          AltIndex %= 3;

          // Clear the ACK_set array
          memset(ACK_set, 0, sizeof(ACK_set));

          // Get a new messages array
          messages = fetch(pl);

          // Reset the loop variable
          msgIndex = 0;
        }

        // The message to send is filled with the appropriate data
        btrMsg->ai = AltIndex;
        btrMsg->lbl = msgLbl;
        btrMsg->dat = *(messages + msgIndex);
        btrMsg->nodeid = TOS_NODE_ID;
      }

      if(call AMSend.send((TOS_NODE_ID + sendnodes), &myMsg, sizeof(SECMsg)) != SUCCESS) {
        post send();
      } else {
        busy = TRUE;
      }
    }
  }

  /***************** User-defined functions ****************/
  // function returning messages array M
  uint16_t * fetch(uint8_t NumOfMessages) {
    static uint16_t M[pl];

    for ( i = 0; i < NumOfMessages; ++i) {
      M[i] = counter;
      // Increment the counter (for pl amount of messages)
      ++counter;
    }
    return M;
  }

  // Boolean return function to check if ACK_set is complete
  bool checkAckSet() {
    // go through ACK_set, size <capacity> + 1
    for (i = 0; i < (capacity+1); i++) {
      // The fullfillment requirement is that ACK_set contains
      // <capacity> + 1 ACK messages from the receiver,
      // each with ldai = AltIndex and every value of the labels
      // represented
      if( (ACK_set[i].ldai == AltIndex) && (ACK_set[i].lbl == (i+1)) ) {
        // do nothing
      } else {
        return FALSE;
      }
    }
    return TRUE;
  }
}
