#define n 8     // COLUMNS
#define m 16    // ROWS

int data[m];
int result[n];
int i,j;
int counter = 0;

memset(data, 0, sizeof(data));
memset(result, 0, sizeof(result));

for ( i = 0; i < m; ++i) {
  data[i] = counter;
  ++counter;
}

int a[m][n], b[n][m], x;

// Convert decimal array to 2D bit array
for(i=0; i<m; i++)
{
 x = data[i];
        for(j=0; j<n; j++)
        {
                 a[i][j] = (x & 0x8000) >> 8;
                 x <<= 1;
        }
}

// Transpose bit array
for(i=0; i<m; i++)
{
         for(j=0; j<n; j++)
         {
                  b[j][i] = a[i][j];
         }
}

// Convert back to decimal
for(i=0; i<n; i++)
{
         for(j=0; j<m; j++)
         {
                  if (b[i][j] == 1) result[i] = result[i] * 2 + 1;
                  else if (b[i][j] == 0) result[i] *= 2;
         }
}
