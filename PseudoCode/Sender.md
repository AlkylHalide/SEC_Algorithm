# ALGORITHM 1: Sender p(s)

## Local variables

AltIndex   -->   {0, 1, 2}

ACK_set    -->   length = <capacity> + 1
           -->   each item is <ldai; lbl>

## Interfaces

**FETCH**
fetch(NumOfMessages) {

  return messages[NumOfMessages]

}

**ENCODE**
encode (M[]) {
  M = messages[];

  sizeof(M[i]) = ml;

  M'[] = encode(M[]);

  sizeof(M'[i]) = n;              --> n > ml, code can bare <capacity> mistakes
                                  --> Hier niet helemaal kosher: code can bare less than <capacity> mistakes
                                      if <capacity> is equal to the amount of messages sent.
                                      I declare here that the code can bare <parity> amount of mistakes
  return M'[];
}

## Main part

### Packet formation from messages

**Packet formation**
function packet_set() {

  for_each (i,j) in [(1, n) x (1, pl)]          --> (1, n) x (1, pl) =   1   2    3   .   .    .   pl       pl = length messages[] array
                                                                         2                                     = amount of messages fetched
    data[i].bit[j] = messages[j].bit[i];                                 3
                                                                         .                                  n  = length 1 encoded message (in bits)
                                                                         .
                                                                         .
                                                                         n  n,1  n,2  .   .   .   n,pl
  return {< AltIndex, i, data[i] >}             --> i = [1 ... n]
}

### Do forever loop
--> Set of atomic steps initiated by a Timer (periodically) going off, or Packet Reception event.

if (AltIndex x [1, <capacity> + 1]) in ACK_set {       --> AltIndex x [1, <capacity> + 1] =    AltIndex , 1
                                                                                               AltIndex , 2
    ++AltIndex;                                                                                AltIndex , 3
    AltIndex %= 3;                                                                                 ···
    memset(ACK_set, 0, sizeof(ACK_set));                                                       AltIndex , <capacity>     
    messages = encode(fetch(pl));                                                              AltIndex , <capacity> + 1
}                                                                                              

for each *packet* in packet_set() do send *packet*

### Reception of packet
When receive(ACK) --> ACK = < ldai;lbl >  (AM CHECK)

  if ( ldai == AltIndex && lbl == [1, <capacity + 1>] ) {

    ACK_set.add(ACK);

  }
