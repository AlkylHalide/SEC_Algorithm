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
#include "SECReceive.h"

module SECReceiveP {
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

  // Variable to keep track of the last delivered alternating index in the ABP protocol
  uint16_t LastDeliveredAltIndex = 2;
  uint8_t ldai = 0;

  // Label variable
  uint16_t receiveLbl = 0;

  // Array to contain all the received packages
  nx_struct SECMsg packet_set[(capacity + 1)];

  // Define some loop variables to go through arrays
  uint8_t i = 0;
  uint8_t j = 0;
  uint8_t ackLbl = 0;

  // Message to transmit
  message_t ackMsg;

  // Variable to store the source address [Node ID] of the incoming packet
  uint16_t inNodeID = 0;

  // Pointers to an int for the messages array
  uint16_t *p;

  /***************** Prototypes ****************/
  task void send();

  // declaration of deliver function to deliver the received messages to the application layer
  void deliver();

  bool checkArray(uint8_t pcktAi, uint8_t pcktLbl);

  /***************** Boot Events ****************/
  event void Boot.booted() {
    call AMControl.start();
  }

  /***************** SplitControl Events ****************/
  event void AMControl.startDone(error_t error) {
    if (error == SUCCESS) {
      atomic {
        // Initialize the ACK_set array with zeroes
        memset(packet_set, 0, sizeof(packet_set));

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
    if(call AMPacket.type(msg) != AM_SECMSG) {
      return msg;
    }
    else {
      atomic {
        SECMsg* inMsg = (SECMsg*)payload;

        if (checkArray(inMsg->ai, inMsg->lbl) && (inMsg->nodeid == (TOS_NODE_ID - sendnodes)))
        {
          ldai = inMsg->ai;
          receiveLbl = inMsg->lbl;
          inNodeID = inMsg->nodeid;

          // Add incoming packet to packet_set[]
          // The packets in the receiving packet_set[] array should always be in order
          // This means replacing, inserting and appending packets at the right point in the array
          // according to their label value. This is solved very easily by making the array loop variable 'j'
          // equal to the label of the incoming message, minus 1 (because labels start at 1 where the array
          // index starts at 0).
          packet_set[(inMsg->lbl - 1)].ai = inMsg->ai;
          packet_set[(inMsg->lbl - 1)].lbl = inMsg->lbl;
          packet_set[(inMsg->lbl - 1)].dat = inMsg->dat;
          packet_set[(inMsg->lbl - 1)].nodeid = inMsg->nodeid;
        }

        // Check if the label at position 'capacity' in the packet_set array is filled in or not
        // YES: change the LastDeliveredAltIndex value to the Alternating Index value of the incoming packet.
        // NO: continue normal operation.
        if (packet_set[(capacity)].lbl != 0 ) {
          // Update LastDeliveredIndex to AI of current message array
          LastDeliveredAltIndex = inMsg->ai;

          // Delive the messages to the application layer
          deliver();

          // Clear the packet_set array
          memset(packet_set, 0, sizeof(packet_set));
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
      ++ackLbl;
      if ( (ackLbl % (capacity + 2)) == 0 ) {
        ++ackLbl;
      }
      ackLbl %= (capacity + 2);

      if(DELAY_BETWEEN_MESSAGES > 0) {
        call Timer0.startOneShot(DELAY_BETWEEN_MESSAGES);
      } else {
        post send();
      }
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
        ACKMsg* outMsg = (ACKMsg*)(call Packet.getPayload(&ackMsg, sizeof(ACKMsg)));
        outMsg->ldai = ldai;
        outMsg->lbl = ackLbl;
        outMsg->nodeid = TOS_NODE_ID;
      }

      if(call AMSend.send((TOS_NODE_ID - sendnodes), &ackMsg, sizeof(ACKMsg)) != SUCCESS) {
        post send();
      } else {
        busy = TRUE;
      }
    }
  }

  /***************** User-defined functions ****************/
  // function returning messages array
  void deliver() {
    for ( i = 0; i < (capacity+1); ++i) {
      printf("%u    %u    %u\n", packet_set[i].ai, packet_set[i].lbl, packet_set[i].dat);
    }
    printfflush();
  }

  bool checkArray(uint8_t pcktAi, uint8_t pcktLbl){
    if ((pcktAi != LastDeliveredAltIndex) && (pcktAi < 3) && (pcktAi > -1) && (pcktLbl > 0) && (pcktLbl < (capacity+2)))
    {
      for (i = 0; i < capacity; ++i)
      {
        if ((pcktAi == packet_set[i].ai) && (pcktLbl == packet_set[i].lbl))
        {
          return FALSE;
        }
      }
      return TRUE;
    } else {
      return FALSE;
    }
  }
}
