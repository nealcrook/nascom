;	title	'Nascom monitor NASBUG T2'
; **********************************
; *** Nascom 1 monitor NASBUG T2 ***
; **********************************
; published version 15.02.1978
; modified for common kbd & serial input July 1978
; converted to Z80ASM syntax in February 2000
; 2 lines corrected 2008 (DW)

	org	0
crtram: equ	0800h	; start of video ram
bs:	equ	1dh
ff:	equ	1eh
cr:	equ	1fh
cur:	equ	5fh
line:	equ	0b4ah
curlin: equ	0b8ah

; initialise stack pointer and RAM
start:	ld	sp,stack
	ld	hl,ramz
	ld	b,rame-ramz
l1:     ld	(hl),0
	inc	hl
	djnz	l1

; set reflections
	ld	hl,initt
	ld	de,initr
	ld	bc,inite-initt
	ldir

; initialise CRT
	ld	a,ff
	call	crt
	jp	strt0

; breakpoint restart
	push	af
	push	hl
	push	de
	jp	bpt1
	nop
	nop

; RST 5 = print following string, terminated by 00
prs:	ex	(sp),hl
prs1:	ld	a,(hl)
	inc	hl
	or	a
	jr	z,l2
	call	_crt
	jr	prs1
l2:	ex	(sp),hl
	ret

; keyboard debounce delay routine
kdel:	xor	a
kdel1:	push	af
	pop	af
	push	af
	pop	af
	dec	a
	jr	nz,kdel1
	ret

; read a char from keyboard or uart (first come first served)
chin:	call	_kbd
	ret	c
	in	a,(2)
	rla
	jr	nc,chin
	in	a,(1)
	ret

; set & reset a bit in I/O port 0
flpflp:	push	af
	call	flip
	pop	af
	jr	flip

; start or stop motor
motflp:	ld	a,10h	; bit 4

; flip a bit in port 0
flip:	push	hl
	ld	hl,port0
	xor	(hl)
	out	(0),a
	ld	(hl),a
	pop	hl
	ret

; put character out thru UART, and wait till sent
slrout:	out	(1),a
l3:	in	a,(2)
	add	a,a
	ret	m
	jr	l3

	nop

; NMI vector
	jp	_nmi

; routine to read from keyboard
;	carry is set if a char. is available
;	the standard ASCII code for the char is returned in A
;	EXCEPT for the following chars
;		BS= 1DH	 backspace
;		CR= 1EH	 carriage return (=newline)
;		FF= 1FH	 form feed =clear screen
kbd:	push	bc
	push	de
	push	hl
	ld	a,2	; bit 1
	call	flpflp
	ld	hl,kmap
	in	a,(0)
	cpl
	ld	(hl),a
	ld	b,8
ksc1:	ld	a,1	; bit 0
	call	flpflp
	inc	hl
	in	a,(0)
	cpl
	ld	d,a
	xor	(hl)
	jr	nz,ksc2
ksc1a:	djnz	ksc1
ksc8:	or	a
ksc9:	pop	hl
	pop	de
	pop	bc
	ret
ksc2:	call	kdel
	in	a,(0)
	cpl
	ld	e,a
	ld	a,d
	xor	(hl)
	ld	c,-1
	ld	d,0
	scf
l4:	rl	d
	inc	c
	rra
	jr	nc,l4
	ld	a,d
	and	e
	ld	e,a
	ld	a,(hl)
	and	d
	cp	e
	jr	z,ksc1a
	ld	a,(hl)
	xor	d
	ld	(hl),a
	ld	a,e
	or	a
	jr	z,ksc1a
	ld	a,(kmap)
	and	10h	; bit 4
	or	b
	add	a
	add	a
	add	a
	or	c
	ld	bc,(_ktabl)
	ld	hl,(_ktab)
	cpir

; check again for unshifted character
	jr	z,l5
	ld	hl,(_ktab)
	ld	bc,(_ktabl)
	and	7fh
	cpir
