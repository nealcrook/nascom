;	title	'Nascom monitor BBUG'
; **********************************
; *** Nascom 1 monitor BBUG	 ***
; **********************************
; BBUG was a 2Kbyte monitor in which the first
; 1Kbyte was a patched near-copy of NASBUG T2.
; This source code has been re-created by
; disassembling a BBUG ROM dump, making the
; first 1Kbyte match NASBUG T2 (and
; highlighting the parts that are changed)
; then using the source listing in the
; BBUG documentation to get label names
; and comments for the remaining code.

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
	ld	b, $15        ;;  rame-ramz 
l1:     ld	(hl),0
	inc	hl
	djnz	l1

; set reflections
	ld	hl,initt
	ld	de,initr
	ld	bc,inite-initt
	ldir

; initialise CRT
	ld	a,$1e
	call	crt
	jp	strt0

; breakpoint restart
rst20:	ex	(sp),hl
	dec	hl
	ex	(sp),hl
	jp	trap
	nop
	nop

; RST = print following string, terminated by 00
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
motflp:	ld	a,$10	; bit 4

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
	ld	hl,_kmap
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
ksc9:	jp	ekey

	nop

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
	and	$10	; bit 4
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
	and	$7f
	cpir
l5:	jr	nz,ksc8
	ld	bc,(_ktab)
	scf
	sbc	hl,bc
	ld	bc,(_ktab0)
	add	hl,bc
	ld	a,l
	scf
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
ktab:	defb	$08,$88,$09
	defb	$14,$9c,$9b,$a3,$92,$c2,$ba,$b2
	defb	$aa,$a2,$98,$a0,$29,$0a,$21,$19
	defb	$1a,$1c,$1b,$23,$12,$42,$3a,$32
	defb	$2a,$22,$18,$20,$a9,$8a,$a1,$99
	defb	$0d,$2c,$41,$13,$3b,$33,$43,$10
	defb	$40,$2d,$38,$30,$28,$31,$39,$25
	defb	$1d,$24,$15,$34,$45,$35,$11,$2b
	defb	$44,$3d,$3c

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
	cp	$1e
	jr	nz,l_0174
	ld	hl,crtram+9
	ld	(hl),$ff
	inc	hl
	ld	b,$30
l_014d:	ld	(hl),$20
	inc	hl
	djnz	l_014d
	ld	b,$10
l8:	ld	(hl),0
	inc	hl
	djnz	l8
	ex	de,hl
	ld	hl,crtram+10
	ld	bc,$03b0
	ldir
	ld	a,$ff
	ld	(crtram+14*64+58),a
l_0167:	ld	hl,$0b8a
l_016a:	ld	(hl),$5f
	ld	(cursor),hl
	pop	hl
	pop	de
	pop	bc
	pop	af
	ret


; remove cursor
l_0174:	ld	hl,(cursor)
	ld	(hl),$20
	cp	$1d
	jr	nz,l_0188

; backspace (thru margins if necessary)
l_017d:	dec	hl
	ld	a,(hl)
	or	a
	jr	z,l_017d
	inc	a
	jr	nz,l_016a
	inc	hl
	jr	l_016a

l_0188:	cp	$1f
	jr	z,l_0195

; put on screen, scroll if necessary
	ld	(hl),a
l_018d:	inc	hl
	ld	a,(hl)
	or	a
	jr	z,l_018d
	inc	a
	jr	nz,l_016a

; scroll
l_0195:	ld	de,crtram+10
	ld	hl,crtram+10+64
	ld	bc,14*64-16
	ldir
	ld	hl,$0010
	add	hl,de
	ld	b,$30
l_01a6:	ld	(hl),' '
	inc	hl
	djnz	l_01a6
	jr	l_0167

; memory modify, arg1=address
modify:	ld	hl,(arg1)
mod1:	call	tbcd3
	ld	a,(hl)
	call	b2hex
	call	inline
	ld	de,$0b52
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
inline:	rst	$28
	defb	'>',$00
