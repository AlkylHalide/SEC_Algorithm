#include <stdio.h>
#include <stdint.h>

uint16_t main() {
  uint16_t counter = 0;
  uint16_t x = 0;
  static uint8_t rijen = 16;
  static uint8_t kolommen = 16;
  uint8_t i = 0;
  uint8_t j = 0;
  uint16_t result[rijen][kolommen];
  uint16_t transpose[kolommen][rijen];
  uint16_t packet_set[kolommen];

  // while(1)
  // {
    // Initalize 2D arrays with zeroes
    // This makes sure all array contents are valid
    for (i = 0; i < rijen; ++i)
    {
      packet_set[i] = 0;
    	for (j = 0; j < kolommen; ++j)
    	{
    		result[i][j] = 0;
        transpose[j][i] = 0;
    	}
    }

    // *************************************//
    //          SENDER: PACKET_SET
    // *************************************//

    // Transfer 'rijen' amount of counter values to bits
    // The bits are stored in the 2D array 'result'
    printf("Original bit array:\n");
    for (i = 0; i < rijen; ++i)
    {
      x = counter;
    	for (j = 0; j < kolommen; ++j)
    	{
    		result[i][j] = (x & 0x8000) >> 15;
    		printf("%d", result[i][j]);
    		x <<= 1;
    	}
    	printf("\n");
    	++counter;
    }
    printf("\n");

    // Transpose the 'result' array and put the result in 'transpose'
    printf("Transposed array:\n");
    for (i = 0; i < kolommen; ++i)
    {
      for (j = 0; j < rijen; ++j)
      {
        transpose[i][j] = result[j][i];
        printf("%d", transpose[i][j]);
      }
      printf("\n");
    }
    printf("\n");

    // Convert the transposed bit array into a decimal value array
    printf("Decimal array: \n");
    x = 1;
    for (i = 0; i < kolommen; ++i)
    {
      for (j = 0; j < rijen; ++j)
      {
        if (transpose[i][j] == 1) packet_set[i] = packet_set[i] * 2 + 1;
        else if (transpose[i][j] == 0) packet_set[i] *= 2;
      }
      printf("%d\n", packet_set[i]);
    }
    printf("\n");

    // *************************************//
    //      RECEIVER: REVERSE PACKET_SET
    // *************************************//

    // Using the same int to bit array conversion as above,
    // the received 1D int array of decimals is converted to
    // a 2D bit array
    printf("Received bit array:\n");
    for (i = 0; i < kolommen; ++i)
    {
      x = packet_set[i];
      for (j = 0; j < rijen; ++j)
      {
        transpose[i][j] = (x & 0x8000) >> 15;
        printf("%d", transpose[i][j]);
        x <<= 1;
      }
      printf("\n");
    }
    printf("\n");

    // Transpose the 'transpose' array and put the result in 'result'
    printf("Transposed array:\n");
    for (i = 0; i < rijen; ++i)
    {
      for (j = 0; j < kolommen; ++j)
      {
        result[i][j] = transpose[j][i];
        printf("%d", result[i][j]);
      }
      printf("\n");
    }
    printf("\n");

    // Convert the transposed bit array into a decimal value array
    printf("Received decimal array: \n");
    x = 1;
    for (i = 0; i < rijen; ++i)
    {
      for (j = 0; j < kolommen; ++j)
      {
        if (result[i][j] == 1) packet_set[i] = packet_set[i] * 2 + 1;
        else if (result[i][j] == 0) packet_set[i] *= 2;
      }
      printf("%d\n", packet_set[i]);
    }
  // }
	return 0;
}