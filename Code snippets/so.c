#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define n 8     // COLUMNS
#define m 223    // ROWS

int main(void)
{
    uint data[m];
    uint result[n];
    int i, j;
    int counter = 0;

    // memset(data, 0, sizeof(data));
    // memset(result, 0, sizeof(result));

    for (i = 0; i < m; ++i)   // print initial data
    {
        data[i] = counter;
        printf("%d ", data[i]);
        ++counter;
    }
    putchar('\n');

    char a[m][n], b[n][m];
    int x;

    // Convert decimal array to 2D bit array
    for (i = 0; i < m; i++)
    {
        x = data[i];
        for (j = n - 1; j >= 0; j--)
        {
            a[i][j] = x & 1;
            x >>= 1;
            printf("%d", a[i][j]);
        }
        printf("\n");
    }

    printf("\n");
    // Transpose bit array
    for (i = 0; i < m; i++)
    {
        for (j = 0; j < n; j++)
        {
            b[j][i] = a[i][j];
        }
    }

    for (i = 0; i < n; i++) {
      for (i = 0; i < m; i++) {
        printf("%d\n", b[i][j]);
      }
      printf("\n");
    }

    // Convert back to decimal
    for (i = 0; i < n; i++)
    {
        for (j = 0; j < m; j++)
        {
            if (b[i][j] == 1)
                result[i] = result[i] * 2 + 1;
            else if (b[i][j] == 0)
                result[i] *= 2;
        }
    }

    for (i = 0; i < n; ++i)      // print result
    {
        printf("%d ", result[i]);
    }
    putchar('\n');

    // RECEIVER

    // Convert decimal array to 2D bit array
    for (i = 0; i < n; i++)
    {
        x = result[i];
        for (j = m - 1; j >= 0; j--)
        {
            a[i][j] = x & 1;
            x >>= 1;
            printf("%d", a[i][j]);
        }
        printf("\n");
    }

    printf("\n");
    // Transpose bit array
    for (i = 0; i < m; i++)
    {
        for (j = 0; j < n; j++)
        {
            b[j][i] = a[i][j];
            printf("%d", b[j][i]);
        }
        printf("\n");
    }

    // Convert back to decimal
    for (i = 0; i < n; i++)
    {
        for (j = 0; j < m; j++)
        {
            if (b[i][j] == 1)
                result[i] = result[i] * 2 + 1;
            else if (b[i][j] == 0)
                result[i] *= 2;
        }
    }

    for (i = 0; i < n; ++i)      // print result
    {
        printf("%d ", result[i]);
    }
    putchar('\n');

    return 0;
}
