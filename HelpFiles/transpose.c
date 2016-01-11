/* C program to transpose the 2D array */

#include <stdio.h>
#include <termios.h>
#include <stdio.h>
#include <string.h> /* memset */

static struct termios old, new;

/* Initialize new terminal i/o settings */
void initTermios(int echo)
{
  tcgetattr(0, &old); /* grab old terminal i/o settings */
  new = old; /* make new settings same as old settings */
  new.c_lflag &= ~ICANON; /* disable buffered i/o */
  new.c_lflag &= echo ? ECHO : ~ECHO; /* set echo mode */
  tcsetattr(0, TCSANOW, &new); /* use these new terminal i/o settings now */
}

/* Restore old terminal i/o settings */
void resetTermios(void)
{
  tcsetattr(0, TCSANOW, &old);
}

/* Read 1 character - echo defines echo mode */
char getch_(int echo)
{
  char ch;
  initTermios(echo);
  ch = getchar();
  resetTermios();
  return ch;
}

/* Read 1 character without echo */
char getch(void)
{
  return getch_(0);
}

/* Read 1 character with echo */
char getche(void)
{
  return getch_(1);
}

void main()
{
    #define CAPACITY 16
    #define mm 8
    #define kk 223

    int data[kk];
    int result[mm];
    int i,j;
    int counter = 0;

    memset(data, 0, sizeof(data));
    memset(result, 0, sizeof(result));

    for ( i = 0; i < CAPACITY; ++i) {
      /*messages[i] = counter;*/
      data[i] = counter;
      // Increment the counter (for pl amount of messages)
      ++counter;
    }

    //  Show resulting decimal array
    for (i = 0; i < kk; i++) {
      printf("%d\n", data[i]);
    }

    //  int a[10][10], b[10][10], m, n, x;
    //
    // //  printf("\nEnter number of rows & columns of aray : ");
    // //  scanf("%d %d", &m, &n);
    //
    // m = kk; // ROWS
    // n = mm; // COLUMNS
    //
    // //  printf("\nEnter elements of 2-D array:\n");
    //  for(i=0; i<m; i++)
    //  {
    //    x = data[i];
    //           for(j=0; j<n; j++)
    //           {
    //                    a[i][j] = (x & 0x8000) >> 15;
    //                    x <<= 1;
    //           }
    //  }
    //
    //  printf("\n\n2-D array before transposing:\n\n");
    //  for(i=0; i<m; i++)
    //  {
    //           for(j=0; j<n; j++)
    //           {
    //                    printf("\t%d", a[i][j]);
    //           }
    //           printf("\n\n");
    //  }
    //
    //  /* Transposing array */
    //  for(i=0; i<m; i++)
    //  {
    //           for(j=0; j<n; j++)
    //           {
    //                    b[j][i] = a[i][j];
    //           }
    //  }
    //
    //  printf("\n\n2-D array after transposing:\n\n");
    //  for(i=0; i<n; i++)
    //  {
    //           for(j=0; j<m; j++)
    //           {
    //                    printf("\t%d", b[i][j]);
    //                    if (b[i][j] == 1) result[i] = result[i] * 2 + 1;
    //                    else if (b[i][j] == 0) result[i] *= 2;
    //           }
    //           printf("\n\n");
    //  }
    //
    // //  Show resulting decimal array
    // for (i = 0; i < mm; i++) {
    //   printf("%d\n", result[i]);
    // }

     getch();
}
