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
#include <math.h>
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

  #define CAPACITY 31           // CAPACITY can't be higher than the value of kk! (see Reed-Solomon variables)
  #define ROWS CAPACITY
  #define COLUMNS 16
  #define SENDNODES 1

  /***************** Reed-Solomon constants and variables ****************/
  #define mm 8                  /* the code symbol size in bits; RS code over GF(2**4) - change to suit */
  #define nn 255                /* the block size in symbols, which is always (2**mm - 1) */
  #define tt 31                 /* number of errors that can be corrected */
  #define kk 192                /* kk = nn-2*tt; the number of data symbols per block, kk < nn */

  #define enclen (2 * tt + CAPACITY + 1)  // The length of the encoded data
  // for tt = 31, CAPCACITY = 31: enclen = 94

  /***************** Local variables ****************/
  // Boolean to check if channel is busy
  bool busy = FALSE;

  // Array to hold the ACK messagess
  /*nx_struct ACKMsg ACK_set[CAPACITY];*/
  nx_struct ACKMsg ACK_set[enclen];         // The above line is commented, since we're only executing RS once
                                            // and then sending all packets from that one fetch() operation

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

  /***************** Reed-Solomon constants and variables ****************/
  // Specify irreducible polynomial coefficients
  // If mm = 8
  int pp[mm+1] = { 1, 0, 1, 1, 1, 0, 0, 0, 1 };

  nx_uint16_t alpha_to [nn+1], index_of [nn+1], gg [nn-kk+1] ;
  nx_uint16_t recd [nn], data [kk], bb [nn-kk] ;
  // recd[255]; data[192]; bb[63]

  /***************** Prototypes ****************/
  task void send();

  // declaration of fetch function to get an array of new messages
  /*uint16_t * fetch(uint8_t pl);*/
  void fetch();

  // declaration of packet_set function to generate packets for sending
  uint16_t * packet_set();

  // Reed-Solomon functions
  void generate_gf();
  void gen_poly();
  void encode_rs();

  /***************** Boot Events ****************/
  event void Boot.booted() {
    call AMControl.start();
  }

  /***************** SplitControl Events ****************/
  event void AMControl.startDone(error_t error) {
    if (error == SUCCESS) {

      printf("AMControl.startDone");
      printfflush();

      // Initialize the ACK_set array with zeroes
      memset(ACK_set, 0, sizeof(ACK_set));

      // Get a new messages array
      /*p = fetch(CAPACITY);*/
      fetch();
      printf("fetch");
      printfflush();

      /* generate the Galois Field GF(2**mm) */
      printf("generate_gf()");
      printfflush();
      generate_gf() ;

      /* compute the generator polynomial for this RS code */
      printf("gen_poly");
      printfflush();
      gen_poly() ;

      /* encode data[] to produce parity in bb[].  Data input and parity output
      is in polynomial form */
      printf("encode");
      printfflush();
      encode_rs() ;

      /* put the transmitted codeword, made up of data plus parity, in recd[] */
      printf("fill recd[]");
      printfflush();
      for (i=0; i<nn-kk; i++)  recd[i] = bb[i] ;
      for (i=0; i<kk; i++) recd[i+nn-kk] = data[i] ;

      // Divide messages into packets using packet_set()
      /*pckt = packet_set();*/

      // Reset the loop variable
      i = 0;

      printf("AMControl.startDone FINISHED");
      printfflush();

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
      // As long as the ACK_set array is not full (checked by seeing if the lbl at position CAPCACITY is 0 or not),
      // we keep the label. From the moment it's full, aka 11 (CAPACITY+1)
      // messages have been send, we put the label back at zero and increment
      // the alternating index in modulo 3.

      // If array is filled with 'CAPACITY' packets:
      // TODO: CHECKEN OF ARRAY VOL IS, NIET ENKEL LAATSTE ELEMENT
      /*if ((ACK_set[(CAPACITY -1)].lbl != 0) && (ACK_set[(CAPACITY - 1)].ldai == AltIndex)) {*/
      if ((ACK_set[(enclen -1)].lbl != 0) && (ACK_set[(enclen - 1)].ldai == AltIndex)) {
        // The above line (two lines up) is commented, since we're only executing RS once
        // and then sending all packets from that one fetch() operation

        // Put variable msgLbl back to 1 (starting point)
        msgLbl = 1;

        // Increment the Alternating Index in modulo 3
        ++AltIndex;
        AltIndex %= 3;

        // Clear the ACK_set array
        memset(ACK_set, 0, sizeof(ACK_set));
        // Clear the data array
        memset(data, 0, sizeof(data));

        // Get a new messages array
        /*p = fetch(CAPACITY);*/
        fetch();

        // Divide messages into packets using packet_set()
        /*pckt = packet_set();*/

        /* encode data[] to produce parity in bb[].  Data input and parity output
        is in polynomial form */
        encode_rs() ;

        /* put the transmitted codeword, made up of data plus parity, in recd[] */
        for (i=0; i<nn-kk; i++)  recd[i] = bb[i] ;
        for (i=0; i<kk; i++) recd[i+nn-kk] = data[i] ;

        // Reset the loop variable
        i = 0;
      }
      // The message to send is filled with the appropriate data
      btrMsg->ai = AltIndex;
      btrMsg->lbl = msgLbl;
      /*btrMsg->dat = *(pckt + i);*/
      btrMsg->dat = recd[i];
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
  /*uint16_t * fetch(uint8_t pl) {*/
  void fetch() {
    /*static uint16_t messages[CAPACITY];*/

    for ( i = 0; i < CAPACITY; ++i) {
    /*for ( i = 0; i < pl; ++i) {*/
      /*messages[i] = counter;*/
      data[i] = counter;
      // Increment the counter (for pl amount of messages)
      ++counter;
    }
    /*return messages;*/
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

  // Reed-Solomon functions
  void generate_gf()
  /* generate GF(2**mm) from the irreducible polynomial p(X) in pp[0]..pp[mm]
     lookup tables:  index->polynomial form   alpha_to[] contains j=alpha**i;
                     polynomial form -> index form  index_of[j=alpha**i] = i
     alpha=2 is the primitive element of GF(2**mm)
  */
  {
    /*register int i, mask ;*/
    register int mask ;

    mask = 1 ;
    alpha_to[mm] = 0 ;
    for (i=0; i<mm; i++)
    {
      alpha_to[i] = mask ;
      index_of[alpha_to[i]] = i ;
      if (pp[i]!=0)
        alpha_to[mm] ^= mask ;
      mask <<= 1 ;
    }
    index_of[alpha_to[mm]] = mm ;
    mask >>= 1 ;
    for (i=mm+1; i<nn; i++)
    {
      if (alpha_to[i-1] >= mask)
        alpha_to[i] = alpha_to[mm] ^ ((alpha_to[i-1]^mask)<<1) ;
      else alpha_to[i] = alpha_to[i-1]<<1 ;
        index_of[alpha_to[i]] = i ;
    }
    index_of[0] = -1 ;
  }

  void gen_poly()
  /* Obtain the generator polynomial of the tt-error correcting, length
    nn=(2**mm -1) Reed Solomon code  from the product of (X+alpha**i), i=1..2*tt
  */
  {
    /*register int i,j ;*/

    gg[0] = 2 ;    /* primitive element alpha = 2  for GF(2**mm)  */
    gg[1] = 1 ;    /* g(x) = (X+alpha) initially */
    for (i=2; i<=nn-kk; i++)
    {
      gg[i] = 1 ;
      for (j=i-1; j>0; j--)
        if (gg[j] != 0)  gg[j] = gg[j-1]^ alpha_to[(index_of[gg[j]]+i)%nn] ;
        else gg[j] = gg[j-1] ;
      gg[0] = alpha_to[(index_of[gg[0]]+i)%nn] ;     /* gg[0] can never be zero */
    }
    /* convert gg[] to index form for quicker encoding */
    for (i=0; i<=nn-kk; i++)  gg[i] = index_of[gg[i]] ;
  }

  void encode_rs()
  /* take the string of symbols in data[i], i=0..(k-1) and encode systematically
     to produce 2*tt parity symbols in bb[0]..bb[2*tt-1]
     data[] is input and bb[] is output in polynomial form.
     Encoding is done by using a feedback shift register with appropriate
     connections specified by the elements of gg[], which was generated above.
     Codeword is   c(X) = data(X)*X**(nn-kk)+ b(X)          */
  {
    /*register int i,j ;*/
    int feedback ;

    for (i=0; i<nn-kk; i++)   bb[i] = 0 ;
    for (i=kk-1; i>=0; i--)
    {
      feedback = index_of[data[i]^bb[nn-kk-1]] ;
      if (feedback != -1)
      {
        for (j=nn-kk-1; j>0; j--)
          if (gg[j] != -1)
            bb[j] = bb[j-1]^alpha_to[(gg[j]+feedback)%nn] ;
          else
            bb[j] = bb[j-1] ;
          bb[0] = alpha_to[(gg[0]+feedback)%nn] ;
      }
      else
      {
        for (j=nn-kk-1; j>0; j--)
          bb[j] = bb[j-1] ;
        bb[0] = 0 ;
      } ;
    } ;
  } ;


}
