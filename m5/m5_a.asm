        ;; SOP:    equ $efe
        ;; SOPM1:  equ SOP-1

        org $0C50

;;; ========================================================
;;; M5 Interpreter for NASCOM
;;;
;;; User program is stored starting at SOP ($efe) and is
;;; terminated with two bytes of 0. In the code, the address
;;; SOP-1 is loaded in multiple places, because it is
;;; incremented before use. I defined name SOPM1 for
;;; this address ($efd). A little rearrangement would
;;; allow SOP to be used consistently in the code, which
;;; would make the code clearer.
;;;
;;; There are 27 16-bit variables, named @ and A-Z which
;;; are accessed based on their ASCII codes $40-$5a
;;; respectively.
;;;
;;; Variables are stored starting at $bc0
;;; which is the top (non-scrolled) line of the memory
;;; -mapped display, which means that they are visible
;;; before and after the program is running!
;;;
;;; The editor does direct read/write to 1 location at
;;; the right-hand side of the top (non-scrolled) line
;;; of the memory-mapped display: location $bf6
;;;
;;; Within the program, register assignment is as
;;; follows:
;;;
;;; DE  -- stores the current value, 'x'.
;;; IX  -- during program execution, stores the address
;;;        of the program symol currently being executed.
;;; SP  -- the system stack holds values stacked by the
;;;        user program (pop returns 'y').
;;;
;;; memory scratch: none
;;;
;;; ========================================================

;;; Non-printable codes (non-standard for T4)
CHR_CR: equ $1f
CHR_BS: equ $1d

;;; T4 i/o calls
RST_PRS:equ $28
INCH:   equ $003E
OUTCH:  equ $013B

;;; A specifies a variable. $40 is @, $41 is A.. $5A is Z.
;;; fetch value of referenced variable into DE ('x')
GETVAR: sub '?'                 ;convert @->1, A->2.. Z->27
        call VARADR
        ld e, (hl)
        inc hl
        ld d, (hl)
        jr NEXT

;;; Symbol: - -- subtract: x:=x - TOS
SUB:    pop hl
        sbc hl, de
        ex de, hl
        jr NEXT

;;; Program entry point
ENTRY:  jp MONITOR

;;; Symbol: ? -- prompt with ? and get numeric input from user into x (DE)
NUMIN:  rst RST_PRS
        defm "?"
        defb $00
        ld hl, $0000
NUMI1:  call ECHO
        call XXXNUM
        jr c, NUMI1
        ex de, hl
        jr NEXT

;;; Symbol: display value of x (DE) in decimal
NUMOUT: ld h, d
        ld l, e
        ld iy, NUMTAB
NUMO1:  xor a
        ld b, (iy+$01)
        ld c, (iy+$00)
NUMO2:  sbc hl, bc
        jr c, NUMO3
        inc a
        jr NUMO2
NUMO3:  add hl, bc
        add a, $30
        call OUTCH
        inc iy
        inc iy
        dec c
        jr nz, NUMO1

;;; fall through or end up here to point to next symbol..
NEXT:   inc ix

;;; ..and process it
SYMBOL: ld a, (ix+$00)
        cp ' '
        jr z, NEXT
        cp CHR_CR
        jr z, NEXT
        cp '?'
        jr z, NUMIN
        jr nc, GETVAR
        cp ','
        jr z, STAKIT
        cp '='
        jr z, ASSIGN
        cp ')'
        jp z, BRACHK
        cp '#'
        jr z, DEC
        cp '&'
        jr z, INC
        cp '+'
        jr z, ADD
        cp '-'
        jr z, SUB
        cp '*'
        jr z, MUL
        cp '/'
        jr z, DIV
        cp '('
        jr z, LABEL
        cp '"'                  ; "
        jr z, STRING
        or a
        jp z, MONITOR
        jp WHAT

;;; Symbol: , -- push x onto stack
STAKIT: push de
        jr NEXT

