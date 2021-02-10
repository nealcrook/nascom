	; NAS-SYS 1 (R1)
	; WRITTEN BY RICHARD BEAL

	; source code re-created from NAS-SYS 3 electronic
	; source and contemporary NAS-SYS 1 printed source
	; foofobedoo@gmail.com Feb 2020

	; characters
	org	0
bs:	equ	08h
lf:	equ	0ah
cs:	equ	0ch
cr:	equ	0dh
cul:	equ	11h
cur:	equ	12h
cuu:	equ	13h
cud:	equ	14h
csl:	equ	15h
csr:	equ	16h
ch:	equ	17h
ccr:	equ	18h
esc:	equ	1bh
cu:	equ	5fh
del:	equ	7fh

	; rom addresses
rom:	equ	0
djmp:	equ	0d000h
yjmp:	equ	0b000h
bprc:	equ	0fffah
bprw:	equ	0fffdh

	; video ram
vram:	equ	0800h
vl1:	equ	vram+10
vl2:	equ	vl1+64
vl15:	equ	vram+038ah
vend:	equ	vram+0400h

	; workspace ram
ram:	equ	0c00h
ramtop:	equ	1000h

	org	rom
	; start of monitor
start:
	ld	sp,ramtop
	rst	rcal
	defb	stmon-$-1
	jp	mret

	; get input
rin:	rst	scal
	defb	zin
	ret	c
	jr	rin

	; initialize monitor
stmon:	jp	strtb

	; relative call
rcal:	push    hl
	pop     hl
	; inc ret address
	pop	hl
	inc     hl
	push    hl
	jp	rcalb

	; subroutine call
scal:	push    hl
	pop     hl
	; inc ret address
	pop	hl
	inc     hl
	push    hl
	jp	scalb

	; bpt
	; decrement pc on stack
brkpt:	ex	(sp),hl
	dec	hl
	ex	(sp),hl
	jp	trap
	defb	0,0 ; fill

	; output a string
prs:	ex	(sp),hl
prs1:	ld	a,(hl)
	inc	hl
	; output unless 0
	or	a
	jr	nz,prs2
	ex	(sp),hl
dret:	ret

	; output a char
rout:	push	hl
	jp	aout

	; more of prs
prs2:	rst	rout
	jr	prs1
	defb	0 ; fill

	; delay
rdel:	dec	a
	ret	z
	push 	af
	pop	af
	jr	rdel

	; delay
tdel:	xor	a
	ld	b,a
tdel2:	rst	rdel
	rst	rdel
	djnz	tdel2
	ret

	; set,  reset bit in P0
fflp:	push	hl
	ld	hl,port0
	xor	(hl)
	out	(0),a
	ld	a,(hl)
ff2:	out	(0),a
	pop	hl
	ret

	; flip bit 4 in P0
mflp:	ld	a,10h
	push	hl
	ld	hl,port0
	xor	(hl)
	ld	(hl),a
	jr	ff2

	; serial output to P1
srlx:	push	af
	out	(1),a
	; wait until output
srl4:	in	a,(2)
	bit	6,a
	jr	z,srl4
	pop	af
	ret

	; nmi restart
rnmi:	jp	_nmi

	; get input
bin:	ld      e,0c0h
bin2:	rst	scal
	defb	zin
	ret     c
	dec     e
	jr	nz,bin2
	ret

	; blink until input
blink:	ld	hl,(cursor)
	ld	d,(hl)
	ld	(hl),cu
	rst	rcal
	defb	bin-$-1
	ld	(hl),d
	ret	c
	rst	rcal
	defb	bin-$-1
	jr	nc,blink
	ret

	; check serial in
srlin:	in	a,(2)
	rla
	ret	nc
	in	a,(1)
	ret

	; keyboard routine
	; reset kbd counter
kbd:	ld	a,2
	call	fflp
	; store row 0 in map
	ld	hl,kmap
	in	a,(0)
	cpl
	ld	(hl),a

	; scan 8 rows
	ld	b,8
	; inc kbd counter
ksc1:	ld	a,1
	call	fflp
	inc	hl
	; get row status
	in	a,(0)
	cpl
	ld	d,a
	; if map different
	;  find out why
	xor	(hl)
	jr	nz,ksc2
	; scan next row
ksc1a:	djnz	ksc1
	; no key pressed
ksc8:	or	a
	ret
	; wait to debounce
ksc2:	xor	a
	rst	rdel
	; get row again
	in	a,(0)
	cpl
	ld	e,a
	; e = new state
	ld	a,d
	; a = old state
	xor	(hl)
	; a = changes
	; find changed bit
	ld	c,-1
	ld	d,0
	scf
