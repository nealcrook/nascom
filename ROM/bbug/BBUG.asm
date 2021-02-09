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
; foofoobedoo@gmail.com Feb 2020/Feb 2021

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
l1:	ld	(hl),0
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
rst20:	ex	(sp),hl
	dec	hl
	ex	(sp),hl
	jp	trap
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
	ld	a,(kmap+8) ; BBUG "list of modifications" shows (kmap) but opcodes address kmap+8
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
ktab:	defb	08h,88h,09h
	defb	14h,9ch,9bh,0a3h,92h,0c2h,0bah,0b2h
	defb	0aah,0a2h,98h,0a0h,29h,0ah,21h,19h
	defb	1ah,1ch,1bh,23h,12h,42h,3ah,32h
	defb	2ah,22h,18h,20h,0a9h,8ah,0a1h,99h
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
	pop	hl
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
parse:	call	inline
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
	ld	hl,ctab
pend1:	ld	a,(hl)
	or	a
	jp	z,eparse
	inc	hl
	cp	c
	jr	z,l17
	inc	hl
	inc	hl
	jr	pend1
l17:	ld	e,(hl)
	inc	hl
	ld	d,(hl)
l_02ca:	ld	hl,parse
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
	ld	(_hl),hl
	push	af
	ld	a,8
	out	(0),a
	pop	af
	retn

; step, if arg supplied then is address
step:	xor	a
	ld	(conflg),a
	jr	exec1

trap:	push	af
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
	xor	a
	ld	(conflg),a
	nop
	nop
	pop	hl
	pop	af
	retn
l19:	push	de
	push	bc
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
	nop
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
	jp	ereg
strt0:	ld	hl,(brkadr)
	ld	a,(brkval)
	ld	(hl),a	; restore breakpoint
	jp	parse

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
	ld	(num+1),hl
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
l_03fa:	ldir			;come here from icopy
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
	ld hl,kmap+8
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
	ld hl,_af
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
brkval: defs	1
cursor: defs	2
conflg: defs	1
	defs	18h
stack:	defs	2
	defs	2
_hl:	defs	2
_af:	defs	2
_pc:	defs	2
initr:
_sp:	defs	2
; reflections
_ktabl: defs	2
_ktab0:	defs	2
_ktab:	defs	2
_ctab:	defs	2
_nmi:	defs	3
_crt:	defs	3
_kbd:	defs	3