;;; Symbol: ( -- label. Just step past the label identifier
;;; TODO optimisation: could this be merged with FALSE?
LABEL:  inc ix
        jr NEXT

;;; Symbol: = -- assign or =? -- print number
ASSIGN: inc ix
        ld a, (ix+$00)
        sub '?'
        jr z, NUMOUT
        jp c, ID
        call VARADR
        ld (hl), e
        inc hl
        ld (hl), d
        jr NEXT

;;; Symbol: + -- add: x:=x + TOS
ADD:    pop hl
        add hl, de
        ex de, hl
        jr NEXT

;;; Symbol: % -- increment: x:=x + 1
INC:    inc de
        jr NEXT

;;; Symbol: £ -- decrement: x:=x - 1
DEC:    dec de
        jr NEXT

;;; Symbol: * -- multiply: x:=x * TOS, @:=overflow
MUL:    pop bc
        ld a, $10
        ld hl, $0000
MUL1:   bit 7, d
        jr z, MUL2
        add hl, bc
        jr nc, MUL2
        inc de
MUL2:   dec a
        jr z, MUL3
        ex de, hl
        add hl, hl
        ex de, hl
        add hl, hl
        jr nc, MUL1
        inc de
        jr MUL1
MUL3:   ex de, hl

;;; Store in variable @
STOREAT:ld ($0BC0), hl
        jp NEXT

;;; Symbol: / -- divide: x:=x / TOS, @:=remainder
DIV:    ld b, d
        ld c, e
        ld hl, $0000
        pop de
DIV1:   ld a, $10
DIV2:   add hl, hl
        ex de, hl
        add hl, hl
        ex de, hl
        jr nc, DIV3
        inc hl
        or a
DIV3:   sbc hl, bc
        inc de
        jp p, DIV4
        add hl, bc
        res 0, e
DIV4:   dec a
        jr nz, DIV2
        jr STOREAT


STRING: inc ix
        ld a, (ix+$00)
        cp '"'                  ;"
        jp z, NEXT
        or a
        jp z, MONITOR
        call OUTCH
        jr STRING

;;; Either a variable @, A-Z or an unknown symbol (in which case, error)
WHAT:   sub $30
        cp $0A
        jr nc, ERRSYM

;;; Convert/accumulate inline number from ASCII string into x (DE) -- like NUMIN
        ld hl, $0000

L_0D5D: ld a, (ix+$00)
        inc ix
        call XXXNUM
        jr c, L_0D5D
        ex de, hl
        dec ix
        jp SYMBOL


ERRSYM: rst RST_PRS
        defm "SYM"
        defb $00
        jr ERROR

;;; Symbol: ) -- branch. Check condition
;;; 8 conditions are:  Nonzero Uncon Zero Equal Xoteq Lessoreq Greatoreq Monitor
;;; TODO would save 2 bytes to move the inc ix from the end to here: then remove one inc ix each from NOBRA and BRA
BRACHK: ld a, (ix+$01)
        cp 'N'
        jr z, NONZER
        cp 'U'
        jr z, BRA
        cp 'Z'
        jr z, ZERO
        ex af, af'
        pop hl
        push hl
        or a
        sbc hl, de
        ex af, af'
        cp 'E'
        jr z, EQUAL
        cp 'X'
        jr z, NOTEQU
        cp 'L'
        jr z, LESEQU
        cp 'G'
        jr z, GRTEQU
        cp 'M'
        jp z, MONITOR
        rst RST_PRS
        defm "J"
        defb $00
        inc ix
        jr ERROR

;;; Branch if x (in DE) is 0
ZERO:   ld a, d
        or e

BRAIFZ: jr z, BRA
        jr NOBRA

;;; Branch if x (in DE) is non-0
NONZER: ld a, d
        or e

BRAIFNZ:jr nz, BRA
        jr NOBRA


EQUAL:  ex af, af'
        jr BRAIFZ

NOTEQU: ex af, af'
        jr BRAIFNZ

;;; TODO ?? what's going on here with the dec/inc
LESEQU: ex af, af'
        jr nc, BRA
        dec de
        inc bc

GRTEQU: ex af, af'
        jr c, BRA

;;; not-taken branch. Skip past brace and condition: point to jump symbol, then continue
NOBRA:  inc ix
        inc ix
        jp NEXT

ID:     rst RST_PRS
        defm "ID"
        defb $00

ERROR:  rst RST_PRS
        defm " ERR "
        defb $00
        ld a, (ix+$00)
        call OUTCH
        jr MONITOR

;;; Come here for unconditional Branch and for taken conditional branch.
;;; Notation:   (n   )km
;;; ( = label marker
;;; n = label symbol
;;; ) = branch marker
;;; k = branch condition
;;; m = destination symbol
;;; Search for destination: first, search for label marker, then see if label symbol matches
;;; destination symbol.

;;; at 0ddd 31 fa 0f correct? LD SP, $0FFA -- cannot be correct: it would clear the user stack
;;; but neither B1 nor 81 would work here, and code looks good without this instruction.

