// Evert Boelaert
// S²E²C algorithm

// Sender mote broadcasts packets <Ai, lbl, dat>
// Receiver receives packets and puts them into arrays packet_set[] according to NMote ID.
// Receiver then acknowledges packets by sending ACK <ldai, lbl> messages back to Sender.

// Ai = Alternating Index
// lbl = Label
// dat = data (message)
// ldai = Last Delivered Alternating Index

#ifndef SECSEND_H
#define SECSEND_H

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

typedef nx_struct dat {
	nx_uint16_t bit0 : 1;
	nx_uint16_t bit1 : 1;
	nx_uint16_t bit2 : 1;
	nx_uint16_t bit3 : 1;
	nx_uint16_t bit4 : 1;
	nx_uint16_t bit5 : 1;
	nx_uint16_t bit6 : 1;
	nx_uint16_t bit7 : 1;
	nx_uint16_t bit8 : 1;
	nx_uint16_t bit9 : 1;
	nx_uint16_t bit10 : 1;
	nx_uint16_t bit11 : 1;
	nx_uint16_t bit12 : 1;
	nx_uint16_t bit13 : 1;
	nx_uint16_t bit14 : 1;
	nx_uint16_t bit15 : 1;
} dat;

#endif
