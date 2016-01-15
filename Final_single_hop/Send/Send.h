// Evert Boelaert
// S²E²C algorithm

// Sender mote broadcasts packets <Ai, lbl, dat>
// Receiver receives packets and puts them into arrays packet_set[] according to NMote ID.
// Receiver acknowledges packets by sending ACK <ldai, lbl> messages back to Sender.

// Ai = Alternating Index
// lbl = Label
// dat = data (message)
// ldai = Last Delivered Alternating Index

#ifndef SEND_H
#define SEND_H

// Reed-Solomon encoding variables
#define mm 8                 /* length of codeword */
#define nn 255               /* nn=2**mm - 1 --> the block size in symbols */
#define tt 16                /* number of errors that can be corrected */
#define kk 223               /* kk = nn-2*tt */

// Packet generation variables
#define pl 16
#define n (pl+2*tt)         // amount of labels for packages
                             // calculated with encryption parameters
#define capacity (n-1)

// define amount of sending nodes in the network
// there should be an equal amount of receiver nodes
// for end-to-end communication
#define sendnodes 1

enum {
  DELAY_BETWEEN_MESSAGES = 50,
	AM_MSG = 5,
	AM_ACK = 10,
};

typedef nx_struct MSG {
  nx_uint16_t ai;
  nx_uint16_t lbl;
  nx_uint16_t dat;
  nx_uint16_t nodeid;
} MSG;

typedef nx_struct ACK {
	nx_uint16_t ldai;
	nx_uint16_t lbl;
	nx_uint16_t nodeid;
} ACK;

#endif
