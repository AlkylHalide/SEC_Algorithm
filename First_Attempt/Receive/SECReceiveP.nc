// Evert Boelaert
// S²E²C algorithm

// Sender mote broadcasts packets <Ai, lbl, dat>
// Receiver receives packets and puts them into array packet_set[]
// Receiver then acknowledges packets by sending ACK <ldai, lbl> messages back to Sender.

// Ai = Alternating Index
// lbl = Label
// dat = data (message)
// ldai = Last Delivered Alternating Index

#include <stdlib.h>
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
  // Packet generation variables
  #define pl 16               // amount of messages to get from application layer

  #define capacity (pl-1)

  #define arraySize(x)  (sizeof(x) / sizeof((x)[0]))

  /***************** Local variables ****************/
  // Boolean to check if channel is busy
  bool busy = FALSE;

  // Variable to keep track of the last delivered alternating index in the ABP protocol
  uint16_t LastDeliveredAltIndex = 0;
  uint8_t ldai = 0;

  // Label variable
  uint16_t receiveLbl = 0;

  // Array to contain all the received packages
  nx_struct SECMsg packet_set[(capacity + 1)];

  // Define some loop variables to go through arrays
  uint8_t i = 0;
  uint8_t j = 0;
  uint8_t ackLbl = 1;
  uint8_t random = 0;

  // Message to transmit
  message_t ackMsg;

  // Variable to store the source address [Node ID] of the incoming packet
  uint16_t inNodeID = 0;

  // Pointers to an int for the messages array
  uint16_t *p;

  ////************PACKET MODIFICATION************////
  // Variable to keep track of the amount of iterations
  uint32_t iteration = 0;
  // Variable to keep track of wrong packages
  uint32_t missed = 0;
  // probability is a number between 0 and 100, defined as a percentage
  // Example: probability = 50 --> 50% chance
  uint16_t probability = 0;
  // Variable to count the amount of message deliveries (see deliver() function)
  // This can be used to count only the amount of times a batch of messages is
  // actually delivered, instead of all the iterations
  uint16_t deliverCounter = 0;
  ////*******************************************////

  /***************** Prototypes ****************/
  // task to encompass all sending operations
  task void send();

  // declaration of deliver function to deliver the received messages to the application layer
  void deliver();

  // boolean function to check if the incoming packet is valid
  bool checkIncoming(uint8_t pcktAi, uint8_t pcktLbl);

  // boolean function to check if the contents of packet_set are valid
  bool checkValid();

  // boolean function to check if ready for delivery
  bool checkPacketSet();

  /***************** Boot Events ****************/
  event void Boot.booted() {
    call AMControl.start();
  }

  /***************** SplitControl Events ****************/
  event void AMControl.startDone(error_t error) {
    if (error == SUCCESS) {
      atomic {
        // Initialize the random seed
        srand(abs(rand() % 100 + 1));

        // Initialize the ACK_set array with zeroes
        memset(packet_set, 0, sizeof(packet_set));

        // Immediately start sending ACK messages at startup
        post send();
      }
    }
    else {
      // If AMControl didn't start successfully, call it again
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t error) {
    // do nothing
  }

  /***************** Receive Events ****************/
  event message_t *Receive.receive(message_t *msg, void *payload, uint8_t len) {
    // Check the received packet's AM type. If it's not a valid message
    // type (AM_SECMSG), return it
    if(call AMPacket.type(msg) != AM_SECMSG) {
      return msg;
    }
    else {
      atomic {
        // Put the payload in a pointer
        SECMsg* inMsg = (SECMsg*)payload;

        ////************PACKET MODIFICATION************////
        // This section modifies packet reception.
        // Depending on a probability, errors can be inserted in the communication
        // channel by means of packet manipulation. We can omit, duplicate, or
        // reorder packets.

        // An iteration counter is incremented every time the receive function
        // completes. This is in accordance with the definition of one iteration
        // in the theoretical paper.
        ++iteration;

        // Calculating the probability
        if ( abs(rand() % 100 + 1) <= ((probability))) {
          // Increment the 'missed' variable, the probability was hit
          missed++;

          // Switch case based on a rand value in the range of [0 2]
          // Depending on possibility insert different error
          /*switch(abs(rand() % 2 + 1)) {
            case 0 :
              // Omit the package
              return msg;
              break;

            case 1 :
              // Duplicate package
              inMsg->lbl = (inMsg->lbl + abs(rand() % (capacity) + 1)) % capacity;
              break;

            case 2 :
              // Reorder package
              inMsg->lbl = abs(rand() % (capacity) + 1);
              break;
          }*/
        }
        ////*******************************************////

        // Check the incoming packet for validity
        // If the packet passes, add it to packet_set[]
        // If it fails, return the message
        if (checkIncoming(inMsg->ai, inMsg->lbl) && (inMsg->nodeid == (TOS_NODE_ID - sendnodes)))
        {
          ldai = inMsg->ai;
          receiveLbl = inMsg->lbl;
          inNodeID = inMsg->nodeid;

          // Add incoming packet to packet_set[]
          // The packets in the receiving packet_set[] array should always be in order
          // This means replacing, inserting and appending packets at the right point in the array
          // according to their label value. This is solved very easily by making the array index variable
          // equal to the label of the incoming message, minus 1 (because labels start at 1 where the array
          // index starts at 0).
          packet_set[(inMsg->lbl - 1)].ai = inMsg->ai;
          packet_set[(inMsg->lbl - 1)].lbl = inMsg->lbl;
          packet_set[(inMsg->lbl - 1)].dat = inMsg->dat;
          packet_set[(inMsg->lbl - 1)].nodeid = inMsg->nodeid;
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

        // Check if packet_set holds valid contents
        // If not, reset packet_set
        if (checkValid()) {
          memset(packet_set, 0, sizeof(packet_set));
        }

        if (checkPacketSet()) {
          // Update LastDeliveredIndex to AI of current message array
          LastDeliveredAltIndex = ldai;
          ackLbl = 1;

          // Deliver the messages to the application layer
          deliver();

          // Clear the packet_set array
          memset(packet_set, 0, sizeof(packet_set));
        }

        outMsg->ldai = LastDeliveredAltIndex;
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
    // Uncomment this to print data instead of measurements
    /*printf("DELIVER MESSAGES\n");*/
    ++deliverCounter;
    printf("%u %u %lu %lu\n", probability, deliverCounter, iteration, missed);
    printfflush();
  }

  // boolean function to check if the incoming packet is valid
  bool checkIncoming(uint8_t pcktAi, uint8_t pcktLbl){
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

  // boolean function to check if the contents of packet_set are valid
  bool checkValid () {
    for (i = 0; i < arraySize(packet_set); i++) {
      if( (packet_set[i].ai == LastDeliveredAltIndex) || (packet_set[i].ai > 2) || (packet_set[i].ai < 0) ) {
        return TRUE;
      } else if ((packet_set[i].lbl < 1) || (packet_set[i].lbl > (capacity + 1))) {
        return TRUE;
      } else if (sizeof(packet_set[i].dat) != 2) {
        return TRUE;
      } else {
        return FALSE;
      }
    }
    return FALSE;
  }

  // Boolean return function to check if packet_set is complete
  // Check if packet_set holds at most ONE group of ai
  // that has n (distinctly labeled) packets
  bool checkPacketSet() {
    uint16_t firstAi = packet_set[0].ai;
    // go through packet_set
    for (i = 0; i < arraySize(packet_set); i++) {
      // The fullfillment requirement is that packet_set contains
      // n distinct labeled packets with identical 'ai'
      if( (packet_set[i].ai == firstAi) && (packet_set[i].lbl == (i+1)) ) {
        // do nothing
      } else {
        return FALSE;
      }
    }
    return TRUE;
  }
}
