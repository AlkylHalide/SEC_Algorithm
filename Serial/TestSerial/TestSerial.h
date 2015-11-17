
#ifndef SERIAL_H
#define SERIAL_H

typedef nx_struct serial_msg {
  nx_uint16_t counter;
} serial_msg_t;

enum {
  AM_SERIAL_MSG = 0x89,
};

#endif
