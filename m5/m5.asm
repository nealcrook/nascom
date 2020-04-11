L_003E  equ $003E
L_013B  equ $013B

        org $0028


L_0028:
        ret


        org $0C50

;;; ========================================================
;;; M5 Interpreter for NASCOM
;;; Uses these calls into NASBUG T2 monitor:
;;; RST $28   -- print in-line string; string is terminated by 00.
;;; CALL $13b -- print character in A.
;;; CALL $3e  -- wait for input character, return it in A.
;;;
;;; It is a peculiarity of T2 that it uses non-standard
;;; codes instead of ASCII for some operations:
;;; $1f for carriage-return
;;; $1d for backspace
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
;;; memory scratch ?? none??
;;;
;;; ========================================================


;;; A specifies a variable. $40 is @, $41 is A.. $5A is Z.
;;; fetch value of referenced variable into DE ('x')

GETVAR:
        sub $3F
        call VARADR
        ld e, (hl)
        inc hl
        ld d, (hl)
        jr NEXT

;;; Symbol: - -- subtract: x:=x - TOS

SUB:
        pop hl
        sbc hl, de
        ex de, hl
        jr NEXT

;;; Program entry point

ENTRY:
        jp MONITOR

;;; Symbol: ? -- prompt with ? and get numeric input from user into x (DE)

NUMIN:
        rst $28
        defm "?"
        defb $00
        ld hl, $0000

NUMI1:
        call ECHO
        call XXXNUM
        jr c, NUMI1
        ex de, hl
        jr NEXT

;;; Symbol: display value of x (DE) in decimal

NUMOUT:
        ld h, d
        ld l, e
        ld iy, NUMTAB

NUMO1:
        xor a
        ld b, (iy+$01)
        ld c, (iy)

NUMO2:
        sbc hl, bc
        jr c, NUMO3
        inc a
        jr NUMO2


NUMO3:
        add hl, bc
        add a, $30
        call L_013B
        inc iy
        inc iy
        dec c
        jr nz, NUMO1

;;; fall through or end up here to point to next symbol..

NEXT:
        inc ix

;;; ..and process it

SYMBOL:
        ld a, (ix)
        cp $20
        jr z, NEXT
        cp $1F
        jr z, NEXT
        cp $3F
        jr z, NUMIN
        jr nc, GETVAR
        cp $2C
        jr z, STAKIT
        cp $3D
        jr z, ASSIGN
        cp $29
        jp z, BRACHK
        cp $23
        jr z, DEC
        cp $26
        jr z, INC
        cp $2B
        jr z, ADD
        cp $2D
        jr z, SUB
        cp $2A
        jr z, MUL
        cp $2F
        jr z, DIV
        cp $28
        jr z, LABEL
        cp $22
        jr z, STRING
        or a
        jp z, MONITOR
        jp WHAT

;;; Symbol: , -- push x onto stack

STAKIT:
        push de
        jr NEXT

;;; Symbol: ( -- label. Just step past the label identifier
;;; TODO optimisation: could this be merged with FALSE?

LABEL:
        inc ix
        jr NEXT

;;; Symbol: = -- assign or =? -- print number

ASSIGN:
        inc ix
        ld a, (ix)
        sub $3F
        jr z, NUMOUT
        jp c, ID
        call VARADR
        ld (hl), e
        dec hl
        ld (hl), d
        jr NEXT

;;; Symbol: + -- add: x:=x + TOS

ADD:
        pop hl
        add hl, de
        ex de, hl
        jr NEXT

;;; Symbol: % -- increment: x:=x + 1

INC:
        inc de
        jr NEXT

;;; Symbol: £ -- decrement: x:=x - 1

DEC:
        dec de
        jr NEXT

;;; Symbol: * -- multiply: x:=x * TOS, @:=overflow

MUL:
        pop bc
        ld a, $10
        ld hl, $0000

MUL1:
        bit 7, d
        jr z, MUL2
        add hl, bc
        jr nc, MUL2
        inc de

MUL2:
        dec a
        jr z, MUL3
        ex de, hl
        add hl, hl
        ex de, hl
        add hl, hl
        jr nc, MUL1
        inc de
        jr MUL1


MUL3:
        ex de, hl

;;; Store in variable @

STORAT:
        ld ($0BC0), hl
        jp NEXT

;;; Symbol: / -- divide: x:=x / TOS, @:=remainder

DIV:
        ld b, d
        ld c, e
        ld hl, $0000
        pop de

DIV1:
        ld a, $10

DIV2:
        add hl, hl
        ex de, hl
        add hl, hl
        ex de, hl
        jr nc, DIV3
        inc hl
        or a

DIV3:
        sbc hl, bc
        inc de
        jp p, DIV4
        add hl, bc
        res 0, e

DIV4:
        dec a
        jr nz, DIV2
        jr STORAT


STRING:
        inc ix
        ld a, (ix)
        cp $22
        jp z, NEXT
        or a
        jp z, MONITOR
        call L_013B
        jr STRING

;;; Either a variable @, A-Z or an unknown symbol (in which case, error)

WHAT:
        sub $30
        cp $0A
        jr nc, ERRSYM
        ld hl, $0000

;;; TODO ?? what's going on here? fetch and convert inline number

L_0D5D:
        ld a, (ix)
        inc ix
        call XXXNUM
        jr c, L_0D5D
        ex de, hl
        dec ix
        jp SYMBOL


ERRSYM:
        rst $28
        defm "SYM"
        defb $00
        jr ERROR

;;; Symbol: ) -- branch. Check condition
;;; 8 conditions are:  Nonzero Uncon Zero Equal Xoteq Lessoreq Greatoreq Monitor
;;; TODO would save 2 bytes to move the inc ix from the end to here: then remove one inc ix each from NOBRA and BRA