inl0:	call	chin
	cp	$1d
	jr	z,l_01ee

; return on cr
	cp	$1f
	jr	z,crlf

; put out char and continue
l_01e9:	call	_crt
	jr	inl0

; handle backspace; dont allow backspace over prompt
l_01ee:	ld	de,(cursor)
	dec	de
	ld	a,(de)
	cp	'>'
	jr	z,inl0
	ld	a,$1d
	jr	l_01e9


; tabulate code, arg1=start addr, arg2=end
;	routine is used by dump command
tabcde:	ld	hl,(arg1)
tbcd1:	ld	de,(arg2)
	push	hl
	or	a
	sbc	hl,de
	pop	hl
	jr	c,l14
	rst	$28
	defb	'.',$1f,00
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
	rst	$28
	defb	$1d,$1d,$1f,$00
	jr	tbcd1
tbcd2:	push	af
	add	a,c
	ld	c,a
	pop	af
	jp	b2hex
tbcd3:	ld	a,h
	call	tbcd2
	ld	a,l
	call	tbcd2
	nop
	nop

space:	ld	a,$20
	jr	l_0257


crlf:	ld	a,$1f
	jr	l_0257


b2hex:
	push	af
	rra
	rra
	rra
	rra
	call	l_024d
	pop	af
l_024d:	and	$0f
	add	a,$30
	cp	$3a
	jr	c,l_0257
	add	a,$07
l_0257:	jp	_crt

; read in a hex number, DE being used as pointer to line
;	NUM+1, NUM+2 contain the number
;	NUM set non zero if there is a number there at all
nexnum:	ld	a,(de)
	cp	' '
	inc	de
	jr	z,nexnum
	dec	de
	xor	a
	ld	hl,$0c12
	ld	(hl),a
	inc	hl
	ld	(hl),a
	inc	hl
	ld	(hl),a
l_026a:	ld	a,(de)
	dec	hl
	dec	hl
	sub	$30
	ret	m
	cp	$0a
	jr	c,l_027c
	sub	$07
	cp	$0a
	ret	m
	cp	$10
	ret	p
l_027c:	inc	de
	inc	(hl)
	inc	hl
	rld
	inc	hl
	rld
	jr	l_026a

; main monitor loop; read a line and obey it
parse:	call	inline
	ld	de,$0b4b
	ld	bc,$0c0a
	ld	a,(de)
	cp	' '
	jr	nz,l_0299
	ld	a,(bc)
	cp	'S'
	jr	nz,parse
l_0299:	ld	(bc),a
	inc	bc
	inc	de
	xor	a
	ld	(bc),a
; get the arguments
ploop:	inc	bc
	call	nexnum
	ld	a,(hl)
	or	a
	jr	z,l_02b3
	inc	hl
	ld	a,(hl)
	ld	(bc),a
	inc	hl
	inc	bc
	ld	a,(hl)
	ld	(bc),a
	ld	hl,$0c0b
	inc	(hl)
	jr	ploop
l_02b3:	ld bc,($0c0a)
	ld hl,ctab
l_02ba:	ld a,(hl)
	or a
	jp z,eparse
	inc hl
	cp c
	jr z,l_02c7
	inc hl
	inc hl
	jr l_02ba
l_02c7:	ld e,(hl)
	inc hl
	ld d,(hl)
l_02ca:	ld hl,parse
	push hl
	ex de,hl
	jp (hl)


exec:	ld a,$ff
	ld (conflg),a
; common to E and S, config tells which
;	set NMI for end of instr
exec1:	ld hl,trap
	ld ($0c48),hl
	pop hl
	ld a,($0c0b)
	or a
	jr z,l_02e8
	ld hl,(arg1)
	ld ($0c3b),hl

