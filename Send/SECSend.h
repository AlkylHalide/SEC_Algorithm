#ifndef SECSEND_H
#define SECSEND_H

 enum {  
   DELAY_BETWEEN_MESSAGES = 50,
 };

typedef nx_struct SECMsg {
  nx_uint16_t ai;
  nx_uint16_t lbl;
  //nx_uint16_t dat;
} SECMsg;

#endif