BRACHK:
        ld a, (ix+$01)
        cp $4E
        jr z, NONZER
        cp $55
        jr z, BRA
        cp $5A
        jr z, ZERO
        ex af, af'
        pop hl
        push hl
        or a
        sbc hl, de
        ex af, af'
        cp $45
        jr z, EQUAL
        cp $58
        jr z, NOTEQU
        cp $4C
        jr z, LESEQU
        cp $47
        jr z, GRTEQU
        cp $4D
        jp z, MONITOR
        rst $28
        defm "J"
        defb $00
        inc ix
        jr ERROR


ZERO:
        ld a, d
        or e

L_0DA8:
        jr z, BRA
        jr NOBRA


NONZER:
        ld a, d
        or e

L_0DAE:
        jr nz, BRA
        jr NOBRA


EQUAL:
        ex af, af'
        jr L_0DA8


NOTEQU:
        ex af, af'
        jr L_0DAE

;;; TODO ?? what's going on here with the dec/inc

LESEQU:
        ex af, af'
        jr nc, BRA
        dec de
        inc bc

GRTEQU:
        ex af, af'
        jr c, BRA

;;; not-taken branch. Skip past brace and condition: point to jump symbol, then continue

NOBRA:
        inc ix
        inc ix
        jp NEXT


ID:
        rst $28
        defm "ID"
        defb $00

ERROR:
        rst $28
        defm " ERR "
        defb $00
        ld a, (ix)
        call L_013B

UNCOND:
        jr MONITOR


