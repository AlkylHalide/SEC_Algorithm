#include <stdio.h>
#include <stdint.h>

#define capacity 9

int main()
{
	static uint16_t messages[(capacity + 1)];
	uint16_t counter = 0;
	uint8_t pl = capacity + 1;
	int i = 0;

	for (i = 0; i < pl; ++i) {
      messages[i] = counter;
      // Increment the counter (for pl amount of messages sent instead of copies of the same message)
      ++counter;
      printf("%d\n", messages[i]);
    }

	return 0;
}