ksc4:	rl	d
	inc	c
	rra
	jr	nc,ksc4
	; c = col changed
	; d= mask with 1 at change
	ld	a,d
	and	e
	ld	e,a
	; e= new state
	;  masked by change
	; if map state and new
	;  state equal, ignore
	ld	a,(hl)
	and	d
	cp	e
	jr	z,ksc1a
	; update map
	ld	a,(hl)
	xor	d
	ld	(hl),a
	; if new state is 0, then
	;  key released, so ignore
	ld	a,e
	or	a
	jr	z,ksc1a

	; value = srrrrccc
	;  s=1 if shift
	;  rrrr=9-row number
	;  ccc=column number
	ld	a,(kmap)
	and	10h
	or	b
	add	a,a
	add	a,a
	add	a,a
	or	c

	; search table
	rst	rcal
	defb	kse-$-1
	jr	z,ksc5
	; check for unshifted
	and	07fh
	rst	rcal
	defb	kse-$-1
	jr	nz,ksc8
	; calc ascii value
ksc5:   scf
	sbc     hl,de
	ld	a,l

	; support lower case
	cp	"A"
	jr	c,k20
	cp	"Z"+1
	jr	nc,k20
	; is it a letter
	ld      hl,kmap
	bit	4,(hl)
	; 1= shift down
	ld      hl,_kopt
	jr	nz,k8
	; shift not down
	bit     0,(hl)
	jr      z,k20
	add     a,20h
	jr      k20
	; shift was down
k8:     add     a,20h
	bit     0,(hl)
	jr      z,k20
	sub     20h

	; control keys
k20:    ld      hl,kmap
	;  if not @, may modify
	cp	"@"
	jr	nz,k30
	; if shift down, normal,
	;  otherwise ignore
	bit	4,(hl)
	jr	z,ksc8
	jr	k35
	; if @ down, modify
k30:	bit 5,(hl)
	jr	z,k35
	xor	40h
	; control
k35:	bit	3,(hl)
	jr	z,k40
	xor	40h
	; graphic
k40:	ld	hl,kmap+5
	bit	6,(hl)
	jr	z,k55
	xor	80h

	; k4 option
	;  change bit 7
k55:	ld	hl,_kopt
	bit	2,(hl)
	jr	z,k60
	xor	80h

	;  end
k60:	scf
	ret

	; search keyboard table
kse:	ld	hl,(_ktab)
	ld      d,h
	ld      e,l
	ld	bc,(_ktabl)
	cpir
	ret

	; workspace initialisation
	;  table
initt:	equ	$
	; user stack
isp:    defw    ramtop
	; length of ktab
iktabl:	defw	ktabe-ktab
	; end of keyboard table
iktab:	defw	ktab
	; subroutine table
istab:	defw	staba-"A"-"A"
	; output table
iout:	defw	outt1
	; input table
iin:	defw	int1
	; user jumps
iuout:	jp	dret
iuin:	jp	dret
	; nmi jump
inmi:	defb	0c3h
initx:	equ	$


	; crt routine
	;  ignore null or lf
crt:	or	a
	ret	z
	push	af
	cp	lf
	jr	z,crt2

	; clear screen
	cp	cs
	jr	nz,crt6
	; clear top line
	ld	hl,vl1
	push	hl
	ld	b,48
cr1:	ld	(hl)," "
	inc	hl
	djnz	cr1
	; set margin
	ld	b,16
cr3:	ld	(hl),0
	inc	hl
	djnz	cr3
	; copy down screen
	ex	de,hl
	pop	hl
	push	hl
	ld	bc,vend-vram-64-10-6
	ldir
	; set to top left
	pop	hl

	; set hl left side
crt0:	rst	scal
	defb	zcpos

	; save cursor
crt1:	ld	(cursor),hl

	; return
crt2:	pop	af
	ret

	; set hl to cursor
crt6:	ld	hl,(cursor)

	; bs, cul
	cp	bs
	jr	nz,crt14
crt8:	push	af
	; ignore margins
crt10:	dec hl
	ld	a,(hl)
	or	a
	jr	z,crt10
	pop	af
	cp	cul
	jr	z,crt12
	ld	(hl)," "
crt12:	rst	rcal
	defb	ctst-$-1
	jr	crt2
crt14:	cp	cul
	jr	z,crt8

	; cursor home, esc
	cp	ch
	jr	z,crt0
	cp	esc
	jr	nz,crt20
	rst	scal
	defb	zcpos
	ld	b,48
crt18:	ld	(hl)," "
	inc	hl
	djnz	crt18
	jr	crt0

	; new line, ccr
crt20:	cp	cr
	jr	z,crt38
	cp	ccr
	jr	nz,crt25
	push	hl
	rst	scal
	defb	zcpos
	pop	de
	or	a
	sbc	hl,de
	add	hl,de
	jr	z,crt1
	jr	crt38

	; cuu, cud
crt25:	cp	cuu
	jr	nz,crt28
	ld	de,-64
crt26:	add	hl,de
	rst	rcal
	defb	ctst-$-1
	jr	crt2
crt28:	cp	cud
	jr	nz,crt29
	ld	de,64
	jr	crt26

	; csl, csr
crt29:	cp	csl
	jr	nz,crt32
crt30:	inc	hl
	ld	a,(hl)
	dec	hl
	or	a
	jr	nz,crt31
	ld	(hl)," "
	jr	crt2
crt31:	ld	(hl),a
	inc	hl
	jr	crt30
crt32:	cp	csr
	jr	nz,crt34
	ld	b," "