l5:	jr	nz,ksc8
	ld	bc,(_ktab)
	scf
	sbc	hl,bc
	ld	bc,(_ktab0)
	add	hl,bc
	ld	a,l
ksc3:	scf
	jr	ksc9

; set breakpoint address
break:	ld	hl,(arg1)
	ld	(brkadr),hl
	ret

; table entries represent key number for each ASCII code
;	appearing in ASCII order starting at code 1DH
;	Each entry is in the format SRRRRCCC
;	where S=1 implies that shift key must be down
;	RRRR=8-row number (number in counter)
;	CCC=column number (bit number)
; Setting all ones (0FFH) implies that there is no key
;	for this code
; If the shift key is down and no code is found
;	then the table is searched again if
;	the shift key were uo.
ktab:	defb	08h,88h,09h
	defb	14h,9ch,9bh,0a3h,92h,0c2h,0bah,0b2h
	defb	0aah,0a2h,98h,0a0h,29h,0ah,21h,19h
	defb	1ah,1ch,1bh,23h,12h,42h,3Ah,32h
	defb	2ah,22h,18h,20h,0b1h,8ah,0b9h,99h
	defb	0dh,2ch,41h,13h,3bh,33h,43h,10h
	defb	40h,2dh,38h,30h,28h,31h,39h,25h
	defb	1dh,24h,15h,34h,45h,35h,11h,2bh
	defb	44h,3dh,3ch

; reflection initialisation table
initt:	defw	1000h
	defw	64+3-5
	defw	32-3
	defw	ktab
	defw	ctab
	jp	trap
	jp	crt
	jp	kbd
inite:

crt:	or	a
	ret	z
	push	af
	push	bc
	push	de
	push	hl
	cp	ff
	jr	nz,l6
	ld	hl,crtram+9
	ld	(hl),-1
	inc	hl
	ld	b,48
l7:	ld	(hl),' '
	inc	hl
	djnz	l7
	ld	b,16
l8:	ld	(hl),0
	inc	hl
	djnz	l8
	ex	de,hl
	ld	hl,crtram+10
	ld	bc,15*64-16
	ldir
	ld	a,-1
	ld	(crtram+14*64+58),a
crt0:	ld	hl,curlin
crt1:	ld	(hl),cur
	ld	(cursor),hl
crt2:	pop	hl
	pop	de
	pop	bc
	pop	af
	ret


; remove cursor
l6:	ld	hl,(cursor)
	ld	(hl),' '
	cp	bs
	jr	nz,l9

; backspace (thru margins if necessary)
l10:	dec	hl
	ld	a,(hl)
	or	a
	jr	z,l10
	inc	a
	jr	nz,crt1
	inc	hl
	jr	crt1

l9:	cp	cr
	jr	z,crt3

; put on screen, scroll if necessary
	ld	(hl),a
l11:	inc	hl
	ld	a,(hl)
	or	a
	jr	z,l11
	inc	a
	jr	nz,crt1

; scroll
crt3:	ld	de,crtram+10
	ld	hl,crtram+10+64
	ld	bc,14*64-16
	ldir
	ld	hl,16
	add	hl,de
	ld	b,48
l12:	ld	(hl),' '
	inc	hl
	djnz	l12
	jr	crt0

; memory modify, arg1=address
modify:	ld	hl,(arg1)
mod1:	call	tbcd3
	ld	a,(hl)
	call	b2hex
	call	inline
	ld	de,line+8
	ld	b,0

; note that line starts at line+8
mod2:	push	hl
	call	nexnum
	ld	a,(hl)
	or	a
	jr	z,mod3
	inc	hl
	ld	a,(hl)
	pop	hl
	ld	(hl),a
	inc	b
	inc	hl
	jr	mod2

mod3:	pop	hl
	ld	a,(de)
	cp	'.'
	ret	z
	ld	a,b
	or	a
	jr	nz,l13
	inc	hl
l13:	jr	mod1

; print system prompt and read a line
inline:	rst	28h
	defb	'>',0
inl0:	call	chin
	cp	bs
	jr	z,inl2

; return on cr
	cp	cr
	jr	z,crlf

