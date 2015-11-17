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
    interface Leds;
    interface PacketAcknowledgements;
    interface Timer<TMilli> as Timer0;
  }
}

implementation {

  /***************** Local variables ****************/
  // Boolean to check if channel is busy
  bool busy = FALSE;

  // define capacity
  uint16_t capacity = 10;

  // Array to hold the ACK messages
  // The size of the array is equal to capacity+1
  // This needs to be set manually: no dynamic array definition possible
  nx_struct ACKMsg ACK_set[11];

  nx_struct dat dataTabel[11];
  
  // We also define a loop variable to go through the array
  uint8_t j = 0;

  // AltIndex for the ABP protocol
  uint16_t AltIndex = 0;

  // Label variable
  uint16_t msgLbl = 1;

  // Message/data variable as a counter
  uint16_t counter = 0;

  // a pointer to an int for the messages array
  uint16_t *p;
  uint8_t i = 0;

  // Message to transmit
  message_t myMsg;
  
  /***************** Prototypes ****************/
  task void send();

  // declaration of fetch function to get an array of new messages
  uint16_t * fetch(int pl);

  // declaration of packet_set function to generate packets for sending
  uint16_t * packet_set();
  
  /***************** Boot Events ****************/
  event void Boot.booted() {
    call AMControl.start();
  }

  /***************** SplitControl Events ****************/
  event void AMControl.startDone(error_t error) {
    if (error == SUCCESS) {
      ACK_set[capacity].lbl = 0;
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
      // check if label lies in [1 11] interval
      if ((inMsg->ldai == AltIndex) && (inMsg->lbl > 0) && (inMsg->lbl < 12)) {
        // Add incoming packet to ACK_set
        j = inMsg->lbl - 1;
        ACK_set[j].ldai = inMsg->ldai;  
        ACK_set[j].lbl = inMsg->lbl;
        ACK_set[j].nodeid = inMsg->nodeid;
      }

      // Below is a check for when we increment the Alternating Index
      // and start transmitting a new message.
      // As long as the ACK_set array is not full (checked by seeing if the lbl at position 11 is 0 or not),
      // we keep the label. From the moment it's full, aka 11 (capacity+1)
      // messages have been send, we put the label back at zero and increment
      // the alternating index in modulo 3.

      // If array is filled with 'capacity' packets:
      if ((ACK_set[capacity].lbl != 0) && (ACK_set[capacity].ldai == AltIndex)) {

        // Put variable msgLbl back to 1 (starting point)
        msgLbl = 1;
        
        // Increment the Alternating Index in modulo 3
        ++AltIndex;
        AltIndex %= 3;

        // Clear the ACK_set array
        memset(ACK_set, 0, sizeof(ACK_set));

        // Increment the counter (for pl copies of the same data)
        //++counter;

        // Get a new messages array
        p = fetch(capacity + 1);
        // TODO: ENCODE()

        i = 0;

        // for ( i = 0; i < (capacity + 1); i++ ) {
        //   printf( "*(p + %d) : %d\n", i, *(p + i));
        // }
        
      } else {
        // If the ACK_set array isn't full yet, we just increment the label
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
    ++i;
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
      btrMsg->dat = *(p + i);
      btrMsg->nodeid = TOS_NODE_ID;

      if(call AMSend.send(AM_BROADCAST_ADDR, &myMsg, sizeof(SECMsg)) != SUCCESS) {
        post send();
      } else {
        busy = TRUE;
      }
    }
  }

  // function returning messages array
  uint16_t * fetch(int pl) {    
    static uint16_t messages[11];

    for ( i = 0; i < pl; ++i) {
      messages[i] = counter;
      // Increment the counter (for pl amount of messages sent instead of copies of the same message)
      ++counter;
    }
    return messages;
  }

  // function packet_set to generate packets for sending
  uint16_t * packet_set() {
    // Consider message array as bit matrix
    // Transpose matrix: data[i].bit[j] = messages[j].bit[i]
    // return array with <capacity> amount of SECMsg
    // SECMsg = <Ai; lbl; data(i)> with i € [1, n]

    uint16_t transpose[][];

    for (int i = 0; i < (capacity + 1); ++i)
    {
      transpose = dectobin();
    }

    // for (c = 0; c < m; c++)
    //       for( d = 0 ; d < n ; d++ )
    //          transpose[d][c] = matrix[c][d];

    // SECMsg* btrMsg = (SECMsg*)(call Packet.getPayload(&myMsg, sizeof(SECMsg)));
    // btrMsg->ai = AltIndex;
    // btrMsg->lbl = msgLbl;
    // btrMsg->dat = *(p + i);
    // btrMsg->nodeid = TOS_NODE_ID;
  }
}