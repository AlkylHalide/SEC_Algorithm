// Evert Boelaert
// S²E²C algorithm

// Sender mote broadcasts packets <Ai, lbl, dat>
// Receiver receives packets and puts them into arrays packet_set[] according to NMote ID.
// Receiver then acknowledges packets by sending ACK <ldai, lbl> messages back to Sender.

// Ai = Alternating Index
// lbl = Label
// dat = data (message)
// ldai = Last Delivered Alternating Index

#ifndef SECRECEIVE_H
#define SECRECEIVE_H

 enum {
 	DELAY_BETWEEN_MESSAGES = 50,
 };

// Before it said 'nx_struct' instead of the normal 'struct'
// In the ReceiveP.nc file I declared the arrays as follows:
// struct SECMsg packet_set[21];
// But this gave an error at compiling, saying the type of packet_set
// did not match. Changing the nx_struct here to struct made it work.
// I'm wondering if the platfrom independence still works now I've removed
// the nx_prefix.
typedef nx_struct SECMsg {
	nx_uint16_t ai;
	nx_uint16_t lbl;
	nx_uint16_t dat;
	nx_uint16_t nodeid;
} SECMsg;

typedef nx_struct ACKMsg {
	nx_uint16_t ldai;
	nx_uint16_t lbl;
	nx_uint16_t nodeid;
} ACKMsg;

#endif