;;; taken branch. Search for destination
;;; at 0ddd 31 fa 0f correct? LD SP, $0FFA -- cannot be correct: it would clear the user stack
;;; but neither B1 nor 81 would work here, and code looks good without this instruction.
;;; first, search for ( $28 to indicate a label, then check the jump symbol to see if it's the one we want
;;; TODO bug: if you use a label like this: (( and it's not the first label a branch from BRALAB to BRA1 will
;;; load and check the second ) instead of stepping past it. Trivial to fix.

BRA:
        ld c, (ix+$02)
        ld sp, $0FFA
        ld hl, SOP
        ld b, $28

BRA1:
        ld a, (hl)
        inc hl
        cp b
        jr z, BRALAB
        or a
        jp nz, BRA1

;;; found 0 (end of program) without finding branch destination. Skip past brace and
;;; condition: point to jump symbol, then report error
        inc ix
        inc ix
        rst $28
        defm "J"
        defb $00
        jr ID


;;; found branch label. Does the destination symbol match?

BRALAB:
        ld a, (hl)
        cp c
        jr nz, BRA1

;;; yes, found match. Move symbol address to IX then continue with next symbol
        push hl
        pop ix

NEXTI:
        jp NEXT

;;; A indicates a variable; 1 -> @, 2 -> A, 3 -> B, 27 -> Z
;;; double it (16-bit variables) then add to variables start address - 2 ($bbe)
;;; to get address of storage. Would have been cleaner to index this from 0!!

VARADR:
        rlca
        ld c, a
        ld b, $00
        ld hl, $0BBE
        add hl, bc
        ret

;;; Look-up table for hex->decimal conversion
;;; 1, 16-bit value for each of the 5 decimal output digits
;;; in decimal, values are: 10000, 1000, 100, 10, 1

NUMTAB:
        defw $2710, $03E8, $0064, $000A, $0001

;;; TODO ??? Return C if ASCII in A is non-numeric, otherwise
;;; multiply HL by 10 and add in value from A

XXXNUM:
        sub $30
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

ECHO:
        call L_003E
        jp L_013B

;;; List command: display until end-of-program (indicated by 0)
;;; also, called as a subroutine from Edit loop.

LIST:
        rst $28
        defb $1F, $00
        ld hl, SOPM1

LIST1:
        inc hl
        ld a, (hl)
        or a
        ret z
        call L_013B
        jr LIST1


;;; Mark end of program at HL: two bytes of 0.
;;; TODO is the 2nd 0 necessary?? -- there might be some scenario where
;;; you incorrectly end a program with a ) maybe a label search would not stop??

MARKEOP:
        xor a
        ld (hl), a
        inc hl
        ld (hl), a

;;; Command loop
;;; TODO it would be tidier and same code size to avoid the double fall-through

MONITOR:
        rst $28
        defb $1F
        defm "M5:"
        defb $00
        call ECHO
        cp $4C
        call z, LIST
        cp $49
        jp z, INPUT
        cp $52
        jr nz, NOTRUN
;;; fall-through to Run command: CR then start executing symbols at SOP
        rst $28
        defb $1F, $00
        ld ix, SOPM1
        jr NEXTI


NOTRUN:
        cp $45
        jr nz, MONITOR
;;; fall-through to Edit command
        push ix
        pop hl

EDIT:
        ld c, (hl)
        ld (hl), $7F
        push hl
        ld a, c
        ld ($0BF6), a
        call LIST
        pop hl
        ld (hl), c
        rst $28
        defb $1F
        defm "E:"
        defb $00

EDLOP1:
        call ECHO
        cp $44
        jr z, DELETE
        cp $1F
        jr z, EDIT
        cp $3E
        jr nz, NOTRT
;;; > (right) sub-command of Edit command
        inc hl

NOTRT:
        cp $3C
        jr nz, EDLOP2
;;; < (left) sub-command of Edit command
        dec hl

EDLOP2:
        cp $52
        jr z, REWIND
        cp $4E
        jr z, NEXTLN
        cp $57
        jr z, MONITOR
        cp $49
        jr nz, EDLOP1

EDLOP3:
        call ECHO
        cp $3B
        jr z, EDLOP1
        push hl

EDLOP4:
        ld c, (hl)
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

REWIND:
        ld hl, $0EFF
        dec hl
        jr EDLOP1

;;; Delete sub-command of Edit command
;;; copy the program back by 1 byte; loop until end of program marker copied

DELETE:
        push hl
        pop ix

DEL1:
        ld a, (ix+$01)
        ld (ix), a
        or a
        jr z, EDLOP1
        inc ix
        jr DEL1

;;; NextLine sub-command of Edit command
;;; advance pointer past next newline, or stop at end

NEXTLN:
        ld a, (hl)
        or a
        jr z, EDLOP1
        inc hl
        cp $1F
        jr nz, NEXTLN
        jr EDLOP1

;;; Input command: message, CR then get/store user program

INPUT:
        rst $28
        defm "nput"
        defb $1F, $00
        ld hl, SOPM1

INOK:
        inc hl

INBAK:
        call ECHO
        cp $3B
        jp z, MARKEOP
        ld (hl), a
        cp $1D
        jr nz, INOK
        dec hl
        jr INBAK


        ; Start of unknown area $0EEE to $0EEE
        defb $D4
        ; End of unknown area $0EEE to $0EEE


        org $0EFD


SOPM1:
        defb $00

SOP:
        defb $00



; $0C50 CCCCCCCCCCCCCCCCCCCCBBCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0C80 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0CD0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0D20 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBB
; $0D70 BBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0DC0 CCCCCCCCBBBCBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBCCCCCCCCCCCCCCCCCCCCCWWWWWW
; $0E10 WWWWCCCCCCCCCCCCCCCCCCCCCCCCBBCCCCCCCCCCCCCCCCCBBBBBCCCCCCCCCCCCCCCCCCBBCCCCCCCC
; $0E60 CCCCCCCCCCCCCCCCCCCBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $0EB0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBBBCCCCCCCCCCCCCCCCCCCC

; $0EFD B

; Labels
;
; $0028 => L_0028         ADD     => $0CF7
; $003E => L_003E         ASSIGN  => $0CE3
; $013B => L_013B         BRA     => $0DDA
; $0C50 => GETVAR         BRA1    => $0DE5
; $0C5A => SUB            BRACHK  => $0D74
; $0C60 => ENTRY          BRALAB  => $0DF7
; $0C63 => NUMIN          DEC     => $0CFF
; $0C69 => NUMI1          DEL1    => $0EBB
; $0C74 => NUMOUT         DELETE  => $0EB8
; $0C7A => NUMO1          DIV     => $0D23
; $0C81 => NUMO2          DIV1    => $0D29
; $0C88 => NUMO3          DIV2    => $0D2B
; $0C95 => NEXT           DIV3    => $0D33
; $0C97 => SYMBOL         DIV4    => $0D3C
; $0CDC => STAKIT         ECHO    => $0E25
; $0CDF => LABEL          EDIT    => $0E65
; $0CE3 => ASSIGN         EDLOP1  => $0E77
; $0CF7 => ADD            EDLOP2  => $0E8C
; $0CFC => INC            EDLOP3  => $0E9C
; $0CFF => DEC            EDLOP4  => $0EA4
; $0D02 => MUL            ENTRY   => $0C60
; $0D08 => MUL1           EQUAL   => $0DB2
; $0D10 => MUL2           ERROR   => $0DCB
; $0D1C => MUL3           ERRSYM  => $0D6D
; $0D1D => STORAT         GETVAR  => $0C50
; $0D23 => DIV            GRTEQU  => $0DBD
; $0D29 => DIV1           ID      => $0DC7
; $0D2B => DIV2           INBAK   => $0EDE
; $0D33 => DIV3           INC     => $0CFC
; $0D3C => DIV4           INOK    => $0EDD
; $0D41 => STRING         INPUT   => $0ED3
; $0D54 => WHAT           L_0028  => $0028
; $0D5D => L_0D5D         L_003E  => $003E
; $0D6D => ERRSYM         L_013B  => $013B
; $0D74 => BRACHK         L_0D5D  => $0D5D
; $0DA6 => ZERO           L_0DA8  => $0DA8
; $0DA8 => L_0DA8         L_0DAE  => $0DAE
; $0DAC => NONZER         LABEL   => $0CDF
; $0DAE => L_0DAE         LESEQU  => $0DB8
; $0DB2 => EQUAL          LIST    => $0E2B
; $0DB5 => NOTEQU         LIST1   => $0E31
; $0DB8 => LESEQU         MARKEOP => $0E3A
; $0DBD => GRTEQU         MONITOR => $0E3E
; $0DC0 => NOBRA          MUL     => $0D02
; $0DC7 => ID             MUL1    => $0D08
; $0DCB => ERROR          MUL2    => $0D10
; $0DD8 => UNCOND         MUL3    => $0D1C
; $0DDA => BRA            NEXT    => $0C95
; $0DE5 => BRA1           NEXTI   => $0DFE
; $0DF7 => BRALAB         NEXTLN  => $0EC8
; $0DFE => NEXTI          NOBRA   => $0DC0
; $0E01 => VARADR         NONZER  => $0DAC
; $0E0A => NUMTAB         NOTEQU  => $0DB5
; $0E14 => XXXNUM         NOTRT   => $0E87
; $0E25 => ECHO           NOTRUN  => $0E5E
; $0E2B => LIST           NUMI1   => $0C69
; $0E31 => LIST1          NUMIN   => $0C63
; $0E3A => MARKEOP        NUMO1   => $0C7A
; $0E3E => MONITOR        NUMO2   => $0C81
; $0E5E => NOTRUN         NUMO3   => $0C88
; $0E65 => EDIT           NUMOUT  => $0C74
; $0E77 => EDLOP1         NUMTAB  => $0E0A
; $0E87 => NOTRT          REWIND  => $0EB2
; $0E8C => EDLOP2         SOP     => $0EFE
; $0E9C => EDLOP3         SOPM1   => $0EFD
; $0EA4 => EDLOP4         STAKIT  => $0CDC
; $0EB2 => REWIND         STORAT  => $0D1D
; $0EB8 => DELETE         STRING  => $0D41
; $0EBB => DEL1           SUB     => $0C5A
; $0EC8 => NEXTLN         SYMBOL  => $0C97
; $0ED3 => INPUT          UNCOND  => $0DD8
; $0EDD => INOK           VARADR  => $0E01
; $0EDE => INBAK          WHAT    => $0D54
; $0EFD => SOPM1          XXXNUM  => $0E14
; $0EFE => SOP            ZERO    => $0DA6
