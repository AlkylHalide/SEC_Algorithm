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
#include <math.h>
#include <Timer.h>
#include <lib6lowpan/ip.h>
#include "SECReceive.h"

module SECReceiveP {
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
  #define n (pl+2*tt)         // amount of labels for packages
                              // calculated with encryption parameters
  #define capacity (n-1)

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

  struct sockaddr_in6 dest;
  nx_struct ACKMsg* outMsg;

  /***************** Reed-Solomon constants and variables ****************/
  // Specify irreducible polynomial coefficients
  // If mm = 8
  int pp[mm+1] = { 1, 0, 1, 1, 1, 0, 0, 0, 1 };

  nx_uint16_t alpha_to [nn+1], index_of [nn+1], gg [nn-kk+1] ;
  nx_uint16_t recd [nn], data [kk], bb [nn-kk] ;

  ////************PACKET MODIFICATION************////
  // Variable to keep track of the amount of iterations
  uint32_t iteration = 0;
  // Variable to keep track of wrong packages
  uint32_t missed = 0;
  // probability is a number between 0 and 100, defined as a percentage
  // Example: probability = 50 --> 50% chance
  uint16_t probability = 10;
  // Variable to count the amount of message deliveries (see deliver() function)
  // This can be used to count only the amount of times a batch of messages is
  // actually delivered, instead of all the iterations
  uint16_t deliverCounter = 0;
  ////*******************************************////

  /***************** Prototypes ****************/
  // task to encompass all sending operations
  task void send();
  task void sendDone();

  // declaration of deliver function to deliver the received messages to the application layer
  void deliver();

  // boolean function to check if the incoming packet is valid
  bool checkIncoming(uint8_t pcktAi, uint8_t pcktLbl);

  // boolean function to check if the contents of packet_set are valid
  bool checkValid();

  // boolean function to check if ready for delivery
  bool checkPacketSet();

  // Reed-Solomon functions
  void generate_gf();
  void gen_poly();
  void encode_rs();
  void decode_rs();

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

        // Initialize the random seed
        srand(abs(rand() % 100 + 1));

        // Initialize the ACK_set array with zeroes
        memset(packet_set, 0, sizeof(packet_set));

        // Initalize Reed-Solomon functions
        // generate the Galois Field GF(2**mm)
        generate_gf();
        // compute the generator polynomial for this RS code
        gen_poly();

