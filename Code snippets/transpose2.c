int a[10][10], b[10][10];

m = kk; // ROWS
n = mm; // COLUMNS

for(i=0; i<m; i++)
{
         for(j=0; j<n; j++)
         {
                  /*scanf("%d", &a[i][j]);*/

         }
}

for(i=0; i<m; i++)
{
         for(j=0; j<n; j++)
         {
                  printf("\t%d", a[i][j]);
         }
         printf("\n\n");
}

/* Transposing array */
for(i=0; i<m; i++)
{
         for(j=0; j<n; j++)
         {
                  b[j][i] = a[i][j];
         }
}

printf("\n\n2-D array after transposing:\n\n");
for(i=0; i<n; i++)
{
         for(j=0; j<m; j++)
         {
                  printf("\t%d", b[i][j]);
         }
         printf("\n\n");
}
