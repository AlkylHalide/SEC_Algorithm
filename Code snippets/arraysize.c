#include <stdio.h>
#include <stdint.h>

#define NELEMS(x)  (sizeof(x) / sizeof((x)[0]))

int main() {

  int a[17];
  int n = NELEMS(a);

  uint16_t counter = 0;

  printf("%d\n", n);

  printf("%lu\n", sizeof(counter));

  return 0;
}
