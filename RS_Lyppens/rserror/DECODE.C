/******************************************************
 * File: decode.c
 * contains RSG_decode C function that decodes received
 * words.
 * Copyright (c) 1995 by Hugo Lyppens
 * With permission to print in Dr. Dobb's Journal
 ******************************************************/
#include "hdr.h"
#include "rs.h"

#define PRINTON

int calc_syndrome(UBYTE *data, UBYTE *syndrome);
int find_roots(UBYTE *errlocpol, int elpdegree, UBYTE *roots);

/*
** Decode word pointed to by data
*/
int RSG_decode(data)
UBYTE   *data;
{
	UBYTE  		 syndrome[2*T];
	UBYTE  		 beta[T], beta_val;

	int     	 i, j, elpdegree;
	int     	 numroots;
	UBYTE     	 a, c, loc, magn;
	Polynomial 	 poly1, poly2, v1, v2;
	Polynomial 	 quot, prod;
	Polynomial 	*prev_s, *curr_s, *prev_v, *curr_v, *t;
	Polynomial 	*omega, *sigma;

	if(!calc_syndrome(data, syndrome)) {
		/* no error occurred */
		return(0);
	}
#ifdef PRINTON
	for(j = 0; j<2*T; j++) {
		printf("Syndrome %d: %2x\n", j, syndrome[j]);
	}
#endif
	memset(poly1.c, 0, 2*T); poly1.c[2*T] = 1; poly1.degree = 2*T;
	memcpy(poly2.c, syndrome, 2*T);
	i = 2*T-1;
	while(i>=0 && !poly2.c[i])
		i--;
	poly2.degree = i;
	if(i<0)
		return(0);
	v1.degree = -1;

	v2.c[0]   = 1;
	v2.degree = 0;

	prev_s = &poly1; curr_s = &poly2;
	prev_v = &v1;    curr_v = &v2;

	while(curr_s->degree>=T) {
		divmod(prev_s,
			   curr_s,
			   &quot);
		mult(curr_v, &quot, &prod);
		add(&prod, prev_v, prev_v);
		t = curr_v; curr_v = prev_v; prev_v = t;
		t = curr_s; curr_s = prev_s; prev_s = t;
	}
	sigma = curr_v; /* error locator */
	omega = curr_s; /* error evaluator */
	elpdegree = sigma->degree;
	if(elpdegree<1 || elpdegree>T)
		return(-1);
#ifdef PRINTON
	printf("\nDegree of err. loc. polynomial: %d\n", elpdegree);
	printf("Error locator polynomial: "); printpoly(sigma);
	printf("Error evaluator polynomial: "); printpoly(omega);
#endif
	if(elpdegree == 1) { // shortcut for 1 error
		loc  = RSG_logarithm[multiply(sigma->c[1],RSG_multinv[sigma->c[0]])];
		magn = syndrome[0];
#ifdef PRINTON
		printf("correcting error at location %d of magnitude %02X\n", loc, magn);
#endif
		data[loc] ^= magn;
	} else {
		numroots = find_roots(sigma->c, sigma->degree, beta);
#ifdef PRINTON
		printf("number of roots of elp: %d\n", numroots);
#endif
		if(numroots!=elpdegree)
			return(-1);
		for(i = 0; i<numroots; i++) {
			c = beta_val = beta[i];
			a = omega->c[omega->degree];
			for(j = omega->degree-1; j>=0; j--) {
				a = multiply(a, beta_val) ^ omega->c[j];
			}
			a = multiply(a, RSG_multinv[sigma->c[numroots]]);

			for(j = 0; j<numroots; j++) {
				if(i!=j)
					c = multiply(c, beta[j]^beta_val);
			}
			loc  = RSG_logarithm[RSG_multinv[beta_val]];
			magn = multiply(a, RSG_multinv[c]);
#ifdef PRINTON
			printf("correcting error at location %d of magnitude %02X\n", loc, magn);
#endif
			data[loc] ^= magn;
		}
	}
	return(elpdegree);
}

/* divide poly by divisor. Write quotient to quot and keep
** remainder in poly
*/
void divmod(Polynomial *poly,
			Polynomial *divisor,
			Polynomial *quot)
{
	int    divdegree= divisor->degree;
	int    degree   = poly->degree;
	UBYTE  x;
	int	   j, k;

	if(divdegree<0)
		return;
	x = RSG_multinv[divisor->c[divdegree]];
	j = degree-divdegree;
	quot->degree = j>0?j:0;
	for(; j>=0; j--) {
		UBYTE factor = multiply(x, poly->c[j+divdegree]);
		for(k = 0; k<=divdegree; k++) {
			poly->c[j+k] ^= multiply(factor, divisor->c[k]);
		}
		quot->c[j] = factor;
	}
	while(divdegree>=0 && !poly->c[divdegree]) {
		divdegree--;
	}
	poly->degree = divdegree;
}

/* multiply poly1 by poly2 and write result in dest
*/
void mult(Polynomial *poly1,
		  Polynomial *poly2,
		  Polynomial *dest)
{
	int 	d1, d2;
	UBYTE   f;

	dest->degree = poly1->degree + poly2->degree;
	memset(dest->c, 0, dest->degree+1);
	for(d1 = 0; d1<=poly1->degree; d1++) {
		f = poly1->c[d1];
		for(d2 = 0; d2<=poly2->degree; d2++) {
			dest->c[d1+d2] ^= multiply(f, poly2->c[d2]);
		}
	}
}

/* print polynomial. Output is of the form:
 * 4 + 2x^1 + 13x^2
 */
void printpoly(Polynomial *p)
{
	int i;
	printf("%02X ", p->c[0]);
	for(i = 1; i<=p->degree; i++)
		printf(" + %02Xx^%d", p->c[i], i);
	printf("\n");
}


/* add polynomial 1 to poly 2 and write result in dest
*/
void add(Polynomial *poly1,
		 Polynomial *poly2,
		 Polynomial *dest)
{
	int	i;

	if(poly1->degree>poly2->degree) {
		Polynomial *t = poly1;
		poly1 = poly2; poly2 = t;
	}
	for(i = 0; i<=poly1->degree; i++) {
		dest->c[i] = poly1->c[i]^poly2->c[i];
	}
	while(i<=poly2->degree) {
		dest->c[i] = poly2->c[i];
		i++;
	}
	i--;
	while(i>=0 && !dest->c[i])
		i--;
	dest->degree = i;
}

