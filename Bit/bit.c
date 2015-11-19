#include <stdio.h>
#include <stdint.h>

int main() {
  uint16_t counter = 0;
  uint16_t x = 0;
  static int rijen = 16;
  static int kolommen = 16;
  int i = 0;
  int j = 0;
  int result[rijen][kolommen];
  int transpose[rijen][kolommen];
  int packet_set[rijen];

  // Initalize 2D arrays with zeroes
  // This makes sure all array contents are valid
  for (i = 0; i < rijen; ++i)
  {
    packet_set[i] = 0;
  	for (j = 0; j < kolommen; ++j)
  	{
  		result[i][j] = 0;
      transpose[i][j] = 0;
  	}
  }

  // Transfer 'rijen' amount of counter values to bits
  // The bits are stored in the 2D array 'result'
  printf("Original bit array:\n");
  for (i = 0; i < rijen; ++i)
  {
    x = counter;
  	for (j = 0; j < kolommen; ++j)
  	{
  		result[i][j] = (x & 0x8000) >> 15;
  		// printf("%d", (x & 0x8000) >> 15);
  		printf("%d", result[i][j]);
  		x <<= 1;
  	}
  	printf("\n");
  	++counter;
  }
  printf("\n");

  // Transpose the 'result' array and put the result in 'transpose'
  printf("Transposed array:\n");
  for (i = 0; i < rijen; ++i)
  {
    for (j = 0; j < kolommen; ++j)
    {
      transpose[i][j] = result[j][i];
      printf("%d", transpose[i][j]);
    }
    printf("\n");
  }
  printf("\n");

  // Convert the transposed bit array into a decimal value array
  printf("Decimale array: \n");
  x = 1;
  for (i = 0; i < rijen; ++i)
  {
    packet_set[i] = transpose[i][0];
    for (j = 1; j < kolommen; ++j)
    {
      if (transpose[i][j] == 1) packet_set[i] = packet_set[i] * 2 + 1;
      else if (transpose[i][j] == 0) packet_set[i] *= 2;
      // while (x <= transpose[i][j]) {
      //   packet_set[i] *= 10;
      //   x *= 10;
      // }
      // packet_set[i] += transpose[i][j];
    }
    printf("%d\n", packet_set[i]);
  }

	return 0;
}