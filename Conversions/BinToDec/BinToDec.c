#include <stdio.h>
int main(void) 
{ 
char bin; int dec = 0;

while (bin != '\n') { 
scanf("%c",&bin); 
if (bin == '1') dec = dec * 2 + 1; 
else if (bin == '0') dec *= 2; } 

printf("%d\n", dec); 

return 0;

}
