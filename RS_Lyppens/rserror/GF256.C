/******************************************************
 * File: gf256.c
 * contains code to construct GF(2^8) and all required
 * arrays for GF(2^8) arithmetic.
 * Copyright (c) 1995 by Hugo Lyppens
 * With permission to print in Dr. Dobb's Journal
 ******************************************************/
#include "hdr.h"
#include "rs.h"

#define POL 			 0x171    /* primitive polynomial used to construct
									 GF(2^8) is: x8 + x6 + x5 + x4 + 1
									 represented as 101110001 binary
								  */

UBYTE 		         	 RSG_powers[FIELDSZ];
UBYTE 		         	 RSG_logarithm[FIELDSZ];
UBYTE					 RSG_multinv[FIELDSZ];
UBYTE	            	 RSG_multiply[FIELDSZ][FIELDSZ];

static UBYTE 	         multiply_func(UBYTE, UBYTE);
static UBYTE 	         multinv_func(UBYTE);

void		RSG_ConstructGaloisField()
{
	 int		  v;
	 UBYTE		  i, j;

	 v = 1;
	 for(i = 0; ; i++) {
		  RSG_powers[i] 		= (UBYTE)v;
		  RSG_logarithm[v] 	= i;
		  v <<=1; // multiply v by alpha and reduce modulo POL
		  if(v & (1<<GF_M)) {
				v ^= POL;
		  }
		  if(i==MAXELT-1)
				break;
	 }
	 RSG_powers[MAXELT] = 1;

	 // construct multiplication table
	 for(i = 0; ; i++ ) {
		  if(i) RSG_multinv[i] = multinv_func(i);
		  for(j = i; ; j++) {
			  RSG_multiply[i][j] = RSG_multiply[j][i] = multiply_func(i, j);
			  if(j==MAXELT)
					break;
		  }
		  if(i==MAXELT)
				break;
	 }
}


// compute multiplicative inverse of x
// This is the value y for which x*y = 1
static UBYTE multinv_func(x)
UBYTE x;
{
	if(!x)
		return 0;
	return RSG_powers[FIELDSZ-1-RSG_logarithm[x]];
}


// compute product of i and j
static UBYTE multiply_func(i, j)
UBYTE i, j;
{
	 int r, b, k;

	 r = 0; k = j;
	 for(b = 1; b<FIELDSZ; b<<=1, k<<=1) {
		if(k & (1<<GF_M)) k^=POL;
		 if(i & b)       r ^= k;
	 }
	 return((UBYTE)r);
}