crt33:	ld	a,(hl)
	or	a
	jr	z,crt2
	ld	(hl),b
	ld	b,a
	inc	hl
	jr	crt33

	; test for on screen
ctst:	ld	de,vl1
	or	a
	sbc	hl,de
	add	hl,de
	ret	c
	ld	de,vl15+48
	or	a
	sbc	hl,de
	add	hl,de
	ret	nc
	pop	af
ct8:	jp	crt1

	; cur, others
crt34:	cp	cur
	jr	z,crt36
	ld	(hl),a
	; ignore margins
crt36:	inc	hl
	ld	a,(hl)
	or	a
	jr	z,crt36
	rst     rcal
	defb    ctst-$-1

	; do new line
crt38:	rst	scal
	defb	zcpos
	ld	de,64
	add	hl,de
	rst	rcal
	defb	ctst-$-1

	; scroll up
crt40:	ld	de,vl1
	ld	hl,vl2
	ld	bc,vend-vram-64-64-16
	ldir
	; clear bottom line
	ld	b,48
crt50:	dec	hl
	ld	(hl)," "
	djnz	crt50
	ld      hl,vl15
	jr	ct8

	; set hl to start of line
cpos:	ld	a,l
cp2:    sub     40h
	jr      nc,cp2
	add	a,36h
	ld      e,a
	ld	a,l
	sub     e
	ld      l,a
	ret

	; modify command
modify:	rst	scal
	defb	zargs
	; output address
mod1:	ld	(arg1),hl
	rst	scal
	defb	ztbcd3
	ld      a,(hl)
	rst	scal
	defb	zb2hex
	; get input line
	rst	prs
	defb	" ",cul,cul,cul,0
	rst	rcal
	defb	inls-$-1
	; get address
	rst	scal
	defb	znum
	jr	c,mod9
	ld	a,(hl)
	or	a
	jr	z,mod9
	inc	hl
	push	de
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ex	de,hl
	pop	de
	ld	b,0
	; get each entry
mod2:	push	hl
	rst	scal
	defb	znum
	ld	a,(hl)
	or	a
	jr	z,mod3
	; put into memory
	inc	hl
	; hl = numn+1 = numv
	ld	a,(hl)
	pop	hl
mod2a:	ld	(hl),a
	inc	b
	inc	hl
	push	hl
mod3:	pop	hl
	ld	a,(de)
	; if "." return
	cp	"."
	ret	z
	; if "," set char
	cp	","
	jr	nz,mod4
	inc	de
	ld	a,(de)
	inc	de
	jr	mod2a
	; inc if none
mod4:	ld	a,b
	or	a
	jr	nz,mod5
	inc	hl
	; if ":" go back
mod5:	ld	a,(de)
	cp	":"
	jr	nz,mod7
	dec	hl
	dec	hl
	jr	mod1
	; if "/" set to value
mod7:	cp	"/"
	jr	nz,mod8
	inc	de
	rst	scal
	defb	znum
	jr	c,mod9
	ld	hl,(numv)
	jr	mod1
mod8:	or	a
	jr	z,mod1
	cp	" "
	jr	z,mod2
mod9:	rst	scal
	defb	zerrm
	jr	modify

	; routine to get input line
	; store bpt byte
inls:   push    hl
	call    brst0
	; set conflg to 0
	xor     a
	ld      (conflg),a
	; reset nmi address
	ld	hl,trap
	ld	(_nmi+1),hl
	pop     hl
	; normal start of routine
	; get input char
inlin:	push	hl
inl2:	rst	scal
	defb	zblink
	rst	rout
	cp	cr
	jr	nz,inl2
	; set de to start of input
	ld	hl,(cursor)
	ld	de,-64
	add	hl,de
	ex	de,hl
	pop	hl
	ret

	; tabulate command
tabcde: push    bc
	jr      tb3
	; if h<de got to tb2
tb1:	or	a
	sbc	hl,de
	add	hl,de
	jr      c,tb2
	; end, so output ".",CR
tb8:    pop     bc
	rst     prs
	defb    ".",cr,0
	ret
	; control scrolling
tb2:	ld	a,b
	or	c
	jr	nz,tb3
	rst	rin
	cp	esc
	jr      z,tb8
	pop	bc
	push	bc
tb3:	dec	bc
	push	bc
	; init checksum
	ld      c,0
	; output address
	rst	prs
	defb    " "," ",0
	rst	scal
	defb	ztbcd3
	; output 8 bytes
	ld	b,8
tb4:	ld	a,(hl)
	rst	scal
	defb	ztbcd2
	inc     hl
	rst	scal
	defb	zspace
	djnz    tb4
	; output checksum etc
	ld      a,c
	rst     scal
	defb    zb2hex
	rst     prs
	defb    bs,bs,cr,0
	pop     bc
	jr      tb1

	; output hl then space
tbcd3:	ld	a,h
	rst	scal
	defb	ztbcd2
	ld	a,l
	rst	scal
	defb	ztbcd2

	; output space
space:	ld	a," "
	rst	rout
	ret

	; error message
