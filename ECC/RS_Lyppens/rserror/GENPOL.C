/******************************************************
 * File: genpol.c
 * contains code to generate the generator polynomial
 * of degree 2*T for Reed-Solomon encoding/decoding
 * Copyright (c) 1995 by Hugo Lyppens
 * With permission to print in Dr. Dobb's Journal
 ******************************************************/
#include "hdr.h"
#include "rs.h"

UBYTE	            	 RSG_shiftregtab[FIELDSZ][2*T];
Polynomial			 	 RSG_genpol;


void	RSG_CalcGeneratorPoly()
{
	int		i, j;
	UBYTE	a, *p;

	RSG_genpol.degree = 2*T;
	memset(RSG_genpol.c, 0, 2*T);
	RSG_genpol.c[0] = RSG_powers[0];
	RSG_genpol.c[1] = 1;
	for(j = 1; j<2*T; j++) {
		a = RSG_powers[j];

		for(i = 2*T; i>=1; i--) {
			RSG_genpol.c[i] = RSG_genpol.c[i-1]^multiply(RSG_genpol.c[i], a);
		}
		RSG_genpol.c[0] = multiply(a, RSG_genpol.c[0]);
	}
	printf("Generator polynomial: ");
	printpoly(&RSG_genpol);

	for(i = 0; ; i++) {
		p = &RSG_multiply[i][0];
		for(j = 0; j<2*T; j++) {
			RSG_shiftregtab[i][j] =
				 p[RSG_genpol.c[j]];
		}
		if(i==MAXELT)
			break;
	 }
}


