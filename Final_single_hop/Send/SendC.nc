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
#include "Send.h"

module SendC {
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
  /***************** Algorithm  variables ****************/
  // AltIndex
  uint8_t AltIndex = 0;

  // Array to hold the ACK messagess
  nx_struct ACK ACK_set[(capacity + 1)];

  /***************** Implementation variables ****************/
  // Boolean to check if channel is busy
  bool busy = FALSE;

  // Message/data variable as a counter
  uint8_t counter = 0;

  // Keep track of message label in sendTask
  uint8_t msgLbl = 0;

  // Message to transmit
  message_t myMsg;

  // Array runthrough variables
  uint8_t i = 0;
  uint8_t j = 0;
  uint8_t msgIndex = 0;

  // Pointer to the messages
  uint16_t *messages;

  /***************** Error Correction variables ****************/
  // IF mm = 8
  int pp[mm+1] = { 1, 0, 1, 1, 1, 0, 0, 0, 1 };
  int alpha_to [nn+1], index_of [nn+1], gg [nn-kk+1] ;
  int recd [nn], data [kk], bb [nn-kk] ;

  /***************** Error Correction functions ****************/
  /* generate the Galois Field GF(2**mm) */
  void generate_gf() ;
  /* compute the generator polynomial for this RS code */
  void gen_poly() ;
  // declaration of encode function to encode messages
  uint16_t * encode(uint16_t *M);

  /***************** Interfaces ****************/
  // declaration of fetch function to get an array of new messages
  uint16_t * fetch(uint8_t NumOfMessages);

  /***************** Prototypes ****************/
  // Task for sending
  task void send();

  // function packet_set: formation of packets from messages
  uint16_t * packet_set();

  bool checkAckSet();

  /***************** Boot Event ****************/
  event void Boot.booted() {
    call AMControl.start();
  }

  /***************** SplitControl Events ****************/
  event void AMControl.startDone(error_t error) {
    if (error == SUCCESS) {
      atomic {
        // Initialize the ACK_set array with zeroes
        memset(ACK_set, 0, sizeof(ACK_set));

        // Retrieve a new batch of messages
        messages = encode(fetch(pl));
      }

      // Call the send task to be executed next
      post send();
    }
    else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t error) {
    // do nothing
  }

  /***************** Timer Events ****************/
  event void Timer0.fired() {
    post send();
  }

  /***************** AMSend Events ****************/
  event void AMSend.sendDone(message_t *msg, error_t error) {
    atomic {
      // Sending channel is free again
      busy = FALSE;

      // Increment the message index for the next MSG to be sent in modulo n
      ++msgIndex;
      msgIndex %= n;
    }

    // Set timer to fire after DELAY_BETWEEN_MESSAGES
    if(DELAY_BETWEEN_MESSAGES > 0) {
      call Timer0.startOneShot(DELAY_BETWEEN_MESSAGES);
    } else {
      post send();
    }
  }

  /***************** Receive Events ****************/
  event message_t *Receive.receive(message_t *msg, void *payload, uint8_t len) {
    if(call AMPacket.type(msg) != AM_ACK) {
      return msg;
    }
    else {
      ACK* inMsg = (ACK*)payload;

      // Check if LastDeliveredIndex is equal to the current Alternating Index and
      // check if label lies in [1 10] interval
      if ((inMsg->ldai == AltIndex) && (inMsg->lbl > 0) && (inMsg->lbl < (n+1)) && (inMsg->nodeid == (TOS_NODE_ID + sendnodes))) {
        // Add incoming packet to ACK_set at (lbl - 1)
        // This ensures the packet is in the right spot
        ACK_set[((inMsg->lbl)-1)].ldai = inMsg->ldai;
        ACK_set[((inMsg->lbl)-1)].lbl = inMsg->lbl;
        ACK_set[((inMsg->lbl)-1)].nodeid = inMsg->nodeid;
      }

      ++msgLbl;

      return msg;
    }
  }

  /***************** Tasks ****************/
  task void send() {
    if(!busy){
      atomic {
        // Retrieve message payload
        MSG* outMSG = (MSG*)(call Packet.getPayload(&myMsg, sizeof(MSG)));

        // If array is filled with 'capacity+1' packets of ( AltIndex x [1, n] )
        if (checkAckSet()) {

          // Increment AltIndex in modulo 3
          ++AltIndex;
          AltIndex %= 3;

          // Put label index back to initial value
          msgLbl = 1;

          // Empty ACK_set
          memset(ACK_set, 0, sizeof(ACK_set));

          // Get a new message batch
          messages = encode(fetch(pl));
        }

        // The message to send is filled with the appropriate data
        outMSG->ai = AltIndex;
        outMSG->lbl = msgLbl;
        outMSG->dat = *(messages + msgIndex);
        outMSG->nodeid = TOS_NODE_ID;
      }

      if(call AMSend.send((TOS_NODE_ID + sendnodes), &myMsg, sizeof(MSG)) != SUCCESS) {
        post send();
      } else {
        busy = TRUE;
      }
    }
  }

  /***************** User-defined functions ****************/

  // Fetch function gets batch of messages
  uint16_t * fetch(uint8_t NumOfMessages) {
    // declare array of pl messages
    static uint16_t msgs[NumOfMessages];

    for ( i = 0; i < NumOfMessages; ++i) {
      msgs[i] = counter;
      // Increment the counter (for NumOfMessages amount of messages)
      ++counter;
    }
    return msgs;
  }

  // Reed-Solomon encoding
  uint16_t * encode(uint16_t *M) {
    // specify return array
    static uint16_t encM[n];

    // put data in *M in data[]
    for (i=0; i<kk; i++) {
      data[i] = *(M + i);
    }

    /* generate the Galois Field GF(2**mm) */
    generate_gf() ;

    /* compute the generator polynomial for this RS code */
    gen_poly() ;

    int feedback ;

    for (i=0; i<nn-kk; i++)   bb[i] = 0 ;
    for (i=kk-1; i>=0; i--)
     {  feedback = index_of[data[i]^bb[nn-kk-1]] ;
        if (feedback != -1)
         { for (j=nn-kk-1; j>0; j--)
             if (gg[j] != -1)
               bb[j] = bb[j-1]^alpha_to[(gg[j]+feedback)%nn] ;
             else
               bb[j] = bb[j-1] ;
           bb[0] = alpha_to[(gg[0]+feedback)%nn] ;
         }
        else
         { for (j=nn-kk-1; j>0; j--)
             bb[j] = bb[j-1] ;
           bb[0] = 0 ;
         } ;
     } ;

     /* put the transmitted codeword, made up of data plus parity, in recd[] */
     for (i=0; i<nn-kk; i++) recd[i] = bb[i] ;
     for (i=0; i<kk; i++) recd[i+nn-kk] = data[i] ;

     for (i=0; i<n; i++) {
       *(encM + i) = recd[i];
     }

     return encM;
  }

  // Packet formation from messages
  uint16_t * packet_set() {
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

  void generate_gf() {

  /* generate GF(2**mm) from the irreducible polynomial p(X) in pp[0]..pp[mm]
     lookup tables:  index->polynomial form   alpha_to[] contains j=alpha**i;
                     polynomial form -> index form  index_of[j=alpha**i] = i
     alpha=2 is the primitive element of GF(2**mm)
  */
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


  void gen_poly() {
  /* Obtain the generator polynomial of the tt-error correcting, length
    nn=(2**mm -1) Reed Solomon code  from the product of (X+alpha**i), i=1..2*tt
  */
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
}