errm:	rst	prs
	defm	"Error"
	defb	0

	; output cr
crlf:	ld	a,cr
	rst	rout
	ret

	; add to checksum, output
tbcd2:	push	af
	add	a,c
	ld	c,a
	pop	af

	; output a
b2hex:	push	af
	rra
	rra
	rra
	rra
	rst	rcal
	defb	b1hex-$-1
	pop	af

	; output low half a
b1hex:	and	0fh
	add     a,"0"
	cp      "9"+1
	jr      c,b1h4
	add     a,"A"-"0"-10
	; output char
b1h4:   rst	rout
	ret

	; output hl de, add to sum
tx1:    rst     rcal
	defb    tx2-$-1
tx2:    rst     scal
	defb    ztbcd3
	ex      de,hl
	ret

	; read in hex value
	; de = input line
	; numn = no of chars
	; numv = value
num:	ld	a,(de)
	; ignore blanks
	cp	" "
	inc	de
	jr	z,num
	dec	de
	; numv, numn = 0
	ld	hl,0
	ld	(numv),hl
	xor	a
	ld	hl,numn
	ld	(hl),a
	; get char
nn1:	ld	a,(de)
	; check for end
	or	a
	ret	z
	cp	" "
	ret	z
	; convert from ascii
	; if lt 0 invalid
	sub	a,"0"
	ret	c
	; if lt 10 then ok, so nn2
	cp	10
	jr	c,nn2
	; convert a/f from ascii
	sub	a,"A"-"0"-10
	; if lt 10 invalid
	cp	10
	ret	c
	; if ge 16 invalid
	cp	16
	jr	c,nn2
	; invalid
	scf
	ret

	; valid char found
	; point to next char
nn2:	inc	de
	; inc numn
	inc	(hl)
	; put value in numv, rotating
	;  previous contents
	inc	hl
	rld
	inc	hl
	rld
	dec	hl
	dec	hl
	jr	z,nn1
	dec	de
	scf
	ret

	; get arguments
rlin:	ld	bc,argn
	xor	a
	ld	(bc),a
	; get value
	; cc set if invalid
rl2:	rst	scal
	defb	znum
	ret	c
	; check for end
	ld	a,(hl)
	or	a
	ret	z
	; copy to arg1/10
	inc	hl
	inc	bc
	ld	a,(hl)
	ld	(bc),a
	inc	hl
	inc	bc
	ld	a,(hl)
	ld	(bc),a
	; inc argn
	ld	hl,argn
	inc	(hl)
	ld	a,(hl)
	cp	11
	jr	c,rl2
	scf
	ret

	; store bpt byte
brst0:	ld	hl,(brkadr)
	ld	a,(hl)
	ld	(brkval),a
	ret

	; restore bpt byte
brres:	ld	hl,(brkadr)
	ld	a,(brkval)
	ld	(hl),a
	ret

	; monitor initialisation
	; restore bpt byte
strtb:	rst	rcal
	defb	brres-$-1
	; set workspace to 0
	ld	de,initz
	ld	b,initr-initz
	xor	a
st4:	ld	(de),a
	inc	de
	djnz	st4
	; set workspace from table
	ld	hl,initt
	ld	bc,inite-initr
	ldir
	; clear screen
	rst	prs
	defb	cs,0
	ret

	; user return
	;  reset stacks
mret:	ld	sp,stack
	ld	hl,(isp)
	ld	(rsp),hl
	rst	prs
	defm	"NAS-SYS 1"
	defb	cr,0

	; bpt or nmi
	; restore bpt byte
strt0:  rst	rcal
	defb	brres-$-1

	; main monitor loop
	;  get line and obey
parse:	call	inls
	ld	bc,argx
	; if command is blank, and
	;  previous command not S,
	;  ignore it
	ld	a,(de)
	cp	" "
	jr	nz,pa2
	ld	a,(bc)
	cp	"S"
	jr	nz,parse
	; check and store
pa2:	cp	"A"
	jr	c,perr
	cp	"Z"+1
	jr	nc,perr
	ld	(bc),a
	ld	(argc),a
	; point to next char
	inc	de
	; get args
	rst	scal
	defb	zrlin
	jr	nc,pend
perr:	rst	scal
	defm	zerrm
	jr	parse
	; call command routine
pend:	rst	scal
	defb	zargs
	rst	scal
	defb	zscalj
pa7:	jr	parse

	; the execute command
	; conflg not 0 if e command
exec:	ld	a,-1
	ld	(conflg),a

	; execute and step commands
	; discard return
step:	pop	af
	; if no address entered,
	;   use stored user pc
	ld	a,(argn)
	or	a
	jr	z,exec2
	; user pc = new address
	ld	(rpc),hl
	; restore regs bc de hl af
exec2:	pop	bc
	pop	de
	pop	af ; in fact rhl
	pop	af
	; restore user sp
	ld	hl,(rsp)
	ld	sp,hl
	; put user pc on top of stack
	ld	hl,(rpc)
	push    hl
	; restore user hl
	ld	hl,(rhl)
	; set bit 3 of p0, to
	;  activate nmi
	push	af
	ld	a,8
	out	(0),a
	pop	af
	; execute one step of program
	retn

	; come here after nmi or bpt
