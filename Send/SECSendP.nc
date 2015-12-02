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

/******** RPL ROUTING **********/
#include <Timer.h>
#include <lib6lowpan/ip.h>
// #include <blip_printf.h>
/******** RPL ROUTING **********/

module SECSendP {
  uses {
    interface Boot;
    interface SplitControl as AMControl;
    interface AMSend;
    interface Packet;
    interface AMPacket;
    // interface Receive;
    interface Leds;
    interface PacketAcknowledgements;
    interface Timer<TMilli> as Timer0;

    /******** RPL ROUTING **********/
    interface RPLRoutingEngine as RPLRoute;
    interface RootControl;
    interface StdControl as RoutingControl;
    //interface IP as RPL;
    interface UDP as RPLUDP;
    //interface RPLForwardingEngine;
    interface RPLDAORoutingEngine as RPLDAO;
    interface Random;
    /******** RPL ROUTING **********/
  }
}

implementation {

  #define CAPACITY 15
  #define ROWS (CAPACITY + 1)
  #define COLUMNS 16

  /******** RPL ROUTING **********/
  #ifndef RPL_ROOT_ADDR
  #define RPL_ROOT_ADDR 1
  #endif

  #define UDP_PORT 5678

  struct sockaddr_in6 dest;
  // struct in6_addr MULTICAST_ADDR;
  /******** RPL ROUTING **********/

  /***************** Local variables ****************/
  // Boolean to check if channel is busy
  bool busy = FALSE;

  // Array to hold the ACK messagess
  nx_struct ACKMsg ACK_set[(CAPACITY + 1)];
  
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
  uint16_t *pckt;

  // Message to transmit
  message_t myMsg;
  
  /***************** Prototypes ****************/
  task void send();

  // declaration of fetch function to get an array of new messages
  uint16_t * fetch(uint8_t pl);

  // declaration of packet_set function to generate packets for sending
  uint16_t * packet_set();
  
  /***************** Boot Events ****************/
  event void Boot.booted() {
    /******** RPL ROUTING **********/
    if(TOS_NODE_ID == RPL_ROOT_ADDR){
      call RootControl.setRoot();
    }
    call RoutingControl.start();

    call RPLUDP.bind(UDP_PORT);
    /******** RPL ROUTING **********/

    call AMControl.start();
  }

  /***************** SplitControl Events ****************/
  event void AMControl.startDone(error_t error) {
    /******** RPL ROUTING **********/
    while( call RPLDAO.startDAO() != SUCCESS );
    
    // if(TOS_NODE_ID != RPL_ROOT_ADDR){
    //   // call Timer.startOneShot((call Random.rand16()%2)*2048U);
    //   call Timer.startOneShot(DELAY_BETWEEN_MESSAGES);
    // }
    /******** RPL ROUTING **********/
    if (error == SUCCESS) {
      
      // Initialize the ACK_set array with zeroes
      memset(ACK_set, 0, sizeof(ACK_set));
      // Get a new messages array
      p = fetch(CAPACITY + 1);

      // TODO: ENCODE()

      // Divide messages into packets using packet_set()
      pckt = packet_set();
      
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
  /******** RPL ROUTING **********/
  event void RPLUDP.recvfrom(struct sockaddr_in6 *from, void *payload, uint16_t len, struct ip6_metadata *meta){
  /******** RPL ROUTING **********/
  // event message_t *Receive.receive(message_t *msg, void *payload, uint8_t len) {

    // if(call AMPacket.type(msg) != AM_ACKMSG) {
    if(call AMPacket.type(payload) != AM_ACKMSG) {
      // return msg;
    }
    else {
      ACKMsg* inMsg = (ACKMsg*)payload;

      // Check if LastDeliveredIndex is equal to the current Alternating Index and
      // check if label lies in [1 10] interval
      if ((inMsg->ldai == AltIndex) && (inMsg->lbl > 0) && (inMsg->lbl < (CAPACITY + 2))) {
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
      
      // return msg;
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
    /******** RPL ROUTING **********/
    // call MilliTimer.startOneShot(PACKET_INTERVAL + (call Random.rand16() % 100));
    /******** RPL ROUTING **********/
    post send();
  }
  
  /***************** Tasks ****************/
  task void send() {
    if(!busy){
      // struct sockaddr_in6 dest;

      SECMsg* btrMsg = (SECMsg*)(call Packet.getPayload(&myMsg, sizeof(SECMsg)));

      // Below is a check for when we increment the Alternating Index
      // and start transmitting a new message.
      // As long as the ACK_set array is not full (checked by seeing if the lbl at position 11 is 0 or not),
      // we keep the label. From the moment it's full, aka 11 (CAPACITY+1)
      // messages have been send, we put the label back at zero and increment
      // the alternating index in modulo 3.

      // If array is filled with 'CAPACITY' packets:
      if ((ACK_set[CAPACITY].lbl != 0) && (ACK_set[CAPACITY].ldai == AltIndex)) {

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
        p = fetch(CAPACITY + 1);
        
        // TODO: ENCODE()

        // Divide messages into packets using packet_set()
        pckt = packet_set();

        // Reset the loop variable
        i = 0;
      }

      // The message to send is filled with the appropriate data
      btrMsg->ai = AltIndex;
      btrMsg->lbl = msgLbl;
      btrMsg->dat = *(pckt + i);
      btrMsg->nodeid = TOS_NODE_ID;

      /******** RPL ROUTING **********/
      memcpy(dest.sin6_addr.s6_addr, call RPLRoute.getDodagId(), sizeof(struct in6_addr));
      dest.sin6_port = htons(UDP_PORT);
      /******** RPL ROUTING **********/

      // if(call AMSend.send((TOS_NODE_ID + 2), &myMsg, sizeof(SECMsg)) != SUCCESS) {
      // if(call AMSend.send(AM_BROADCAST_ADDR, &myMsg, sizeof(SECMsg)) != SUCCESS) {
      /******** RPL ROUTING **********/
      if(call RPLUDP.sendto(&dest, &myMsg, sizeof(SECMsg)) != SUCCESS) {
      /******** RPL ROUTING **********/
        post send();
      } else {
        busy = TRUE;
      }
    }
  }

  /***************** User-defined functions ****************/
  // function returning messages array
  uint16_t * fetch(uint8_t pl) {    
    static uint16_t messages[(CAPACITY + 1)];

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
    // return array with <CAPACITY> amount of SECMsg
    // SECMsg = <Ai; lbl; data(i)> with i € [1, n]

    uint16_t x = 0;
    uint16_t result[ROWS][COLUMNS];
    uint16_t transpose[COLUMNS][ROWS];
    static uint16_t packets[COLUMNS];

    // Initalize 2D arrays with zeroes
    for (i = 0; i < ROWS; ++i)
    {
      packets[i] = 0;
      for (j = 0; j < COLUMNS; ++j)
      {
        result[i][j] = 0;
        transpose[j][i] = 0;
      }
    }

    // Transfer 'ROWS' amount of counter values to bits
    // The bits are stored in the 2D array 'result'
    for (i = 0; i < ROWS; ++i)
    {
      x = *(p + i);
      for (j = 0; j < COLUMNS; ++j)
      {
        result[i][j] = (x & 0x8000) >> 15;
        x <<= 1;
      }
    }

    // Transpose the 'result' array and put the result in 'transpose'
    for (i = 0; i < COLUMNS; ++i)
    {
      for (j = 0; j < ROWS; ++j)
      {
        transpose[i][j] = result[j][i];
      }
    }

    // Convert the transposed bit array into a decimal value array
    x = 1;
    for (i = 0; i < COLUMNS; ++i)
    {
      for (j = 0; j < ROWS; ++j)
      {
        if (transpose[i][j] == 1) packets[i] = packets[i] * 2 + 1;
        else if (transpose[i][j] == 0) packets[i] *= 2;
      }
    }

    return packets;
  }
}