l_02e8:
	pop bc
	pop de
	pop af
	pop af
	ld hl,(initr)
	ld sp,hl
	ld hl,($0c3b)
	push hl
	ld ($0c37),hl
	push af
	ld a,$08
	out ($00),a
	pop af
	retn

; step, if arg supplied then is address
step:	xor a
	ld (conflg),a
	jr exec1

trap:	push af
	push hl
	ld a,(port0)
	out ($00),a
	ld a,(conflg)
	or a
	jr z,l_0325
	ld hl,(brkadr)
	ld a,(hl)
	ld ($0c17),a
	ld (hl),$e7
	xor a
	ld (conflg),a
	nop
	nop
	pop hl
	pop af
	retn
l_0325:	push de
	push bc
	ld hl,start
	add hl,sp
	ld de,stack
	ld sp,stack
	ld bc,l1
	ldir
	ld e,(hl)
	inc hl
	ld d,(hl)
	inc hl
	nop
	ld ($0c3b),de
	ld (initr),hl

; print out regs SP PC AF HL DE BC
	ld hl,_ktabl
	ld b,$06
l_0347:	dec hl
	ld a,(hl)
	call b2hex
	dec hl
	ld a,(hl)
	call b2hex
	call space
	djnz l_0347
	jp ereg


strt0:	ld hl,(brkadr)
	ld a,($0c17)
	ld (hl),a
	jp parse

; command table
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
lod1:	ld	hl,$0b8a
	ld	(cursor),hl
l_0385:	call	chin
	cp	$1d
	jr	z,l_0385
	cp	$1f
	jr	z,l_0395
	call	_crt
	jr	nz,l_0385
l_0395:	ld	de,$0b8a
	ld	b,$08
	ld	a,(de)
	cp	'.'
	jp	z,motflp
	call	nexnum
	ld	($0c13),hl
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
	ld	hl,($0c4b)
	push	hl
	ld	hl,slrout
	ld	($0c4b),hl
	call	 tabcde
	pop	 hl
	ld	($0c4b),hl
	jp	motflp

; copy, arguments: from, to, length
copy:	ld	hl,(arg1)
	ld	de,(arg2)
	ld	bc,(arg3)
l_03fa:	ldir                    ;come here from icopy
	ret
	nop
	halt
	halt
; ----------------- end of nasbug t2 code, start of 2nd EPROM -----------

write:	call	motflp
	ld	b,$00

w2:
	call	kdel
	djnz	w2
	ld	hl,(arg1)

w4:
	ld de,(arg2)
	ex de,hl
	scf
	sbc hl,de
	jp c,motflp
	ex de,hl
	ld b,$04

w5:
	ld a,$ff
	call slrout
	djnz w5
	xor a
	cp d
	jr nz,w6
	ld b,e
	inc b

w6:
	ld e,b
	ld a,l
	call slrout
	ld a,h
	call slrout
	ld a,e
	call slrout
	ld a,d
	call slrout
	ld c,$00
	call tx1
	ld a,c
	call slrout
	call crlf
	call sout
	ld b,$04
	ld a,c

w9:
	call slrout
	xor a
	djnz w9
	jr w4


msggds:
	defb $1f,$42,$30,$1f,$45,$30,$1f,$52,$1f

tx1:
	call tx2

tx2:
	call tbcd3
	ex de,hl
	ret


	; start of unknown area $0464 to $0465
	defb $00,$00
	; end of unknown area $0464 to $0465


table:
	push de
	ld e,a

tb1:
	ld a,(hl)
	inc hl
	or a
	jr z,tb3
	cp e
	jr z,tb3
	inc hl
	inc hl
	jr tb1


tb3:
	ld e,(hl)
	inc hl
	ld d,(hl)
	ex de,hl
	pop de
	ret


rnd:
	push bc
	ld b,a
	ld a,r
	add a,(hl)
	jr c,rn2
	dec a

rn2:
	ld (hl),a

sub:
	sub b
	jr nc,sub
	add a,b
	inc a
	pop bc
	ret


