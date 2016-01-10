; File: codecsup.asm
; contains the following 32 bit assembly language
; routines for Reed-Solomom encoding and decoding:
;     RSG_encode, find_roots, calc_syndrome
; Copyright (c) 1995 by Hugo Lyppens
; With permission to print in Dr. Dobb's Journal
			.386p

Prefix      macro
			push    ebp
			mov     ebp,esp
			push    edi
			push    esi
			push    ebx
			push    ecx
			push    edx
			endm

Postfix     macro
			pop     edx
			pop     ecx
			pop     ebx
			pop     esi
			pop     edi
			pop     ebp
			endm

FIELDSZ		equ 256
N	        equ	(FIELDSZ-1)
T	        equ	8
K	        equ	(N-2*T)


			SMART
_DATA       segment DWORD PUBLIC use32 'DATA'
			extrn   _RSG_powers:Byte
			extrn   _RSG_logarithm:Byte
			extrn   _RSG_multinv:Byte
			extrn   _RSG_multiply:Byte
			extrn   _RSG_shiftregtab:Byte

;decoding variables:
m	   		db	    2*T dup (0)
_DATA       ends



_TEXT       segment BYTE PUBLIC use32 'CODE'
			assume	cs:_TEXT,ds:_DATA

			public	_RSG_encode
			public	_find_roots
			public	_calc_syndrome

ae_data	    equ		4+4*6
_RSG_encode	PROC
			Prefix
			mov	    ax,ds
			mov	    es,ax

			mov		esi,[esp+ae_data]
			mov		edi,esi
			add		esi,K

			xor		eax,eax
			xor		ebp,ebp
			xor		ecx,ecx
			xor		edx,edx

encode_loop:dec		esi
			xor		ebx,ebx
			shld	ebx,edx,8
			xor		bl,[esi]			;get next symbol from a(x)
			shl		ebx,4				;multiply by 2*T
			add     ebx,OFFSET _RSG_shiftregtab

			shld    edx,ecx,8           ;shift left by 1 symbol
			shld    ecx,ebp,8
			shld    ebp,eax,8
			shl		eax,8

			xor		eax,[ebx]           ;add bl*g(x)
			xor		ebp,[ebx+4]
			xor		ecx,[ebx+8]
			xor		edx,[ebx+12]

			cmp		edi,esi
			jnz		encode_loop

			mov		[edi+K],eax			;write b(x) to array at
			mov		[edi+K+4],ebp		;position K
			mov		[edi+K+8],ecx
			mov		[edi+K+12],edx

			Postfix
			ret
_RSG_encode	ENDP



cs_data	    equ		4+4*6
cs_syndrome	equ		8+4*6
_calc_syndrome	PROC
			Prefix
			mov	    ax,ds
			mov	    es,ax

			mov		esi,[esp+ae_data]
			mov		edi,esi
			add		esi,K

			mov		edx,[esi+12]
			mov		ecx,[esi+8]
			mov		ebp,[esi+4]
			mov		eax,[esi]

decode_loop:dec		esi
			xor		ebx,ebx
			shld	ebx,edx,8
			shl		ebx,4
			add     ebx,OFFSET _RSG_shiftregtab

			shld    edx,ecx,8
			shld    ecx,ebp,8
			shld    ebp,eax,8
			shl		eax,8
			mov		al,[esi]

			xor		eax,[ebx]
			xor		ebp,[ebx+4]
			xor		ecx,[ebx+8]
			xor		edx,[ebx+12]

			cmp		edi,esi
			jnz		decode_loop
; now, edx,ecx,ebp,eax contains r(x) mod g(x)
			mov		ebx,eax
			or		ebx,ebp
			or		ebx,ecx
			or		ebx,edx
; test if r(x) mod g(x) is nonzero
			jnz		start_syndrome	; errors occurred, compute syndrome
							; from m(x) = r(x) mod g(x)
			Postfix
			mov		eax,0
			ret

start_syndrome:				; compute m(1), m(alpha) ... m(alpha^(2*T-1))
			lea     esi,m
			mov		[esi],eax
			mov		[esi+4],ebp
			mov		[esi+8],ecx
			mov		[esi+12],edx
			mov     edi,OFFSET _RSG_multiply

			xor     eax,ebp
			xor     eax,ecx
			xor     eax,edx

			mov     bx,ax
			shr     eax,16
			xor     bx,ax
			xor     bl,bh

			mov		ebp,[esp+cs_syndrome]
			mov     [ebp],bl

			mov     cl,8
			mov     edx,1
			xor     ebx,ebx
next:
			mov     bh,_RSG_powers[edx]		;alpha ^ edx

			mov     bl,[esi+2*T-1]

			x=2
			rept	15
				mov     bl,[edi+ebx]
				xor     bl,[esi+2*T-x]
				x = x + 1
			endm
;-----
			mov     [ebp+edx],bl
			inc     edx
			cmp     edx,T*2
			jnz     next

			Postfix
			mov		eax,1
			ret
_calc_syndrome    ENDP



fr_errlocpol    equ	4+4*6
fr_elpdegree    equ	8+4*6
fr_roots	    equ	12+4*6
; loop from 1 through 255 and
; substitute in errlocpol to find
; all its zeros (roots). Write roots
; to area pointed to by fr_roots
_find_roots	PROC
			Prefix
			mov	    ax,ds
			mov	    es,ax

			mov     ebp,OFFSET _RSG_multiply
			xor     edx,edx
			mov     dl,[esp+fr_elpdegree]
			mov     edi,[esp+fr_roots]
			mov     ebx,1

nextnumber: movzx   ecx,dl
			mov     esi,[esp+fr_errlocpol]
			add		esi,ecx
			mov     bh,[esi]

evalpoly:   mov     bh,[ebp+ebx]
			dec		esi
			xor     bh,[esi]
			loop    evalpoly
			cmp     bh,0
			jz      SHORT foundroot
			inc     bl
			jnz     SHORT nextnumber
			jmp     allfound
foundroot:
			mov     al,bl
			stosb
			inc     dh  ;numroots
			cmp		dh,[esp+fr_elpdegree]
			jz		allfound		;maximum number of roots found!

			inc     bl
			jnz     nextnumber
allfound:   movzx   eax,dh			;return the number of roots found

			Postfix
			ret
_find_roots ENDP


_TEXT       ENDS

			END