trap:	push	af
	push	hl
	; reset nmi bit in p0
	ld	a,(port0)
	out	(0),a
	; if conflg not 0 then e
	;  so execute normally
	ld	a,(conflg)
	or	a
	jr	z,er1
	; store bpt byte
	;   and insert restart
	call	brst0
	ld	(hl),0e7h
	; set conflg tp 0 for
	;  nmi or bpt,
	xor     a
	ld      (conflg),a
	; execute program normally
trap8:	pop	hl
	pop	af
	retn

	; store user registers
er1:	push	de
	push	bc
	; stack has: pc af hl de bc
	; set hl to user sp
	ld	hl,0
	add	hl,sp
	; set monitor sp
	ld	sp,stack
	; copy user regs from user
	;  stack to reg save area
	ld	de,stack
	ld	bc,8
	ldir
	; set de to pc on user stack
	ld	e,(hl)
	inc     hl
	ld      d,(hl)
	inc     hl
	; store user pc
	ld	(rpc),de
	; store user sp
	ld	(rsp),hl

	; output registers
pregs:	rst	prs
	defb	ccr,0
	; sp pc af hl de bc
	ld	hl,rsae
	ld	b,6
er2:	dec	hl
	ld	a,(hl)
	rst     scal
	defb    zb2hex
	dec	hl
	ld	a,(hl)
	rst     scal
	defb    zb2hex
	rst     scal
	defb    zspace
	djnz    er2
	; i reg
	ld	a,i
	rst	scal
	defb	zb2hex
	rst	scal
	defb	zspace
	; ix iy regs
	push	ix
	pop	hl
	rst	scal
	defb	ztbcd3
	push	iy
	pop	hl
	rst	scal
	defb	ztbcd3
	; f reg
	ld	a,(raf)
	ld	de,estr-1
	ld	b,8
er4:	inc	de
	rla
	push	af
	ld	a,(de)
	jr	nc,er6
	rst	rout
er6:	pop	af
	djnz	er4
	rst	prs
	defb	ccr,0
	jp      strt0

	; string for flags
estr:	defb	"S","Z",0,"H"
	defb	0,"P","N","C"

	; load command
load:	rst     scal
	defb    zmflp
	; normal tables
	rst     scal
	defb	znnom
	push    hl
	rst     scal
	defb    znnim
	push    hl
	; get input
lod1:	rst     rin
	; strip parity
lod1a:	and     7fh
	; if "." then end
	cp      "."
	jr      z,lod9
	; if cr then end of line,
	;  so lod2 to process it
	cp      cr
	jr      z,lod2
	; ignore bs lf etc
	cp      " "
	jr      c,lod1
	rst     rout
	jr      lod1

	; convert and check
lod2:	ld      hl,(cursor)
	rst     scal
	defb    zcpos
	ex      de,hl
	rst     scal
	defb    zrlin
	jr      c,lod8
	; checksum
	ld      hl,arg1
	xor     a
	ld      b,18
lod3:   add     a,(hl)
	inc     hl
	djnz    lod3
	cp      (hl)
	jr      nz,lod8
	; copy to memory
	ld      hl,(arg1)
	ld      de,arg2
	ld      b,8
lod5:   ld      a,(de)
	ld      (hl),a
	inc     hl
	inc     de
	inc     de
	djnz    lod5
	; cursor home
	rst     prs
	defb    esc,0
	jr      lod1
	; bad data, scroll up
lod8:   rst     scal
	defb    zcrlf
	jr      lod1
	; end
lod9:   rst     rin
	and     7fh
	cp      cr
	jr      nz,lod1a
	rst     rout
	jp      r1x

	; write command
write:	rst	scal
	defb	zmflp
	; wait
	rst	scal
	defb	ztdel
	; output to crt inly
	rst	scal
	defb	znnom
	push	hl
	; output 256 nulls
	xor a
	ld	b,a
w3:	rst	scal
	defb	zsrlx
	djnz	w3
	; calculate length-1
	rst	scal
	defb	zargs
w4:	ld      de,(arg2)
	ex	de,hl
	scf
	sbc	hl,de
	; if len-1 is neg, end
	jp	c,r1y
	ex	de,hl
	; hl = start
	; de = length-1
	; wait
	xor	a
	rst	rdel
	; output 00 ff ff ff ff
	ld	b,5
w5:	rst	scal
	defb	zsrlx
	ld	a,0ffh
	djnz	w5
	; if block 0, set len to e+1
	xor	a
	cp	d
	jr	nz,w6
	ld	b,e
	inc	b
	; set e to length
w6:	ld	e,b
	; output start address
	ld	a,l
	rst	scal
	defb	zsrlx
	ld	a,h
	rst	scal
	defb	zsrlx
	; output length of data
	ld	a,e
	rst	scal
	defb	zsrlx
	; output block number
	ld	a,d
	rst	scal
	defb	zsrlx
	; now display all this
	; and output header checksum
	ld	c,0
	rst	scal
	defb	ztx1
	ld	a,c
	rst	scal
	defb	zsrlx
	; output the block
	rst	scal
	defb	zsout
	; output checksum and nulls
	ld	b,11
	ld	a,c
