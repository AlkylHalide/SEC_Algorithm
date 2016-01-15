// ***** ALTERING PACKET ***** //
uint8_t n = 0;
uint8_t m = 0;
uint8_t o = 0;
// *************************** //

// ***** ITERATION TRACKER ***** //
printf("%u  ", n);
// *************************** //

// ***** DUPLICATING PACKETS ***** //
if((n)%6 == 0 && n < 50) {
  m = rand();
  m %= CAPACITY;
  o = inMsg->lbl + m;
  if(o < CAPACITY) {
    inMsg->lbl = o;
  }
}
printf("%u  \n", o);
// *************************** //*/

// ***** INSERTING PACKETS ***** //
if((n)%4 != 0 && n < 50 && (inMsg->lbl < CAPACITY)) {
  m = rand();
  m %= (CAPACITY-(inMsg->lbl));
  m += inMsg->lbl;
  inMsg->lbl = m;
}
printf("%u\n", m);
// *************************** //

// ***** REORDERING PACKETS ***** //
if((n)%4 == 0 && n < 50) {
  m = rand();
  m %= CAPACITY;
  if(m == 0) { m = 1;}
  inMsg->lbl = m;
}
printf("%u\n", m);
printfflush();
n++;
// *************************** //