; put out char and continue
inl1:	call	_crt
	jr	inl0

; handle backspace; dont allow backspace over prompt
inl2:	ld	de,(cursor)
	dec	de
	ld	a,(de)
	cp	'>'
	jr	z,inl0
	ld	a,bs
	jr	inl1

; tabulate code, arg1=start addr, arg2=end
;	routine is used by dump command
tabcde:	ld	hl,(arg1)
tbcd1:	ld	de,(arg2)
	push	hl
	or	a
	sbc	hl,de
	pop	hl
	jr	c,l14
	rst	28h
	defb	'.',cr,00
	ret
l14:	ld	c,0
	call	tbcd3
	ld	b,8
tbcd1a:	ld	a,(hl)
	call	tbcd2
	inc	hl
	call	space
	djnz	tbcd1a
; put put checksum and backspace over it so it doesnt show
	ld	a,c
	call	b2hex
	rst	28h
	defb	1dh,1dh,1fh,0
	jr	tbcd1
tbcd2:	ld	d,a
	add	c
	ld	c,a
	ld	a,d
	jp	b2hex
tbcd3:	ld	a,h
	call	tbcd2
	ld	a,l
	call	tbcd2
	jr	space

space:	ld	a,' '
	jr	jcrt
crlf:	ld	a,1fh
	jr	jcrt

; print A in hex
b2hex:	push	af
	rra
	rra
	rra
	rra
	call	b2hex1
	pop	af
b2hex1:	and	0fh
	add	30h
	cp	'9'+1
	jr	c,jcrt
	add	7
jcrt:	jp	_crt

; read in a hex number, DE being used as pointer to line
;	NUM+1, NUM+2 contain the number
;	NUM set non zero if there is a number there at all
nexnum:	ld	a,(de)
	cp	' '
	inc	de
	jr	z,nexnum
	dec	de
	xor	a
	ld	hl,num
	ld	(hl),a
	inc	hl
	ld	(hl),a
	inc	hl
	ld	(hl),a
nn1:	ld	a,(de)
	dec	hl
	dec	hl
	sub	'0'
	ret	m
	cp	10
	jr	c,nn2
	sub	7
	cp	10
	ret	m
	cp	10h
	ret	p
nn2:	inc	de
	inc	(hl)
	inc	hl
	rld
	inc	hl
	rld
	jr	nn1

; main monitor loop; read a line and obey it
parse:	call 	inline
	ld	de,line+1
	ld	bc,args
	ld	a,(de)
	cp	' '
	jr	nz,l16
	ld	a,(bc)
	cp	'S'
	jr	nz,parse
l16:	ld	(bc),a
	inc	bc
	inc	de
	xor	a
	ld	(bc),a
; get the arguments
ploop:	inc	bc
	call	nexnum
	ld	a,(hl)
	or	a
	jr	z,pend
	inc	hl
	ld	a,(hl)
	ld	(bc),a
	inc	hl
	inc	bc
	ld	a,(hl)
	ld	(bc),a
	ld	hl,args+1
	inc	(hl)
	jr	ploop
pend:	ld	bc,(args)
	ld	hl,(_ctab)
pend1:	ld	a,(hl)
	or	a
	jr	z,parse
	inc	hl
	cp	c
	jr	z,l17
	nop
	inc	hl
	inc	hl
	jr	pend1
l17:	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	hl,parse
	push	hl
	ex	de,hl
	jp	(hl)

exec:	ld	a,0ffh
	ld	(conflg),a
; common to E and S, config tells which
;	set NMI for end of instr
exec1:	ld	hl,trap
	ld	(_nmi+1),hl
	pop	hl
	ld	a,(args+1)
	or	a
	jr	z,l18
	ld	hl,(arg1)
	ld	(_pc),hl
l18:	pop	bc
	pop	de
	pop	af
	pop	af
	ld	hl,(_sp)
	ld	sp,hl
	ld	hl,(_pc)
	push	hl
	ld	hl,(_hl) ; line corrected
	push	af
	ld	a,8
	out	(0),a
	pop	af
	retn