w9:	rst	scal
	defb	zsrlx
	xor	a
	djnz	w9
	; crlf (read has same timing)
	rst	scal
	defb	zcrlf
	jr	w4

	; icopy command
	; if arg1 ge arg2, go to
	;   ldir copy
icopy:	or	a
	sbc	hl,de
	add	hl,de
	jr	nc,copy
	; set to end not start
	dec	bc
	ex	de,hl
	add	hl,bc
	ex	de,hl
	add	hl,bc
	inc	bc
	lddr
	ret

	; copy command
copy:	ldir
	ret

	; arithmetic command
arith:	ex	de,hl
	push	hl
	; sum
	add	hl,de
	rst	scal
	defb	ztbcd3
	; difference
	pop	hl
	or	a
	sbc	hl,de
	rst	scal
	defb	ztbcd3
	; offset
	dec	hl
	dec	hl
	ld	a,h
	cp      0ffh
	jr      nz,a2
	bit     7,l
	jr	nz,aok
	; no good so ??
ang:	rst	prs
	defb	"?","?",cr,0
	ret
a2:     or      a
	jr      nz,ang
	bit     7,l
	jr      nz,ang
	; output offset
aok:	ld	a,l
a7:	rst	scal
	defb	zb2hex
	jp	crlf

	; relative call restart
rcalb:	dec     hl
	dec     sp
	dec     sp
	push    af
	push    de
	ld	e,(hl)
	; e = offset, set d
	ld	a,e
	rla
	sbc	a,a
	ld	d,a
	inc	hl
	add	hl,de
rcal4:	pop	de
	pop	af
	ex	(sp),hl
	; fake jump to routine
	ret

	; subroutine call restart
scalb:  dec     hl
	dec     sp
	dec     sp
	push    af
	push    de
	ld      e,(hl)
	ld      d,0
scal2:	ld	hl,(_stab)
	add	hl,de
	add	hl,de
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ex	de,hl
	jr	rcal4

	; subroutine call
scalj:	push	hl
	push	af
	push	de
	ld      a,(argc)
	ld	e,a
	ld      d,0
	jr	scal2

	; keyboard table
ktab:	defb	0ffh,0ffh,0ffh,0ffh	; #00
	defb	0ffh,0ffh,0ffh,0ffh	; #04
	defb	008h,0ffh,08eh,0ffh	; #08 bs,lf
	defb	088h,009h,0ffh,0ffh	; #0c cs,cr
	defb	0ffh,03eh,02eh,046h	; #10 lru
	defb	036h,0beh,0aeh,00eh	; #14 dlr,ch
	defb	0ffh,0ffh,0ffh,089h	; #18 esc
	defb	0ffh,0ffh,0ffh,0ffh	; #1ch
	defb	014h,09ch,09bh,0a3h	; #20   "#
	defb	092h,0c2h,0bah,0b2h	; #24 $%&'
	defb	0aah,0a2h,098h,0a0h	; #28 ()*+
	defb	029h,00ah,021h,019h	; #2c ,-./
	defb	01ah,01ch,01bh,023h	; #30 0123
	defb	012h,042h,03ah,032h	; #34 4567
	defb	02ah,022h,018h,020h	; #38 89:;
	defb	0a9h,08ah,0a1h,099h	; #3c <=>?
	defb	00dh,02ch,041h,013h	; #40 @abc
	defb	03bh,033h,043h,010h	; #44 defg
	defb	040h,02dh,038h,030h	; #48 hijk
	defb	028h,031h,039h,025h	; #4c lmno
	defb	01dh,024h,015h,034h	; #50 pqrs
	defb	045h,035h,011h,02bh	; #54 tuvw
	defb	044h,03dh,03ch,01eh	; #58 xyz[
	defb	09eh,016h,09ah,096h	; #5c \]^_
ktabe:	equ	$

	; keyboard command
	; store k options
kop:	ld	a,l
	ld	(_kopt),a
	ret

	; bpt command
	; store btp address
break:	ld	(brkadr),hl
	ret

	; output comand
o:	ld	b,h
	ld	c,l
	out	(c),e
	ret

	; query command
q:	ld	b,h
	ld	c,l
	in	a,(c)
	rst     scal
	defb    zb2hex
	jp	crlf

	; get arguments
args:	ld	bc,(arg3)
	ld	de,(arg2)
	ld	hl,(arg1)
	ret

	; generate command
	; output commands to both
g:	ld	hl,outt2
	rst	scal
	defb	znom
	push	hl
	ld	hl,gds
	ld	b,gdse-gds
g2:	ld	a,(hl)
	rst	rout
	; wait
	ld	c,20
	xor	a
g4:	rst	rdel
	dec	c
	jr	nz,g4
	inc	hl
	djnz	g2
	; output the data
	rst	scal
	defb	"W"
	; wait
	xor	a
	rst	rdel
	; output "E"
	ld	a,"E"
	rst	rout
	; output execution address
	ld	hl,(arg3)
	rst	scal
	defb	ztbcd3
	ld	a,cr
	; final cr, end
	rst	rout
	pop	hl
	ld      (_out),hl
	ret

	; commands output by generate