        // Immediately start sending ACK messages at startup
        if(TOS_NODE_ID != RPL_ROOT_ADDR){
          // Execute the send task next
          // Only if this node is not the root node
          post send();
        }
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
  event void RPLUDP.recvfrom(struct sockaddr_in6 *from, void *payload, uint16_t len, struct ip6_metadata *meta) {
    // Check the received packet's AM type. If it's not a valid message
    // type (AM_SECMSG), return it
    if (len != sizeof(SECMsg)) {
      return;
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
          switch(abs(rand() % 2 + 1)) {
            case 0 :
              // Omit the package
              return;
              break;

            case 1 :
              // Duplicate package
              inMsg->lbl = (inMsg->lbl + abs(rand() % (capacity) + 1)) % capacity;
              break;

            case 2 :
              // Reorder package
              inMsg->lbl = abs(rand() % (capacity) + 1);
              break;
          }
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

  task void send() {
    if(!busy){
      atomic {
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

        // DIRECT ADDRESSING WITHOUT STRING PARSE OVERHEAD
        memset(&dest, 0, sizeof(struct sockaddr_in6));
        dest.sin6_addr.s6_addr16[0] = htons(0xfec0);
        dest.sin6_addr.s6_addr[15] = (TOS_NODE_ID - sendnodes);
        dest.sin6_port = htons(UDP_PORT);
      }

      call RPLUDP.sendto(&dest, &outMsg, sizeof(ACKMsg));
      busy = TRUE;
      post sendDone();
    }
  }

  /***************** User-defined functions ****************/
  // function returning messages array
  void deliver() {
    // put packet_set[] contents in recd[] for decoding
    for (i=0; i<(capacity+1); i++) {
      recd[i] = packet_set[i].dat;
    }

    //put recd[i] into index form
    for (i=0; i<nn; i++) {
      recd[i] = index_of[recd[i]];
    }

    // decode recv[]
    // recd[] is returned in polynomial form
    decode_rs();

    // Uncomment this to print data instead of measurements
    /*printf("DELIVER MESSAGES\n");
    for ( i = (2*tt); i < (2*tt+pl); i++) {
      printf("%u\n", recd[i]);
    }*/
    ++deliverCounter;
    printf("%u    %lu   %lu\n", deliverCounter, iteration, missed);
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

    void decode_rs()
    /* assume we have received bits grouped into mm-bit symbols in recd[i],
       i=0..(nn-1),  and recd[i] is index form (ie as powers of alpha).
       We first compute the 2*tt syndromes by substituting alpha**i into rec(X) and
       evaluating, storing the syndromes in s[i], i=1..2tt (leave s[0] zero) .
       Then we use the Berlekamp iteration to find the error location polynomial
       elp[i].   If the degree of the elp is >tt, we cannot correct all the errors
       and hence just put out the information symbols uncorrected. If the degree of
       elp is <=tt, we substitute alpha**i , i=1..n into the elp to get the roots,
       hence the inverse roots, the error location numbers. If the number of errors
       located does not equal the degree of the elp, we have more than tt errors
       and cannot correct them.  Otherwise, we then solve for the error value at
       the error location and correct the error.  The procedure is that found in
       Lin and Costello. For the cases where the number of errors is known to be too
       large to correct, the information symbols as received are output (the
       advantage of systematic encoding is that hopefully some of the information
       symbols will be okay and that if we are in luck, the errors are in the
       parity part of the transmitted codeword).  Of course, these insoluble cases
       can be returned as error flags to the calling routine if desired.   */
     {
       register int f,g,u,q ;
       int elp[nn-kk+2][nn-kk], d[nn-kk+2], l[nn-kk+2], u_lu[nn-kk+2], s[nn-kk+1] ;
       int count=0, syn_error=0, root[tt], loc[tt], z[tt+1], err[nn], reg[tt+1] ;

    /* first form the syndromes */
       for (f=1; f<=nn-kk; f++)
        { s[f] = 0 ;
          for (g=0; g<nn; g++)
            if (recd[g]!=-1)
              s[f] ^= alpha_to[(recd[g]+f*g)%nn] ;      /* recd[g] in index form */
    /* convert syndrome from polynomial form to index form  */
          if (s[f]!=0)  syn_error=1 ;        /* set flag if non-zero syndrome => error */
          s[f] = index_of[s[f]] ;
        } ;

       if (syn_error)       /* if errors, try and correct */
        {
    /* compute the error location polynomial via the Berlekamp iterative algorithm,
       following the terminology of Lin and Costello :   d[u] is the 'mu'th
       discrepancy, where u='mu'+1 and 'mu' (the Greek letter!) is the step number
       ranging from -1 to 2*tt (see L&C),  l[u] is the
       degree of the elp at that step, and u_l[u] is the difference between the
       step number and the degree of the elp.
    */
    /* initialise table entries */
          d[0] = 0 ;           /* index form */
          d[1] = s[1] ;        /* index form */
          elp[0][0] = 0 ;      /* index form */
          elp[1][0] = 1 ;      /* polynomial form */
          for (f=1; f<nn-kk; f++)
            { elp[0][f] = -1 ;   /* index form */
              elp[1][f] = 0 ;   /* polynomial form */
            }
          l[0] = 0 ;
          l[1] = 0 ;
          u_lu[0] = -1 ;
          u_lu[1] = 0 ;
          u = 0 ;

          do
          {
            u++ ;
            if (d[u]==-1)
              { l[u+1] = l[u] ;
                for (f=0; f<=l[u]; f++)
                 {  elp[u+1][f] = elp[u][f] ;
                    elp[u][f] = index_of[elp[u][f]] ;
                 }
              }
            else
    /* search for words with greatest u_lu[q] for which d[q]!=0 */
              { q = u-1 ;
                while ((d[q]==-1) && (q>0)) q-- ;
    /* have found first non-zero d[q]  */
                if (q>0)
                 { g=q ;
                   do
                   { g-- ;
                     if ((d[g]!=-1) && (u_lu[q]<u_lu[g]))
                       q = g ;
                   }while (g>0) ;
                 } ;

    /* have now found q such that d[u]!=0 and u_lu[q] is maximum */
    /* store degree of new elp polynomial */
                if (l[u]>l[q]+u-q)  l[u+1] = l[u] ;
                else  l[u+1] = l[q]+u-q ;

    /* form new elp(x) */
                for (f=0; f<nn-kk; f++)    elp[u+1][f] = 0 ;
                for (f=0; f<=l[q]; f++)
                  if (elp[q][f]!=-1)
                    elp[u+1][f+u-q] = alpha_to[(d[u]+nn-d[q]+elp[q][f])%nn] ;
                for (f=0; f<=l[u]; f++)
                  { elp[u+1][f] ^= elp[u][f] ;
                    elp[u][f] = index_of[elp[u][f]] ;  /*convert old elp value to index*/
                  }
              }
            u_lu[u+1] = u-l[u+1] ;

    /* form (u+1)th discrepancy */
            if (u<nn-kk)    /* no discrepancy computed on last iteration */
              {
                if (s[u+1]!=-1)
                       d[u+1] = alpha_to[s[u+1]] ;
                else
                  d[u+1] = 0 ;
                for (f=1; f<=l[u+1]; f++)
                  if ((s[u+1-f]!=-1) && (elp[u+1][f]!=0))
                    d[u+1] ^= alpha_to[(s[u+1-f]+index_of[elp[u+1][f]])%nn] ;
                d[u+1] = index_of[d[u+1]] ;    /* put d[u+1] into index form */
              }
          } while ((u<nn-kk) && (l[u+1]<=tt)) ;

          u++ ;
          if (l[u]<=tt)         /* can correct error */
           {
    /* put elp into index form */
             for (f=0; f<=l[u]; f++)   elp[u][f] = index_of[elp[u][f]] ;

    /* find roots of the error location polynomial */
             for (f=1; f<=l[u]; f++)
               reg[f] = elp[u][f] ;
             count = 0 ;
             for (f=1; f<=nn; f++)
              {  q = 1 ;
                 for (g=1; g<=l[u]; g++)
                  if (reg[g]!=-1)
                    { reg[g] = (reg[g]+g)%nn ;
                      q ^= alpha_to[reg[g]] ;
                    } ;
                 if (!q)        /* store root and error location number indices */
                  { root[count] = f;
                    loc[count] = nn-f ;
                    count++ ;
                  };
              } ;
             if (count==l[u])    /* no. roots = degree of elp hence <= tt errors */
              {
    /* form polynomial z(x) */
               for (f=1; f<=l[u]; f++)        /* Z[0] = 1 always - do not need */
                { if ((s[f]!=-1) && (elp[u][f]!=-1))
                     z[f] = alpha_to[s[f]] ^ alpha_to[elp[u][f]] ;
                  else if ((s[f]!=-1) && (elp[u][f]==-1))
                          z[f] = alpha_to[s[f]] ;
                       else if ((s[f]==-1) && (elp[u][f]!=-1))
                              z[f] = alpha_to[elp[u][f]] ;
                            else
                              z[f] = 0 ;
                  for (g=1; g<f; g++)
                    if ((s[g]!=-1) && (elp[u][f-g]!=-1))
                       z[f] ^= alpha_to[(elp[u][f-g] + s[g])%nn] ;
                  z[f] = index_of[z[f]] ;         /* put into index form */
                } ;

      /* evaluate errors at locations given by error location numbers loc[i] */
               for (f=0; f<nn; f++)
                 { err[f] = 0 ;
                   if (recd[f]!=-1)        /* convert recd[] to polynomial form */
                     recd[f] = alpha_to[recd[f]] ;
                   else  recd[f] = 0 ;
                 }
               for (f=0; f<l[u]; f++)    /* compute numerator of error term first */
                { err[loc[f]] = 1;       /* accounts for z[0] */
                  for (g=1; g<=l[u]; g++)
                    if (z[g]!=-1)
                      err[loc[f]] ^= alpha_to[(z[g]+g*root[f])%nn] ;
                  if (err[loc[f]]!=0)
                   { err[loc[f]] = index_of[err[loc[f]]] ;
                     q = 0 ;     /* form denominator of error term */
                     for (g=0; g<l[u]; g++)
                       if (g!=f)
                         q += index_of[1^alpha_to[(loc[g]+root[f])%nn]] ;
                     q = q % nn ;
                     err[loc[f]] = alpha_to[(err[loc[f]]-q+nn)%nn] ;
                     recd[loc[f]] ^= err[loc[f]] ;  /*recd[i] must be in polynomial form */
                   }
                }
              }
             else    /* no. roots != degree of elp => >tt errors and cannot solve */
               for (f=0; f<nn; f++)        /* could return error flag if desired */
                   if (recd[f]!=-1)        /* convert recd[] to polynomial form */
                     recd[f] = alpha_to[recd[f]] ;
                   else  recd[f] = 0 ;     /* just output received codeword as is */
           }
         else         /* elp has degree has degree >tt hence cannot solve */
           for (f=0; f<nn; f++)       /* could return error flag if desired */
              if (recd[f]!=-1)        /* convert recd[] to polynomial form */
                recd[f] = alpha_to[recd[f]] ;
              else  recd[f] = 0 ;     /* just output received codeword as is */
        }
       else       /* no non-zero syndromes => no errors: output received codeword */
        for (f=0; f<nn; f++)
           if (recd[f]!=-1)        /* convert recd[] to polynomial form */
             recd[f] = alpha_to[recd[f]] ;
           else  recd[f] = 0 ;
     }
}