ekey:
	jr nc,ke
	ld hl,kmap
	cp $40
	jr nz,k3
	or a
	bit 4,(hl)
	jr z,ke

kn:
	scf

ke:
	pop hl
	pop de
	pop bc
	ret


k3:
	cp $21
	jr c,kn
	cp $55
	jr c,k5
	bit 4,(hl)
	jr z,k5
	add a,$06

k5:
	bit 5,(hl)
	jr z,kn
	add a,$20
	cp $60
	jr nc,kn
	add a,$40
	jr kn


idelay:
	dec de
	ld a,d
	or e
	ret z
	call _kbd
	ret c
	call kdel
	jr idelay


cda:
	ld a,(hl)
	push af
	call cd14
	call cd14
	pop af
	ld (hl),a
	inc hl
	djnz cda
	bit 0,c
	ret nz
	bit 1,c
	ret z
	dec de
	ld a,$30
	jr cd18


cd14:
	xor a
	rld
	jr nz,cd16
	bit 0,c
	jr nz,cd16
	ld a,$20
	jr cd18


cd16:
	set 0,c
	add a,$30

cd18:
	ld (de),a
	inc de
	ret


rdl:
	push bc
	push hl

dl2:
	dec hl
	rld
	djnz dl2
	pop hl
	pop bc
	ret


cad:
	ld a,b

ca2:
	ld (hl),$00
	inc hl
	djnz ca2
	ld b,a
	add a,a
	ld c,a

ca6:
	ld a,(de)
	inc de
	sub $30
	ret c
	cp $0a
	ret nc
	call rdl
	dec c
	jr nz,ca6
	ret


icopy:
	call garg
	or a
	sbc hl,de
	add hl,de
	jp nc,l_03fa
	dec bc
	ex de,hl
	add hl,bc
	ex de,hl
	add hl,bc
	inc bc
	lddr
	ret


arith:
	call garg2
	ex de,hl
	push hl
	add hl,de
	call tbcd3
	pop hl
	or a
	sbc hl,de
	call tbcd3
	dec hl
	dec hl
	ld a,h
	cp $ff
	jr nz,a2
	bit 7,l
	jr nz,aok

ang:
	rst $28

msgbad:
	defb $3f,$3f,$1f,$00
	ret


a2:
	or a
	jr nz,ang
	bit 7,l
	jr nz,ang

aok:
	ld a,l
	call b2hex
	call crlf
	ret


futur1:
	defb	$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
	defb	$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
	defb	$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
	defb	$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
	defb	$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff

; get 3 arguments (or, get 2 arguments)
garg:	ld bc,(arg3)
garg2:	ld de,(arg2)
	ld hl,(arg1)
	ret

g:	ld hl,msggds
	ld b,$09
	call sout
	call write
	ld a,$45
	call slrout
	ld hl,($0c4b)
	push hl
	ld hl,slrout
	ld ($0c4b),hl
	ld hl,(arg3)
	call tbcd3
	pop hl
	ld ($0c4b),hl
	ld a,$1f
	jp slrout

sout:	ld c,$00

so1:	ld a,(hl)
	add a,c
	ld c,a
	ld a,(hl)
	call slrout
	inc hl
	djnz so1
	ret

er1:	ld a,i
	call b2hex
	call space
	push ix
	pop hl
	call tbcd3
	push iy
	pop hl
	call tbcd3
	ld hl,$0c39
	ld a,(hl)
	ld de,$0703
	ld b,$08

er4:	inc de
	rla
	push af
	ld a,(de)
	jr c,er6
	xor a

er6:	call _crt
	pop af
	djnz er4
	ret


msgflg:	defb $53,$5a,$00,$48,$00,$50,$4e,$43

read:	call motflp

r1:	ld b,$04

