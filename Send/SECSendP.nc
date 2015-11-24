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

#define capacity 9
#define rows (capacity + 1)
#define columns 16

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

  // Array to hold the ACK messagess
  nx_struct ACKMsg ACK_set[(capacity + 1)];
  
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
    call AMControl.start();
  }

  /***************** SplitControl Events ****************/
  event void AMControl.startDone(error_t error) {
    if (error == SUCCESS) {
      // Initialize the ACK_set array with zeroes
      memset(ACK_set, 0, sizeof(ACK_set));
      // Get a new messages array
      printf("DRIE\n");
      printfflush();
      p = fetch(capacity + 1);
      for (i = 0; i < (capacity+1); ++i)
      {
        printf("%d\n", *(p+i));
        printfflush();
      }
      i = 0;
      // TODO: ENCODE()

      // Divide messages into packets using packet_set()
      // printf("VIER\n");
      // printfflush();
      // pckt = packet_set();
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
      if ((inMsg->ldai == AltIndex) && (inMsg->lbl > 0) && (inMsg->lbl < (capacity + 2))) {
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
      
      printf("EEN\n");
      printfflush();

      // Below is a check for when we increment the Alternating Index
      // and start transmitting a new message.
      // As long as the ACK_set array is not full (checked by seeing if the lbl at position 11 is 0 or not),
      // we keep the label. From the moment it's full, aka 11 (capacity+1)
      // messages have been send, we put the label back at zero and increment
      // the alternating index in modulo 3.

      // If array is filled with 'capacity' packets:
      if ((ACK_set[capacity].lbl != 0) && (ACK_set[capacity].ldai == AltIndex)) {
        printf("TWEE\n");
        printfflush();

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
        printf("DRIE\n");
        printfflush();
        p = fetch(capacity + 1);
        // TODO: ENCODE()

        // Divide messages into packets using packet_set()
        // printf("VIER\n");
        // printfflush();
        // pckt = packet_set();

        for ( i = 0; i < (capacity + 1); i++ ) {
          // printf("*(pckt + %d) : %d\n", i, *(pckt + i));
          // printf("%d\n", *(pckt + i));
          printf("%d\n", *(p + i));
          printfflush();
        }

        i = 0;
      }

      // The message to send is filled with the appropriate data
      btrMsg->ai = AltIndex;
      printf("%d\n", btrMsg->ai);
      btrMsg->lbl = msgLbl;
      printf("%d\n", btrMsg->lbl);
      // btrMsg->dat = *(pckt + i);
      btrMsg->dat = *(p + i);
      printf("%d\n", btrMsg->dat);
      btrMsg->nodeid = TOS_NODE_ID;

      if(call AMSend.send(AM_BROADCAST_ADDR, &myMsg, sizeof(SECMsg)) != SUCCESS) {
        post send();
      } else {
        busy = TRUE;
      }
    }
  }

  /***************** User-defined functions ****************/
  // function returning messages array
  uint16_t * fetch(uint8_t pl) {    
    static uint16_t messages[(capacity + 1)];

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

    uint16_t x = 0;
    // static uint8_t rows = (capacity + 1);
    // static uint8_t columns = 16;
    
    // printf("VIJF\n");
    // printfflush();

    uint16_t result[rows][columns];

    // printf("ZES\n");
    // printfflush();

    uint16_t transpose[columns][rows];

    // printf("ZEVEN\n");
    // printfflush();

    static uint16_t packets[rows];

    printf("ACHT\n");
    printfflush();

    // Initalize 2D arrays with zeroes
    printf("NEGEN\n");
    printfflush();
    for (i = 0; i < rows; ++i)
    {
      printf("TIEN\n");
      printfflush();
      packets[i] = 0;
      for (j = 0; j < columns; ++j)
      {
        printf("ELF\n");
        printfflush();
        result[i][j] = 0;
        printf("TWAALF\n");
        printfflush();
        transpose[i][j] = 0;
      }
    }

    printf("INITIALIZE\n");
    printfflush();

    // Transfer 'rows' amount of counter values to bits
    // The bits are stored in the 2D array 'result'
    for (i = 0; i < rows; ++i)
    {
      x = *(p + i);
      for (j = 0; j < columns; ++j)
      {
        result[i][j] = (x & 0x8000) >> 15;
        x <<= 1;
      }
    }

    printf("BIT CONVERSION\n");
    printfflush();

    // Transpose the 'result' array and put the result in 'transpose'
    for (i = 0; i < rows; ++i)
    {
      for (j = 0; j < columns; ++j)
      {
        transpose[i][j] = result[j][i];
      }
    }

    printf("TRANSPOSE\n");
    printfflush();

    // Convert the transposed bit array into a decimal value array
    x = 1;
    for (i = 0; i < rows; ++i)
    {
      packets[i] = transpose[i][0];
      for (j = 1; j < columns; ++j)
      {
        if (transpose[i][j] == 1) packets[i] = packets[i] * 2 + 1;
        else if (transpose[i][j] == 0) packets[i] *= 2;
      }
    }

    printf("CONVERT\n");
    printfflush();

    return packets;
  }
}