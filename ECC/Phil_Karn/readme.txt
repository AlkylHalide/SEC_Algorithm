This package implements general purpose Reed-Solomon encoding and decoding for a
wide range of code parameters. It is a rewrite of code by Robert
Morelos-Zaragoza (robert at spectra.eng.hawaii.edu) and Hari Thirumoorthy (harit
at spectra.eng.hawaii.edu), which was in turn based on an earlier program by
Simon Rockliff (simon at augean.ua.oz.au). This package would not exist without
the excellent work of these earlier authors.
This package includes the following files:

readme - this file
rs.h - include in user programs. Code params are defined here.
rs.c - the initialization, encoder and decoder routines
rstest.c - test program
makefile - makefile for the test program and encoder/decoder

Any good coding theory textbook will describe the error-correcting properties of
Reed-Solomon codes in far more detail than can be included here. Here is a brief
summary of the properties of the standard (nonextended) Reed-Solomon codes
implemented in this package:

MM - the code symbol size in bits
KK - the number of data symbols per block, KK < NN
NN - the block size in symbols, which is always (2**MM - 1)

The integer parameters MM and KK are specified by the user. The code currently
supports values of MM ranging from 2 to 16, which is almost certainly a wider
range than is really useful.

Note that Reed-Solomon codes are non-binary. Each RS "symbol" is actually a
group of MM bits. Just one bit error anywhere in a given symbol spoils the whole
symbol. That's why RS codes are often called "burst-error-correcting" codes; if
you're going to have bit errors, you'd like to concentrate them into as few RS
symbols as possible.

In the literature you will often see RS code parameters given in the form
"(255,223) over GF(2**8)". The first number inside the parentheses is the block
length NN, and the second number is KK. The number inside the GF() gives the
size of each code symbol, written either in exponential form e.g., GF(2**8), or
as an integer that is a power of 2, e.g., GF(256). Both indicate an 8-bit
symbol.

Note that many RS codes in use are "shortened", i.e., the block size is smaller
than the symbol size would indicate. Examples include the (32,28) and (28,24) RS
codes over GF(256) in the Compact Disc and the (204,188) RS code used in digital
video broadcasting. This package does not directly support shortened codes, but
they can be implemented by simply padding the data array with zeros before
encoding, omitting them for transmission and then reinserting them locally
before decoding. A future version of this code will probably support a more
efficient implementation of shortened RS codes.

The error-correcting ability of a Reed-Solomon code depends on NN-KK, the number
of parity symbols in the block. In the pure error- correcting mode (no erasures
indicated by the calling function), the decoder can correct up to (NN-KK)/2
symbol errors per block and no more.

The decoder can correct more than (NN-KK)/2 errors if the calling program can
say where at least some of the errors are. These known error locations are
called "erasures". (Note that knowing where the errors are isn't enough by
itself to correct them because the code is non-binary -- we don't know *which*
bits in the symbol are in error.) If all the error locations are known in
advance, the decoder can correct as many as NN-KK errors, the number of parity
symbols in the code block. (Note that when this many erasures is specified,
there is no redundancy left to detect additional uncorrectable errors so the
decoder may yield uncorrected errors.)

In the most general case there are both errors and erasures. Each error counts
as two erasures, i.e., the number of erasures plus twice the number of
non-erased errors cannot exceed NN-KK. For example, a (255,223) RS code
operating on 8-bit symbols can handle up to 16 errors OR 32 erasures OR various
combinations such as 8 errors and 16 erasures.

The three user-callable functions in rs.c are as follows:

void init_rs(void);

Initializes the internal tables used by the encoder and decoder using the code
parameters compiled in from rs.h. This function *must* be called before the
encoder or decoder are used for the first time.

int encode_rs(dtype data[KK],dtype bb[NN-KK]);

Encodes a block in the Reed-Solomon code. The first argument contains the KK
symbols of user data to be encoded, and the second argument contains the array
into which the encoder will place the NN-KK parity symbols. The data argument is
unchanged. For user convenience, the data and bb arrays may be part of a single
contiguous array of NN elements, e.g., for a (255,223) code:

encode_rs(&data[0],&data[223]);

The encode_rs() function returns 0 on success, -1 on error. (The only possible
error is an illegal (i.e., too large) symbol in the user data array.

Note that the typedef for the "dtype" type depends on the value of MM specified
in rs.h. For MM <= 8, dtype is equivalent to "unsigned char"; for larger values,
dtype is equivalent to "unsigned int".

int eras_dec_rs(dtype data[NN], int eras_pos[NN-KK], int no_eras);

Decodes a encoded block with errors and/or erasures. The first argument contains
the NN symbols of the received codeword, the first KK of which are the user data
and the latter NN-KK are the parity symbols.

Caller-specified erasures, if any, are passed in the second argument as an array
of integers with the third argument giving the number of entries. E.g., to
specify that symbols 10 and 20 (counting from 0) are to be treated as erasures
the caller would say

	eras_pos[0] = 10;
	eras_pos[1] = 20;
	eras_dec_rs(data,eras_pos,2);

The return value from eras_dec_rs() will give the number of errors (including
erasures) corrected by the decoder. If the codeword could not be corrected due
to excessive errors, -1 will be returned. The decoder will also return -1 if the
data array contains an illegal symbol, i.e., one exceeding the defined symbol
size.