gds:	defb	cr,"E","0",cr,"R",cr
gdse:	equ	$

	; string to serial output
	; hl = address
	; b = length
	; c = checksum
sout:	ld	c,0
so1:	ld	a,(hl)
	add	a,c
	ld      c,a
	ld      a,(hl)
	rst	scal
	defb	zsrlx
	inc     hl
	djnz	so1
	ret

	; read routine
read:	rst	scal
	defb	zmflp
	; normal tables
	rst	scal
	defb	znnom
	push	hl
	rst	scal
	defb	znnim
	push	hl
	; look for 4 0ffh chars
r1:	rst     rin
r1a:    cp      0ffh
	jr	nz,r1d
	ld      b,3
r1c:    rst     rin
	cp      0ffh
	jr      nz,r1d
	djnz	r1c
	jr      r3
	; look for 4 esc chars
r1d:    cp      esc
	jr      nz,r1
	ld      b,3
r1f:    rst     rin
	cp      esc
	jr      nz,r1a
	djnz    r1f
	; end, restore tables
r1w:	rst	prs
	defb	ccr,0
r1x:	pop	hl
	ld      (_in),hl
r1y:	pop	hl
	ld      (_out),hl
	jp	mflp
	; get header data
r3:	rst	rin
	ld	l,a
	rst	rin
	ld	h,a
	rst	rin
	ld	e,a
	rst	rin
	ld	d,a
	; display and check
	ld	c,0
	rst	scal
	defb	ztx1
	rst	rin
	cp	c
	jr	nz,r6
	; set b to length
	ld	b,e
	; load the data
	ld	c,0
r4:	ld	a,(argx)
	cp	"R"
	jr	z,r4a
	rst	rin
	jr	r4c
r4a:	rst	rin
	ld	(hl),a
r4c:	push	hl
	ld	hl,(cursor)
	ld	(hl),a
	pop	hl
	add	a,c
	ld	c,a
	inc	hl
	djnz	r4
	; check against checksum
	rst	rin
	cp	c
	jr	z,r7
	; error found
r6:	rst	prs
	defb	"?"," ",0
	jr	r1
	; cr, test for end
r7:	rst	prs
	defb	"."," ",0
	xor	a
	cp	d
	jr	nz,r1
	jr	r1w

	; user i/o command
up:	ld	hl,intu
	rst	scal
	defb	znim
	ld	hl,outtu
	rst	scal
	defb	znom
	ret

	; external (x) command
xp:	ld	a,l
	ld	(_xopt),a
	ld	hl,intx
	rst	scal
	defb	znim
	ld	hl,outtx
	rst	scal
	defb	znom
	ret

	; x input routine
	; check for input
xkbd:	rst	scal
	defb	zsrlin
	ret	nc
	; strip parity
	and	7fh
	push    af
	; if full duplex, send back
	ld	hl,_xopt
	bit	5,(hl)
	call	z,xsopo
	rst     rcal
	defb    xsopl-$-1
	pop     af
	; if del, make null
	cp      del
	jr      nz,xk2
	xor     a
	; if escape or now null,
	;   assume program will not
	;   output the char
xk2:    cp      esc
	jr      z,xk4
	or	a
	jr	z,xk4
	set	7,(hl)
xk4:	scf
	ret

	; x output routine
xout:	push	af
	;  output unless bit 7 set
	;  to suppress serial output
	ld	hl,_xopt
	bit	7,(hl)
	call	z,xsop
	; turn on suppression
	res	7,(hl)
	pop	af
	ret

	; output char and lf
xsop:	rst	rcal
	defb	xsopo-$-1
	; if it was a cr and bit 4
	;  of $xopt = 0, output lf
xsopl:	cp	cr
	ret	nz
	bit	4,(hl)
	ret	nz
	ld	a,lf
	; output ascii char
	; set parity etc
xsopo:	or	a
	; ignore nulls
	ret     z
xsopc:  push	af
	; make parity even
	jp	pe,xsop2
	xor	80h
	; if bit 0 set, make it odd
xsop2:	bit	0,(hl)
	jr	z,xsop4
	xor	80h
	; output it
xsop4:	rst     scal
	defb    zsrlx
	; restore original value
	pop	af
	ret

	; terminal program
xn:	rst	scal
	defb    zblink
	rst     rout
	jr	xn

	; make $in and $out normal
normal:	rst	scal
	defb	znnim

	; set new output table
nnom:	ld	hl,outt1
nom:	push	hl
	ld	hl,(_out)
	ex	(sp),hl
	ld	(_out),hl
	pop	hl
	ret

	; set new input table
nnim:	ld	hl,int1
nim:	push	hl
	ld	hl,(_in)
	ex	(sp),hl
	ld	(_in),hl
	pop	hl
	ret

	; address table execution
in:	push	hl
	ld	hl,_in
	jr	ate
