/******************************************************
 * File: rsmain.c
 * main function:
 * repeatedly asks for original string and string with
 * errors and tries to recover original string from
 * string with errors using Reed-Solomon decoding
 * Copyright (c) 1995 by Hugo Lyppens
 * With permission to print in Dr. Dobb's Journal
 ******************************************************/
#include "hdr.h"
#include <conio.h>
#include "rs.h"

main(argc, argv)
int    argc;
char  *argv[];
{
	char 		 str[N], str2[N];
	int			 r;

	RSG_ConstructGaloisField();
	RSG_CalcGeneratorPoly();

	for(;;) {
		printf("Enter original string or enter empty string to quit:\n");
		memset(str, 0, N); str2[0] = 0;
		gets(str);
		if(!str[0])	break;
		RSG_encode((UBYTE *)str);

		printf("Enter string with up to %d symbol errors or enter empty string to quit:\n", T);
		gets(str2);
		if(!str2[0]) break;

		strncpy(str, str2, K);
		r = RSG_decode((UBYTE *)str);
		if(r < 0) {
			printf("Decoding error -- too many errors!\n");
		} else {
			printf("Decoding OK, recovered '%s' from '%s' by correcting %d errors!\n", str, str2, r);
		}
	}
	return(0);
}

