#define GF_M	   	8
#define FIELDSZ 	(1<<GF_M)
#define MAXELT		(FIELDSZ-1)

#define N       	(FIELDSZ-1)
#define T       	8
#define K       	(N-2*T)

typedef unsigned char		UBYTE;

typedef struct {
	int		degree;
	UBYTE	c[2*T+1];
} Polynomial;

void divmod(Polynomial *poly,\
			Polynomial *divisor,\
			Polynomial *quot);
void mult(Polynomial *poly1,\
		  Polynomial *poly2,\
		  Polynomial *dest);
void printpoly(Polynomial *p);
void add(Polynomial *poly1,\
		 Polynomial *poly2,\
		 Polynomial *dest);


extern UBYTE 		        RSG_powers[FIELDSZ];
extern UBYTE 		        RSG_logarithm[FIELDSZ], RSG_multinv[FIELDSZ];
extern UBYTE	            RSG_multiply[FIELDSZ][FIELDSZ];
extern UBYTE	            RSG_shiftregtab[FIELDSZ][2*T];
extern Polynomial			RSG_genpol;

void 						RSG_encode(UBYTE *data);
int			 				RSG_decode(UBYTE *data);
void						RSG_CalcGeneratorPoly(void);
void	                  	RSG_ConstructGaloisField(void);

#define multiply(a,b)		RSG_multiply[a][b]



