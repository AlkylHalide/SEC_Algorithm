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

  #define CAPACITY 15
  #define ROWS (CAPACITY + 1)
  #define COLUMNS 16
  #define SENDNODES 3
  
  /***************** Local variables ****************/
  // Boolean to check if channel is busy
  bool busy = FALSE;

  // Variable to keep track of the last delivered alternating index in the ABP protocol
  uint16_t LastDeliveredAltIndex = 2;
  uint8_t ldai = 0;

  // Label variable
  uint16_t recLbl = 0;
  
  // Array to contain all the received packages
  // Packet_set array length should be 2*CAPACITY+1
  nx_struct SECMsg packet_set[(CAPACITY + 1)];

  // Define some loop variables to go through arrays
  uint8_t i = 0;
  uint8_t j = 0;

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

  // declaration of transpose function to transpose received packets
  uint16_t * pckt();

  bool checkArray(uint8_t pcktAi, uint8_t pcktLbl);
  
  /***************** Boot Events ****************/
  event void Boot.booted() {
    call AMControl.start();
  }

  /***************** SplitControl Events ****************/
  event void AMControl.startDone(error_t error) {
    if (error == SUCCESS) {
      // Initialize the ACK_set array with zeroes
      memset(packet_set, 0, sizeof(packet_set));
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

      if (checkArray(inMsg->ai, inMsg->lbl) && (inMsg->nodeid == (TOS_NODE_ID - SENDNODES)))
      {
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
      }

      // Check if the label at position 'CAPACITY' in the packet_set array is filled in or not
      // YES: change the LastDeliveredAltIndex value to the Alternating Index value of the incoming packet.
      // NO: continue normal operation.
      if (packet_set[CAPACITY].lbl != 0 ) {
        // Update LastDeliveredIndex to AI of current message array
        LastDeliveredAltIndex = inMsg->ai;

        // Transpose messages array
        p = pckt();

        // Delive the messages to the application layer
        deliver();

        // Clear the packet_set array
        memset(packet_set, 0, sizeof(packet_set));
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
    // do nothing
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
      
      if(call AMSend.send((TOS_NODE_ID - SENDNODES), &ackMsg, sizeof(ACKMsg)) != SUCCESS) {
      // if(call AMSend.send(AM_BROADCAST_ADDR, &ackMsg, sizeof(ACKMsg)) != SUCCESS) {
        post send();
      } else {
        busy = TRUE;
      }
    }
  }

  /***************** User-defined functions ****************/
  // function returning messages array
  void deliver() {
    for ( i = 0; i < (CAPACITY + 1); ++i) {
      printf("%u\n", *(p + i));
    }
    printfflush();
  }

  // function packet_set to transpose received packets
  uint16_t * pckt() {
    // Consider message array as bit matrix
    // Transpose matrix: data[i].bit[j] = messages[j].bit[i]
    // return array with <CAPACITY+1> amount of received messages

    uint16_t x = 0;
    uint16_t result[ROWS][COLUMNS];
    uint16_t transpose[COLUMNS][ROWS];
    static uint16_t packets[ROWS];

    // Initalize 2D arrays with zeroes
    for (i = 0; i < ROWS; ++i)
    {
      // packets[i] = 0;
      for (j = 0; j < COLUMNS; ++j)
      {
        result[i][j] = 0;
        transpose[j][i] = 0;
      }
    }

    // Using the same int to bit array conversion as with the sender,
    // the received 1D int array of decimals is converted to
    // a 2D bit array
    for (i = 0; i < COLUMNS; ++i)
    {
      x = packet_set[i].dat;
      for (j = 0; j < ROWS; ++j)
      {
        transpose[i][j] = (x & 0x8000) >> 15;
        x <<= 1;
      }
    }

    // Transpose the 'transpose' array and put the result in 'result'
    // printf("TRANSPOSE\n");
    for (i = 0; i < ROWS; ++i)
    {
      for (j = 0; j < COLUMNS; ++j)
      {
        result[i][j] = transpose[j][i];
      }
    }

    // Convert the transposed bit array into a decimal value array
    x = 1;
    for (i = 0; i < ROWS; ++i)
    {
      for (j = 0; j < COLUMNS; ++j)
      {
        if (result[i][j] == 1) packets[i] = packets[i] * 2 + 1;
        else if (result[i][j] == 0) packets[i] *= 2;
      }
    }

    return packets;
  }

  bool checkArray(uint8_t pcktAi, uint8_t pcktLbl){
    if ((pcktAi != LastDeliveredAltIndex) && (pcktAi < 3) && (pcktAi > -1) && (pcktLbl > 0) && (pcktLbl < (CAPACITY+2)))
    {
      for (i = 0; i < (CAPACITY + 1); ++i)
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