r2:	call chin
	cp $ff
	jr nz,r1
	djnz r2
	call chin
	ld l,a
	call chin
	ld h,a
	call chin
	ld e,a
	call chin
	ld d,a
	ld c,$00
	call tx1
	call chin
	cp c
	jr nz,r6
	ld b,e
	ld c,$00

r4:	call chin
	ld (hl),a
	add a,c
	ld c,a
	inc hl
	djnz r4
	call chin
	cp c
	jr z,r7

r6:	rst $28

msgerr:	defb $45,$52,$52,$00

r7:	call crlf
	xor a
	cp d
	jp z,motflp
	jr r1

ereg:	call er1
	call crlf
	nop
	jp strt0

eparse:	ld a,c
	ld hl,ectab
	call table
	or a
	jp z,parse
	ex de,hl
	jp l_02ca

ectab:	defb $57,$00,$04,$52,$0c,$07,$49,$14,$05,$41,$27,$05,$48,$9a,$07,$4e,$a1,$07,$47,$a3,$06,$00,$00,$00

futur2:	rst $38
	rst $38
	rst $38
	rst $38
	rst $38
	rst $38
	rst $38
	rst $38
	nop
	rst $38
	rst $38
	rst $38
	rst $38
	rst $38
	rst $38
	rst $38
	nop
	rst $38
	rst $38

h:	ld hl,kex

h1:	ld ($0c4e),hl
	ret

n:	ld hl,kbd
	jr h1

kex:	call kbd
	ret nc
	push hl
	ld hl,$0c08
	cp $20
	scf
	jr z,kx3
	bit 4,(hl)
	jr z,kx3
	call b2hex
	call space
	or a

kx3:	pop hl
	ret


mcr:	push de
	inc hl
	inc c
	ld a,c
	cp $31
	jr c,ecm
	ld c,$01
	ld de,$ffd0
	jr ecma


mcl:	push de
	dec hl
	dec c
	jr nz,ecm
	ld c,$30
	ld de,$0030
	jr ecma


mcd:	push de
	ld de,$0040
	add hl,de
	inc b
	ld a,b
	cp $10
	jr c,ecm
	ld b,$01
	ld de,$fc40
	jr ecma


mcu:	push de
	ld de,$ffc0
	add hl,de
	dec b
	jr nz,ecm
	ld b,$0f
	ld de,$03c0

ecma:	add hl,de

ecm:	ld a,(hl)
	pop de
	bit 0,a
	ret

	org     $0c00
ramz:   equ     $
port0:  defs    1

_kmap:	defb $00,$00,$00,$00,$00,$00,$00,$00
kmap:	defb $00

	; start of unknown area $0c0a to $0c0b
	defb $00,$00
	; end of unknown area $0c0a to $0c0b

arg1:	defw start
arg2:	defw start
arg3:	defw start

	; start of unknown area $0c12 to $0c14
	defb $00,$00,$00
	; end of unknown area $0c12 to $0c14


brkadr:	defw start

	; start of unknown area $0c17 to $0c17
	defb $00
	; end of unknown area $0c17 to $0c17


cursor:
	defb $00

	; start of unknown area $0c19 to $0c19
	defb $00
	; end of unknown area $0c19 to $0c19


conflg:
	defb $00

	; start of unknown area $0c1b to $0c32
	defb $00,$00,$00,$00,$00
	defb $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	defb $00,$00,$00
	; end of unknown area $0c1b to $0c32


stack:
	defb $00

	; start of unknown area $0c34 to $0c3c
	defb $00,$00,$00,$00,$00,$00,$00,$00,$00
	; end of unknown area $0c34 to $0c3c


initr:
	defb $00

	; start of unknown area $0c3e to $0c3e
	defb $00
	; end of unknown area $0c3e to $0c3e


_ktabl:
	defw start

_ktab0:
	defw start

_ktab:
	defw start

	; start of unknown area $0c45 to $0c46
	defb $00,$00
	; end of unknown area $0c45 to $0c46

_nmi:	defs	3
_crt:	defs	3
_kbd:	defs	3
