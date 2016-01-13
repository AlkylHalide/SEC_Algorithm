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

  /***************** Local variables ****************/
  // Boolean to check if channel is busy
  bool busy = FALSE;

  // Variable to keep track of the last delivered alternating index in the ABP protocol
  uint16_t LastDeliveredAltIndex = 2;
  uint8_t ldai = 0;

  // Label variable
  uint16_t recLbl = 0;

  // Array to contain all the received packages
  /*nx_struct SECMsg packet_set[CAPACITY];*/
  nx_struct SECMsg packet_set[enclen];

  // Define some loop variables to go through arrays
  uint8_t i = 0;
  uint8_t j = 0;

  // Message to transmit
  message_t ackMsg;

  // Variable to store the source address [Node ID] of the incoming packet
  uint16_t inNodeID = 0;

  // Pointers to an int for the messages array
  uint16_t *p;

  /***************** Reed-Solomon constants and variables ****************/
  // Specify irreducible polynomial coefficients
  // If mm = 8
  int pp[mm+1] = { 1, 0, 1, 1, 1, 0, 0, 0, 1 };

  nx_uint16_t alpha_to [nn+1], index_of [nn+1], gg [nn-kk+1] ;
  nx_uint16_t recd [nn], data [kk], bb [nn-kk] ;

  /***************** Prototypes ****************/
  task void send();

  // declaration of deliver function to deliver the received messages to the application layer
  void deliver();

  // declaration of transpose function to transpose received packets
  uint16_t * pckt();

  bool checkArray(uint8_t pcktAi, uint8_t pcktLbl);

  // Reed-Solomon functions
  void generate_gf();
  void gen_poly();
  void decode_rs();

  /***************** Boot Events ****************/
  event void Boot.booted() {
    call AMControl.start();
  }

  /***************** SplitControl Events ****************/
  event void AMControl.startDone(error_t error) {
    if (error == SUCCESS) {
      // Initialize the ACK_set array with zeroes
      memset(packet_set, 0, sizeof(packet_set));
      // Initialize the data array with zeroes
      memset(data, 0, sizeof(data));

      // Reed-Solomon functions
      generate_gf();
      gen_poly();
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

        // Delive the messages to the application layer
        deliver();
      }

      // Check if the label at position 'CAPACITY' in the packet_set array is filled in or not
      // YES: change the LastDeliveredAltIndex value to the Alternating Index value of the incoming packet.
      // NO: continue normal operation.
      /*if (packet_set[(CAPACITY-1)].lbl != 0 ) {*/
      if (packet_set[(enclen-1)].lbl != 0 ) {

        // Update LastDeliveredIndex to AI of current message array
        LastDeliveredAltIndex = inMsg->ai;

        // Transpose messages array
        /*p = pckt();*/

        // Clear the packet_set array
        memset(packet_set, 0, sizeof(packet_set));
        // Clear the data array
        memset(data, 0, sizeof(data));
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

      if(call AMSend.send((TOS_NODE_ID - SENDNODES), &ackMsg, sizeof(ACKMsg)) != SUCCESS) {
        post send();
      } else {
        busy = TRUE;
      }
    }
  }

  /***************** User-defined functions ****************/
  // function returning messages array
  void deliver() {
    /*for ( i = 0; i < CAPACITY; ++i) {*/
      /*printf("%u\n", *(p + i));*/

      // Reed-Solomon functions
      for (i=0; i<nn; i++) {
        if(i < enclen){
          recd[i] = packet_set[i].dat;          // put packet_set data into recd
        }
        recd[i] = index_of[recd[i]] ;           // put recd[i] into index form
      }

      decode_rs();

      // PRINT MESSAGE
      for (i=(enclen-(2*tt)); i<enclen; i++)
        printf("%d\n", recd[i]);
        // printf("%3u    %3u      %3u\n",i, data[i-nn+kk], recd[i]) ;
        // printf("%u\n", *(p + i));

    /*}*/
    printfflush();
  }

  // function packet_set to transpose received packets
  uint16_t * pckt() {
    // Consider message array as bit matrix
    // Transpose matrix: data[i].bit[j] = messages[j].bit[i]
    // return array with <CAPACITY> amount of received messages

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
    if ((pcktAi != LastDeliveredAltIndex) && (pcktAi < 3) && (pcktAi > -1) && (pcktLbl > 0) && (pcktLbl < (CAPACITY+1)))
    {
      for (i = 0; i < CAPACITY; ++i)
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
     register int u,q ;
     int elp[nn-kk+2][nn-kk], d[nn-kk+2], l[nn-kk+2], u_lu[nn-kk+2], s[nn-kk+1] ;
     int count=0, syn_error=0, root[tt], loc[tt], z[tt+1], err[nn], reg[tt+1] ;

  /* first form the syndromes */
     for (i=1; i<=nn-kk; i++)
      { s[i] = 0 ;
        for (j=0; j<nn; j++)
          if (recd[j]!=-1)
            s[i] ^= alpha_to[(recd[j]+i*j)%nn] ;      /* recd[j] in index form */
  /* convert syndrome from polynomial form to index form  */
        if (s[i]!=0)  syn_error=1 ;        /* set flag if non-zero syndrome => error */
        s[i] = index_of[s[i]] ;
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
        for (i=1; i<nn-kk; i++)
          { elp[0][i] = -1 ;   /* index form */
            elp[1][i] = 0 ;   /* polynomial form */
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
              for (i=0; i<=l[u]; i++)
               {  elp[u+1][i] = elp[u][i] ;
                  elp[u][i] = index_of[elp[u][i]] ;
               }
            }
          else
  /* search for words with greatest u_lu[q] for which d[q]!=0 */
            { q = u-1 ;
              while ((d[q]==-1) && (q>0)) q-- ;
  /* have found first non-zero d[q]  */
              if (q>0)
               { j=q ;
                 do
                 { j-- ;
                   if ((d[j]!=-1) && (u_lu[q]<u_lu[j]))
                     q = j ;
                 }while (j>0) ;
               } ;

  /* have now found q such that d[u]!=0 and u_lu[q] is maximum */
  /* store degree of new elp polynomial */
              if (l[u]>l[q]+u-q)  l[u+1] = l[u] ;
              else  l[u+1] = l[q]+u-q ;

  /* form new elp(x) */
              for (i=0; i<nn-kk; i++)    elp[u+1][i] = 0 ;
              for (i=0; i<=l[q]; i++)
                if (elp[q][i]!=-1)
                  elp[u+1][i+u-q] = alpha_to[(d[u]+nn-d[q]+elp[q][i])%nn] ;
              for (i=0; i<=l[u]; i++)
                { elp[u+1][i] ^= elp[u][i] ;
                  elp[u][i] = index_of[elp[u][i]] ;  /*convert old elp value to index*/
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
              for (i=1; i<=l[u+1]; i++)
                if ((s[u+1-i]!=-1) && (elp[u+1][i]!=0))
                  d[u+1] ^= alpha_to[(s[u+1-i]+index_of[elp[u+1][i]])%nn] ;
              d[u+1] = index_of[d[u+1]] ;    /* put d[u+1] into index form */
            }
        } while ((u<nn-kk) && (l[u+1]<=tt)) ;

        u++ ;
        if (l[u]<=tt)         /* can correct error */
         {
  /* put elp into index form */
           for (i=0; i<=l[u]; i++)   elp[u][i] = index_of[elp[u][i]] ;

  /* find roots of the error location polynomial */
           for (i=1; i<=l[u]; i++)
             reg[i] = elp[u][i] ;
           count = 0 ;
           for (i=1; i<=nn; i++)
            {  q = 1 ;
               for (j=1; j<=l[u]; j++)
                if (reg[j]!=-1)
                  { reg[j] = (reg[j]+j)%nn ;
                    q ^= alpha_to[reg[j]] ;
                  } ;
               if (!q)        /* store root and error location number indices */
                { root[count] = i;
                  loc[count] = nn-i ;
                  count++ ;
                };
            } ;
           if (count==l[u])    /* no. roots = degree of elp hence <= tt errors */
            {
  /* form polynomial z(x) */
             for (i=1; i<=l[u]; i++)        /* Z[0] = 1 always - do not need */
              { if ((s[i]!=-1) && (elp[u][i]!=-1))
                   z[i] = alpha_to[s[i]] ^ alpha_to[elp[u][i]] ;
                else if ((s[i]!=-1) && (elp[u][i]==-1))
                        z[i] = alpha_to[s[i]] ;
                     else if ((s[i]==-1) && (elp[u][i]!=-1))
                            z[i] = alpha_to[elp[u][i]] ;
                          else
                            z[i] = 0 ;
                for (j=1; j<i; j++)
                  if ((s[j]!=-1) && (elp[u][i-j]!=-1))
                     z[i] ^= alpha_to[(elp[u][i-j] + s[j])%nn] ;
                z[i] = index_of[z[i]] ;         /* put into index form */
              } ;

    /* evaluate errors at locations given by error location numbers loc[i] */
             for (i=0; i<nn; i++)
               { err[i] = 0 ;
                 if (recd[i]!=-1)        /* convert recd[] to polynomial form */
                   recd[i] = alpha_to[recd[i]] ;
                 else  recd[i] = 0 ;
               }
             for (i=0; i<l[u]; i++)    /* compute numerator of error term first */
              { err[loc[i]] = 1;       /* accounts for z[0] */
                for (j=1; j<=l[u]; j++)
                  if (z[j]!=-1)
                    err[loc[i]] ^= alpha_to[(z[j]+j*root[i])%nn] ;
                if (err[loc[i]]!=0)
                 { err[loc[i]] = index_of[err[loc[i]]] ;
                   q = 0 ;     /* form denominator of error term */
                   for (j=0; j<l[u]; j++)
                     if (j!=i)
                       q += index_of[1^alpha_to[(loc[j]+root[i])%nn]] ;
                   q = q % nn ;
                   err[loc[i]] = alpha_to[(err[loc[i]]-q+nn)%nn] ;
                   recd[loc[i]] ^= err[loc[i]] ;  /*recd[i] must be in polynomial form */
                 }
              }
            }
           else    /* no. roots != degree of elp => >tt errors and cannot solve */
             for (i=0; i<nn; i++)        /* could return error flag if desired */
                 if (recd[i]!=-1)        /* convert recd[] to polynomial form */
                   recd[i] = alpha_to[recd[i]] ;
                 else  recd[i] = 0 ;     /* just output received codeword as is */
         }
       else         /* elp has degree has degree >tt hence cannot solve */
         for (i=0; i<nn; i++)       /* could return error flag if desired */
            if (recd[i]!=-1)        /* convert recd[] to polynomial form */
              recd[i] = alpha_to[recd[i]] ;
            else  recd[i] = 0 ;     /* just output received codeword as is */
      }
     else       /* no non-zero syndromes => no errors: output received codeword */
      for (i=0; i<nn; i++)
         if (recd[i]!=-1)        /* convert recd[] to polynomial form */
           recd[i] = alpha_to[recd[i]] ;
         else  recd[i] = 0 ;
   }
}
