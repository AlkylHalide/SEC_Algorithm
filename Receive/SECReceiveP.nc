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
    interface Leds;
    interface PacketAcknowledgements;
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
  uint16_t recLbl = 0;

  // CAPACITY is defined as 10
  uint16_t capacity = 10;
  
  // Array to contain all the received packages
  // Packet_set array length should be 2*capacity+1
  nx_struct SECMsg packet_set[11];

  // Variable for the array index for incoming packets
  uint8_t j = 0;

  // Message to transmit
  message_t ackMsg;

  // Variable to store the source address [Node ID] of the incoming packet
  uint16_t inNodeID = 0;

  // On this receiver side we also add a counter value that runs equal to the counter
  // at the sender side, which we receive as the data in the packets.
  // By comparing both counters we can check if data gets corrupt during transfer or not.
  uint16_t counter = 0;

  uint8_t i = 0;
  
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
      packet_set[capacity].lbl = 0;
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
      SECMsg* inMsg = (SECMsg*)payload;

      ldai = inMsg->ai;
      recLbl = inMsg->lbl;
      inNodeID = inMsg->nodeid;

      // Add incoming packet to packet_set[]
      // The packets in the receiving packet_set[] array should always be in order
      // This means replacing, inserting and appending packets at the right point in the array
      // according to their label value. This is solved very easily by making the array loop variable 'j'
      // equal to the label of the incoming message, minus 1 (because labels start at 1 where the array
      // index starts at 0).
      j = inMsg->lbl - 1;
      packet_set[j].ai = inMsg->ai;
      packet_set[j].lbl = inMsg->lbl;
      packet_set[j].dat = inMsg->dat;
      packet_set[j].nodeid = inMsg->nodeid;

      // Check to see if the lbl variable of the incoming packet is 11 or not.
      // YES: change the LastDeliveredAltIndex value to the Alternating Index value of the incoming packet.
      // NO: continue normal operation.
      if (packet_set[capacity].lbl != 0 ) {
        for (i = 0; i < (capacity+1); ++i)
        {
          printf("%d\n", packet_set[i].dat);
          printfflush();
        }
        LastDeliveredAltIndex = inMsg->ai;
        packet_set[capacity].lbl = 0;
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
    post send();
  }
  
  /***************** Tasks ****************/
  task void send() {
    if(!busy){
      ACKMsg* outMsg = (ACKMsg*)(call Packet.getPayload(&ackMsg, sizeof(ACKMsg)));
      outMsg->ldai = ldai;
      outMsg->lbl = recLbl;
      outMsg->nodeid = TOS_NODE_ID;

      // TODO: zenden naar Node ID werkt blijkbaar niet, snap niet goed waarom.
      // Sender broadcast alles, Receiver zou enkel ACK moeten sturen naar Sender waar inkomende
      // message vandaan kwam.
      // UPDATE 16/11: Kan waarschijnlijk opgelost worden met Routing Algorithm
      if(call AMSend.send(inNodeID, &ackMsg, sizeof(ACKMsg)) != SUCCESS) {
        post send();
      } else {
        busy = TRUE;
      }
    }
  }
}