; step, if arg supplied then is address
step:	xor	a
	ld	(conflg),a
	jr	exec1

trap:	ex	(sp),hl
	inc	hl
	ex	(sp),hl
	push	af
	push	hl
	ld	a,(port0)
	out	(0),a
	ld	a,(conflg)
	or	a
	jr	z,l19
	ld	hl,(brkadr)
	ld	a,(hl)
	ld	(brkval),a
	ld	(hl),0e7h	; rst4
	pop	hl
	pop	af
	ex	(sp),hl
	dec	hl
	ex	(sp),hl
	retn
l19:	push	de
bpt1:	push	bc
	ld	hl,0
	add	hl,sp
	ld	de,stack
	ld	sp,stack
	ld	bc,8
	ldir
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	inc	hl
	dec	de
	ld	(_pc),de
	ld	(_sp),hl

; print out regs SP PC AF HL DE BC
	ld	hl,_sp+2
	ld	b,6
regs1:	dec	hl
	ld	a,(hl)
	call	b2hex
	dec	hl
	ld	a,(hl)
	call	b2hex
	call	space
	djnz	regs1
	call	crlf
strt0:	ld	hl,(brkadr)
	ld	a,(brkval)
	ld	(hl),a	; restore breakpoint
	jp	parse

; commant table
;	format: character, address of subroutine
ctab:	defb	'M'
	defw	modify
	defb	'C'
	defw	copy
	defb	'E'
	defw	exec
	defb	'S'
	defw	step
	defb	'T'
	defw	tabcde
	defb	'B'
	defw	break
	defb	'L'
	defw	load
	defb	'D'
	defw	dump
	nop

; load command
load:	call	motflp
lod1:	ld	hl,curlin
	ld	(cursor),hl
lod1b:	call	chin
	cp	bs
	jr	z,lod1b
	cp	cr
	jr	z,lod1a
	call	_crt
	jr	nz,lod1b
lod1a:	ld	de,curlin
	ld	b,8
	ld	a,(de)
	cp	'.'
	jp	z,motflp
	call	nexnum
	ld	hl,(num+1) ;line corrected
	ld	a,l
	add	a,h
	ld	c,a
	push	hl
	ld	hl,crtram
	push	hl
lod2:	push	hl
	call	nexnum
	inc	hl
	ld	a,(hl)
	pop	hl
	ld	(hl),a
	inc	hl
	add	a,c
	ld	c,a
	djnz	lod2
	call	nexnum
	inc	hl
	ld	a,(hl)
	cp	c
	pop	hl
	pop	de
	jr	nz,l20
	ld	bc,8
	ldir
	jr	lod1
l20:	call	crlf
	jr	lod1


; dump, uses same code as tabulate
dump:	call	motflp
	ld	b,0
l21:	call	kdel
	djnz	l21
	ld	hl,(_crt+1)
	push	hl
	ld	hl,slrout
	ld	(_crt+1),hl
	call	tabcde
	pop	hl
	ld	(_crt+1),hl
	jp	motflp

; copy, arguments: from, to, length
copy:	ld	hl,(arg1)
	ld	de,(arg2)
	ld	bc,(arg3)
	ldir
	ret
	nop
	nop
	nop
; ----------------- end of nasbug t2 ------------------------------------

	org	0c00h
ramz:	equ	$
port0:	defs	1
kmap:	defs	9
args:	defs	2
arg1:	defs	2
arg2:	defs	2
arg3:	defs	2
num:	defs	3
rame:	equ	$
brkadr:	defs	2
brkval:	defs	1
cursor:	defs	2
conflg:	defs	1
	defs	18h
stack:	defs	2
	defs	2
_hl:	defs	2
_af:	defs	2
_pc:	defs	2
initr:
_sp:	defs	2
; reflections
_ktabl:	defs	2
_ktab0:	defs	2
_ktab:	defs	2
_ctab:	defs	2
_nmi:	defs	3
_crt:	defs	3
_kbd:	defs	3
