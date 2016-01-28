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
#include <Timer.h>
#include <lib6lowpan/ip.h>
#include "SECSend.h"

module SECSendP {
  uses {
    interface Boot;
    interface SplitControl as AMControl;
    interface Timer<TMilli> as Timer0;
    interface RPLRoutingEngine as RPLRoute;
    interface RootControl;
    interface StdControl as RoutingControl;
    interface UDP as RPLUDP;
    interface RPLDAORoutingEngine as RPLDAO;
  }
}

implementation {
  /********* RPL constants *********/
  #ifndef RPL_ROOT_ADDR
  #define RPL_ROOT_ADDR 1
  #endif

  #define UDP_PORT 5678

  /***************** Reed-Solomon constants and variables ****************/
  #define mm 8                 /* length of codeword */
  #define nn 255               /* nn=2**mm - 1 --> the block size in symbols */
  #define tt 16                /* number of errors that can be corrected */
  #define kk 223               /* kk = nn-2*tt */

  // Packet generation variables
  #define pl 16               // amount of messages to get from application layer
  #define n (pl+2*tt)         // amount of labels for packages*/
                              // calculated with encryption parameters

  // <capacity> amount of messages
  #define capacity (n-1)

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

  struct sockaddr_in6 dest;
  nx_struct SECMsg* btrMsg;

  /***************** Reed-Solomon constants and variables ****************/
  // Specify irreducible polynomial coefficients
  // If mm = 8
  int pp[mm+1] = { 1, 0, 1, 1, 1, 0, 0, 0, 1 };

  nx_uint16_t alpha_to [nn+1], index_of [nn+1], gg [nn-kk+1] ;
  nx_uint16_t recd [nn], data [kk], bb [nn-kk] ;

  /***************** Prototypes ****************/
  task void send();
  task void sendDone();

  // declaration of fetch function to get an array of new messages
  uint16_t * fetch(uint8_t NumOfMessages);

  // Boolean function to check the contents of the ACK array
  bool checkAckSet();

  // Reed-Solomon functions
  void generate_gf();
  void gen_poly();
  void encode_rs();
  void reedSolomon();

  /***************** Boot Events ****************/
  event void Boot.booted() {
    if(TOS_NODE_ID == RPL_ROOT_ADDR){
      call RootControl.setRoot();
    }
    call RoutingControl.start();
    call AMControl.start();

    call RPLUDP.bind(UDP_PORT);
  }

  /***************** SplitControl Events ****************/
  event void AMControl.startDone(error_t error) {
    if (error == SUCCESS) {
      atomic {
        while( call RPLDAO.startDAO() != SUCCESS );

        // Initialize the ACK_set array with zeroes
        memset(ACK_set, 0, sizeof(ACK_set));

        // Initalize Reed-Solomon functions
        // generate the Galois Field GF(2**mm)
        generate_gf();
        // compute the generator polynomial for this RS code
        gen_poly();

        reedSolomon();

        if(TOS_NODE_ID != RPL_ROOT_ADDR){
          // Execute the send task next
          // Only if this node is not the root node
          post send();
        }
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
  event void RPLUDP.recvfrom(struct sockaddr_in6 *from, void *payload, uint16_t len, struct ip6_metadata *meta){
    if (len != sizeof(ACKMsg)) {
      return;
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

      return;
    }
  }

  /***************** Timer Events ****************/
  event void Timer0.fired() {
    post send();
  }

  /***************** Tasks ****************/
  task void sendDone() {
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
      msgIndex %= (nn-kk+pl);
    }

    if(DELAY_BETWEEN_MESSAGES > 0) {
      call Timer0.startOneShot(DELAY_BETWEEN_MESSAGES);
    } else {
      post send();
    }
  }

  task void send() {
    if(!busy) {
      atomic {
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

          // Reset the loop variable
          msgIndex = 0;

          reedSolomon();
        }

        // The message to send is filled with the appropriate data
        btrMsg->ai = AltIndex;
        btrMsg->lbl = msgLbl;
        btrMsg->dat = recd[msgIndex];
        btrMsg->nodeid = TOS_NODE_ID;

        // DIRECT ADDRESSING WITHOUT STRING PARSE OVERHEAD
        memset(&dest, 0, sizeof(struct sockaddr_in6));
        dest.sin6_addr.s6_addr16[0] = htons(0xfec0);
        dest.sin6_addr.s6_addr[15] = (TOS_NODE_ID + sendnodes);
        dest.sin6_port = htons(UDP_PORT);
      }

      call RPLUDP.sendto(&dest, &btrMsg, sizeof(SECMsg));
      busy = TRUE;
      post sendDone();
    }
  }

  /***************** User-defined functions ****************/
  void reedSolomon(){
    // Get a new messages array
    messages = fetch(pl);

    // zero all data[] entries
    for  (i=0; i<kk; i++)   data[i] = 0;
    // put messages in data array
    for  (i=0; i<pl; i++) {
      data[i] = *(messages + i);
    }

    // encode data
    encode_rs();

    // put the transmitted codeword, made up of data plus parity, in recd[]
    for (i=0; i<nn-kk; i++) {
      recd[i] = bb[i];
    }
    for (i=0; i<kk; i++) {
      recd[i+nn-kk] = data[i];
    }
  }

  // function returning messages array M
  uint16_t * fetch(uint8_t NumOfMessages) {
    static uint16_t M[pl];

    for ( i = 0; i < NumOfMessages; ++i) {
      M[i] = counter;
      // Increment the counter (for pl amount of messages)
      ++counter;
      // The Reed-Solomon functions take a maximum integer
      // value of 255 [(2^8)-1]
      counter %= 256;
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

  void generate_gf()
  /* generate GF(2**mm) from the irreducible polynomial p(X) in pp[0]..pp[mm]
     lookup tables:  index->polynomial form   alpha_to[] contains j=alpha**i;
                     polynomial form -> index form  index_of[j=alpha**i] = i
     alpha=2 is the primitive element of GF(2**mm)
  */
   {
     register int mask ;

    mask = 1 ;
    alpha_to[mm] = 0 ;
    for (i=0; i<mm; i++)
     { alpha_to[i] = mask ;
       index_of[alpha_to[i]] = i ;
       if (pp[i]!=0)
         alpha_to[mm] ^= mask ;
       mask <<= 1 ;
     }
    index_of[alpha_to[mm]] = mm ;
    mask >>= 1 ;
    for (i=mm+1; i<nn; i++)
     { if (alpha_to[i-1] >= mask)
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
       { gg[i] = 1 ;
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
      register int x,y ;
      int feedback ;

      for (x=0; x<nn-kk; x++)   bb[x] = 0 ;
      for (x=kk-1; x>=0; x--)
       {  feedback = index_of[data[x]^bb[nn-kk-1]] ;
          if (feedback != -1)
           { for (y=nn-kk-1; y>0; y--)
               if (gg[y] != -1)
                 bb[y] = bb[y-1]^alpha_to[(gg[y]+feedback)%nn] ;
               else
                 bb[y] = bb[y-1] ;
             bb[0] = alpha_to[(gg[0]+feedback)%nn] ;
           }
          else
           { for (y=nn-kk-1; y>0; y--)
               bb[y] = bb[y-1] ;
             bb[0] = 0 ;
           } ;
       } ;
    } ;
}
