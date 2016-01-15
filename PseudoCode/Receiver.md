# Algorithm 2: Receiver p(r)

## Local variables

LastDeliveredIndex        -->   {0, 1, 2}

packet_set                -->   < ai ; lbl ; dat >    -->   lbl = [1, n]
                                                      -->   sizeof(dat) = pl

## Interfaces

**DECODE**
decode (M'[]) {
  M' = messages[];

  sizeof(M'[i]) = n;

  M[] = decode(M'[]);

  sizeof(M[i]) = ml;              --> n > ml, code can bare <capacity> mistakes

  return M[];
}

**DELIVER**
deliver (messages[]) {

  print to application layer in array order

}

## Macros

index(ind) = { < ind, \*, \* > in packet_set }     --> returns all elements of packet_set that have "ind" as Ai value
                                                   --> elements in packet_set are < Ai ; lbl ; dat >
## Main part

### Do forever loop

if [ (

    | (1) packet_set contains packets with:    ai  ==> [0, 2] without LastDeliveredIndex      (==> : element of)    |
    |                                          lbl between [1, n]                                                   |
    |                                          data of size pl                                                      |
    |                                                                                                               |
    |  (2) packet_set holds at most ONE group of ai that has n packets (distinctly labeled)                         |

  ) == FALSE ]

  memset(packet_set, 0, sizeof(packet_set));      --> reset packet_set

if (  n distinct labeled packets with identical 'ai' ==> packet_set ) {

    for_each (i,j) in [(1, n) x (1, pl)]          --> (1, pl) x (1, n) =   1   2    3   .   .    .   n       pl = length messages[] array
                                                                         2                                      = amount of messages fetched
       messages[i].bit[j] = data[j].bit[i];                              3
                                                                         .                                   n  = length 1 encoded message (in bits)
                                                                         .
                                                                         .
                                                                         pl  pl,1  pl,2  .   .   .   pl,n

    memset(packet_set, 0, sizeof(packet_set));
    LastDeliveredIndex = ai;
    deliver(decode(messages));

}

for each i ==> [ 1,<capacity> + 1 ]       (==> : element of)

    send < LastDeliveredIndex, i >

### Receive event
When receive(pckt) --> pckt = < ai;lbl;dat >  (AM CHECK)

if (  < ai;lbl;\* > not an element of packet_set
      &&
      < ai;lbl > ==> ( [ 0,2 ] \ LastDeliveredIndex x [ 1,n ] )
      &&
      sizeof(dat) == pl ) {

    packet_set.add(pckt);

}
