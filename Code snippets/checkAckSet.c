#include <stdio.h>

#define capacity 47

int ACK_LDAI[capacity+1];
int ACK_LBL[capacity+1];

int i, j;

int main () {
  int i = 0;
  int AltIndex = 0;

  for (i = 0; i < (capacity+1); i++) {
    ACK_LDAI[i] = AltIndex;
    ACK_LBL[i] = (i+1);
  }

  // Corrupt data in arrays
  // comment these out if you want the checkAckSet() to succeed
  // ACK_LBL[47] = 9;
  // ACK_LDAI[47] = 2;

  if (checkAckSet(AltIndex) == 1) {
    printf("GREAT SUCCESS\n");
  } else {
    printf("FAIL SO HARD MOTHERFUCKERS WANNA FIND ME\n");
  }

  return 0;
}


// Boolean return function to check if ACK_set is complete
int checkAckSet(AltIndex) {
  // go through ACK_set, size <capacity> + 1
  for (i = 0; i < (capacity+1); i++) {
    // The fullfillment requirement is that ACK_set contains
    // <capacity> + 1 ACK messages from the receiver,
    // each with ldai = AltIndex and every value of the labels
    // represented
    if( (ACK_LDAI[i] == AltIndex) && (ACK_LBL[i] == (i+1)) ) {
    } else {
      return 0;
    }
  }
  return 1;
}
