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
    interface Receive;
    interface Leds;
    interface PacketAcknowledgements;
    interface Timer<TMilli> as Timer0;
  }
}

implementation {
  
  /** Boolean to check if channel is busy **/
  bool busy = FALSE;

  /**  Variable to keep track of the last delivered alternating index in the ABP protocol **/
  uint16_t LastDeliveredAltIndex = 2;

  /** Label variable **/
  uint16_t recLbl = 0;

  /** Define capacity variable **/
  uint16_t capacity = 10;
  
  // Packet_set array length should be 2*capacity+1
  // uint16_t array_length = 21;

  /** Array to contain all the received packages **/
  nx_struct SECMsg packet_set[11];

  // We also define a loop variable to go through the array
  uint8_t j = 0;

  /** Message to transmit */
  message_t ackMsg;

  /** Variable to store the source address of the incoming packet **/
  uint16_t inNodeID = 0;
  
  /***************** Prototypes ****************/
  task void send();
  
  /***************** Boot Events ****************/
  event void Boot.booted() {
    call AMControl.start();
  }

  /***************** SplitControl Events ****************/
  event void AMControl.startDone(error_t error) {
    if (error == SUCCESS) {
      // This is an initialization for the last element of the packet_set array.
      // This is done so every iteration of the Receive.receive() function I can 
      // check if the label of the last element of the array is empty or not.
      packet_set[10].lbl = 0;
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
    if (len != sizeof(SECMsg)) {
      return msg;
    }
    else {
      SECMsg* inMsg = (SECMsg*)payload;
      
      printf("AltIndex: \n");
      printf("%d\n", inMsg->ai);
      printf("Label: \n");
      printf("%d\n", inMsg->lbl);
      recLbl = inMsg->lbl;
      printf("Data: \n");
      printf("%d\n", inMsg->dat);
      printf("Node ID: \n");
      printf("%d\n", inMsg->nodeid);
      inNodeID = inMsg->nodeid;
      printfflush();

      // Add incoming packet to packet_set[]
      packet_set[j].ai = inMsg->ai;
      packet_set[j].lbl = inMsg->lbl;
      packet_set[j].dat = inMsg->dat;
      packet_set[j].nodeid = inMsg->nodeid;

      // Increment the loop variable for the array
      // The mod operation is necessary to keep the variable from going
      // outside of the array bounds
      ++j;
      j %= 11;

      // Check to see if the lbl variable of the incoming packet is 11 or not.
      // YES: change the LastDeliveredAltIndex value to the Alternating Index value of the incoming packet.
      // NO: continue normal operation.
      // if (inMsg->lbl == 11)
      //   LastDeliveredAltIndex = inMsg->ai;

      if (packet_set[10].lbl != 0 ) {
        LastDeliveredAltIndex = inMsg->ai;
        packet_set[10].lbl = 0;
      }

      post send();
      
      return msg;      
    }
  }
  
  /***************** AMSend Events ****************/
  event void AMSend.sendDone(message_t *msg, error_t error) {
    busy = FALSE;
  }
  
  /***************** Timer Events ****************/
  event void Timer0.fired() {
  }
  
  /***************** Tasks ****************/
  task void send() {
    if(!busy){
      ACKMsg* outMsg = (ACKMsg*)(call Packet.getPayload(&ackMsg, sizeof(ACKMsg)));
      outMsg->ldai = LastDeliveredAltIndex;
      outMsg->lbl = recLbl;
      outMsg->nodeid = TOS_NODE_ID;

      // TODO: zenden naar Node ID werkt blijkbaar niet, snap niet goed waarom.
      // Sender broadcast alles, Receiver zou enkel ACK moeten sturen naar Sender waar inkomende
      // message vandaan kwam.

      if(call AMSend.send(inNodeID, &ackMsg, sizeof(ACKMsg)) != SUCCESS) {
        post send();
      } else {
        busy = TRUE;
      }
    }
  }
}