aout:	ld	hl,_out
	; get start of tbale
ate:	push	de
	push	bc
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	; get routine number
at4:	push	af
	ld	a,(de)
	inc	de
	; check for end
	or	a
	jr	z,at6
	ld	(argc),a
	pop	af
	; call routine
	push	de
	or	a
	call	scalj
	pop	de
	jr	nc,at4
	push	af
at6:	pop	af
	pop	bc
	pop	de
	pop	hl
	ret

	; output tables
outt2:	defb	zcrt
outt3:  defb	zsrlx
	defb	0
outtx:	defb	zxout
outtu:	defb	zuout
outt1:	defb	zcrt
	defb	0

	; input tables
intu:	defb	zuin
int1:	defb	zkbd
	defb	zsrlin
	defb	0
intx:	defb	zxkbd
	defb	zkbd
	defb	0
	; subroutine table
	; starts with "A"
staba:	defw	arith
	defw	break
	defw	copy
	defw	errm
	defw	exec
	defw	errm
	defw	g
	defw	xn
	defw	icopy
	defw	bprc
	defw	kop
	defw	load
	defw	modify
	defw	normal
	defw	o
	defw	errm
	defw	q
	defw	read
	defw	step
	defw	tabcde
	defw	up
	defw	read
	defw	write
	defw	xp
	defw	errm
	defw	bprw
	defw	mret	; 5bh
	defw	scalj	; 5ch
	defw	tdel	; 5dh
	defw	fflp	; 5eh
	defw	mflp	; 5fh
	defw	args	; 60h
	defw	kbd	; 61h
	defw	in	; 62h
	defw	inlin	; 63h
	defw	num	; 64h
	defw	crt	; 65h
	defw	tbcd3	; 66h
	defw	tbcd2	; 67h
	defw	b2hex	; 68h
	defw	space	; 69h
	defw	crlf	; 6ah
	defw	errm	; 6bh
	defw	tx1	; 6ch
	defw	sout	; 6dh
	defw	xout	; 6eh
	defw	srlx	; 6fh
	defw	srlin	; 70h
	defw	nom	; 71h
	defw	nim	; 72h
	defw	ate	; 73h
	defw	xkbd	; 74h
	defw	_uout	; 75h
	defw	_uin	; 76h
	defw	nnom	; 77h
	defw	nnim	; 78h
	defw	rlin	; 79h
	defw	b1hex	; 7ah
	defw	blink	; 7bh
	defw	cpos	; 7ch

	; subroutine call table
zmret:	equ	5bh
zscalj:	equ	5ch
ztdel:	equ	5dh
zfflp:	equ	5eh
zmflp:	equ	5fh
zargs:	equ	60h
zkbd:	equ	61h
zin:	equ	62h
zinlin:	equ	63h
znum:	equ	64h
zcrt:	equ	65h
ztbcd3:	equ	66h
ztbcd2:	equ	67h
zb2hex:	equ	68h
zspace:	equ	69h
zcrlf:	equ	6ah
zerrm:	equ	6bh
ztx1:	equ	6ch
zsout:	equ	6dh
zxout:	equ	6eh
zsrlx:	equ	6fh
zsrlin:	equ	70h
znom:	equ	71h
znim:	equ	72h
zate:	equ	73h
zxkbd:	equ	74h
zuout:	equ	75h
zuin:	equ	76h
znnom:	equ	77h
znnim:	equ	78h
zrlin:	equ	79h
zb1hex:	equ	7ah
zblink:	equ	7bh
zcpos:	equ	7ch

	; spare
	; --- none ---
nend:	equ	$

	; workspace
	;  initialised to 0
	org	ram
initz:	equ	$
	; copy of port 0
port0:	defs	1
	; keyboard status map
kmap:	defs	9
	; command char
argc:	defs	1
	; no of args
argn:	defs	1
	; up to 10 args
arg1:	defs	2
arg2:	defs	2
arg3:	defs	2
arg49:	defs	12
arg10:	defs	2
	; no of chars in hex value
numn:	defs	1
	; hex value entered
numv:	defs	2
	; bpt address
brkadr:	defs	2
	; bpt value
brkval:	defs	1
	; conflg not 0 if e command
conflg:	defs	1
	; k option
_kopt:	defs	1
	; x option
_xopt:	defs	1
	; cursor position
cursor:	defs	2
	; last command
argx:	defs	1
	; monitor stack
monstk:	defs	035h
stack:	equ	$
	; register save area
rbc:	defs	2
rde:	defs	2
rhl:	defs	2
raf:	defs	2
rpc:	defs	2

	; workspace
	;  initialised by table
initr:	equ	$
	; user sp
rsp:	defs	2
	; end of reg save area
rsae:   equ     $
	; length of ktab
_ktabl:	defs	2
	; address of end of ktab
_ktab:	defs	2
	; address of stab
_stab:	defs	2
	; output table
_out:	defs	2
	; input table
_in:	defs	2
	; user jumps
_uout:	defs	3
_uin:	defs	3
	; nmi jump
_nmi:	defs	3

	; end of workspace
inite:	equ	$

	; end of listing
	end
