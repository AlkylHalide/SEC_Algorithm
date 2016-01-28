// Evert Boelaert
// S²E²C algorithm

// Sender mote broadcasts packets <Ai, lbl, dat>
// Receiver receives packets and puts them into arrays packet_set[] according to NMote ID.
// Receiver then acknowledges packets by sending ACK <ldai, lbl> messages back to Sender.

// Ai = Alternating Index
// lbl = Label
// dat = data (message)
// ldai = Last Delivered Alternating Index

// define amount of sending nodes in the network
// there should be an equal amount of receiver nodes
// for end-to-end communication
#define sendnodes 10

enum {
  DELAY_BETWEEN_MESSAGES = 50,
	AM_SECMSG = 5,
	AM_ACKMSG = 10,
};

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