;;; TODO bug: when BRALAB does not match the destination symbol it branches back to BRA1. However,
;;; HL is still pointing to the destination symbol that was checked. At BRA1 it gets tested to see
;;; if it is a label marker. Therefore, if you had a label (( and it's not the first label in
;;; the program the second ( will get treated as the label marker and the next symbol treated as the
;;; label symbol. It's trivial to fix: change JP NZ below to JR to save 1 byte. In BRA1 move INC HL
;;; to after the OR and label it BRA2. In BRALAB, insert INC HL and change the branch destination to BRA2.
BRA:    ld c, (ix+$02)
        ld sp, $0FFA
        ld hl, SOP
        ld b, '('

BRA1:   ld a, (hl)
        inc hl
        cp b
        jr z, BRALAB
        or a
        jp nz, BRA1

;;; found 0 (end of program) without finding branch destination. Skip past branch marker
;;; and condition; point to destination symbol, then report error
        inc ix
        inc ix
        rst RST_PRS
        defm "J"
        defb $00
        jr ID


;;; found label symbol. Does the destination symbol match?
BRALAB: ld a, (hl)
        cp c
        jr nz, BRA1

;;; yes, found match. Point IX to the label symbol then continue with next symbol
        push hl
        pop ix

NEXTI:  jp NEXT

;;; A indicates a variable; 1 -> @, 2 -> A, 3 -> B, 27 -> Z
;;; double it (16-bit variables) then add to variables start address - 2 ($bbe)
;;; to get address of storage. Would have been cleaner to index this from 0!!
VARADR: rlca
        ld c, a
        ld b, $00
        ld hl, $0BBE
        add hl, bc
        ret

;;; Look-up table for hex->decimal conversion
;;; 1, 16-bit value for each of the 5 decimal output digits
NUMTAB: defw 10000, 1000, 100, 10, 1

;;; TODO ??? Return C if ASCII in A is non-numeric, otherwise
;;; multiply HL by 10 and add in value from A
XXXNUM: sub $30
        cp $0A
        ret nc
        add hl, hl
        ld d, h
        ld e, l
        add hl, hl
        add hl, hl
        add hl, de
        ld e, a
        ld d, $00
        add hl, de
        scf
        ret

;;; Get input character, echo it and return it in A
ECHO:   call INCH
        jp OUTCH

;;; List command: display until end-of-program (indicated by 0)
;;; also, called as a subroutine from Edit loop.
LIST:   rst RST_PRS
        defb CHR_CR, $00
        ld hl, SOPM1
LIST1:  inc hl
        ld a, (hl)
        or a
        ret z
        call OUTCH
        jr LIST1


;;; Mark end of program at HL: two bytes of 0.
;;; TODO is the 2nd 0 necessary?? -- there might be some scenario where
;;; you incorrectly end a program with a ) maybe a label search would not stop??
MARKEOP:xor a
        ld (hl), a
        inc hl
        ld (hl), a

;;; Command loop
;;; TODO it would be tidier and same code size to avoid the double fall-through
MONITOR:rst RST_PRS
        defb CHR_CR
        defm "M5:"
        defb $00
        call ECHO
        cp 'L'
        call z, LIST
        cp 'I'
        jp z, INPUT
        cp 'R'
        jr nz, NOTRUN
;;; fall-through to Run command: CR then start executing symbols at SOP
        rst RST_PRS
        defb CHR_CR, $00
        ld ix, SOPM1
        jr NEXTI

NOTRUN: cp 'E'
        jr nz, MONITOR
;;; fall-through to Edit command
        push ix
        pop hl

EDIT:   ld c, (hl)
        ld (hl), $7F
        push hl
        ld a, c
        ld ($0BF6), a
        call LIST
        pop hl
        ld (hl), c
        rst RST_PRS
        defb CHR_CR
        defm "E:"
        defb $00

EDLOP1: call ECHO
        cp $44
        jr z, DELETE
        cp CHR_CR
        jr z, EDIT
        cp '>'
        jr nz, NOTRT
;;; > (right) sub-command of Edit command
        inc hl

NOTRT:  cp '<'
        jr nz, EDLOP2
;;; < (left) sub-command of Edit command
        dec hl

EDLOP2: cp 'R'
        jr z, REWIND
        cp 'N'
        jr z, NEXTLN
        cp 'W'
        jr z, MONITOR
        cp 'I'
        jr nz, EDLOP1

EDLOP3: call ECHO
        cp ';'
        jr z, EDLOP1
        push hl

EDLOP4: ld c, (hl)
        ld (hl), a
        inc hl
        ld a, c
        or a
        jr nz, EDLOP4
        ld (hl), a
        inc hl
        ld (hl), a
        pop hl
        inc hl
        jr EDLOP3

;;; Rewind sub-command of Edit command
;;; TODO the coding here is perverse! Loading with SOP+1 then decrementing! And can all be
;;; eliminated by jumping to the start of the edit command.. save 6 bytes
REWIND: ld hl, $0EFF
        dec hl
        jr EDLOP1

;;; Delete sub-command of Edit command
;;; copy the program back by 1 byte; loop until end of program marker copied
DELETE: push hl
        pop ix
;;; GNU assembler bugs:
;;; ld a, (ix)
;;; ^-- without the +NN, fails; reported as "unable to resolve reference: sp"
;;; ld (ix+$00), a
;;; ^-- without the +NN silently fails; doesn't generate an offset byte, so the generated code is WRONG!!
DEL1:   ld a, (ix+$01)
        ld (ix+$00), a
        or a
        jr z, EDLOP1
        inc ix
        jr DEL1

;;; NextLine sub-command of Edit command
;;; advance pointer past next newline, or stop at end
NEXTLN: ld a, (hl)
        or a
        jr z, EDLOP1
        inc hl
        cp CHR_CR
        jr nz, NEXTLN
        jr EDLOP1

;;; Input command: message, CR then get/store user program
INPUT:  rst RST_PRS
        defm "nput"
        defb CHR_CR, $00
        ld hl, SOPM1

INOK:   inc hl

INBAK:  call ECHO
        cp ';'
        jp z, MARKEOP
        ld (hl), a
        cp CHR_BS
        jr nz, INOK
        dec hl
        jr INBAK

        ; Start of unknown area $0EEE to $0EEE
        defb $D4
        ; End of unknown area $0EEE to $0EEE


        org $0EFE
SOP:    equ $
SOPM1:  equ SOP-1

