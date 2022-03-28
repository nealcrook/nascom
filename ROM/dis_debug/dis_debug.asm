
L_0008: EQU $0008
L_0010: EQU $0010
L_0018: EQU $0018
L_0028: EQU $0028
L_0030: EQU $0030
L_0038: EQU $0038
L_0E00: EQU $0E00


;*************************************
;*          NAS-DEBUG V3.2           *
;*         22nd Feb  1981            *
;*                                   *
;*  (C) CCSOFT (Southfields) 1981    *
;*    Written by Mick Scutt          *
;*                                   *
;*  A  debugging  aid and  monitor   *
;*  extension package for use with   *
;*  all NAS-SYS monitors and NAS-DIS *
;*                                   *
;* Commands -                        *
;* :A            Alternate CRT page  *
;* :C            Change USER o/p locn*
;* :D nnn        Disassemble from nnn*
;* :F nnnn nnnn  Find up to 8 bytes  *
;* :O nnnn       Optional CRT page   *
;* :P            Print stored regs   *
;*                                   *
;* This software was produced and    *
;* developed on a 48k  Nascom  2,    *
;* using the Zeap 2 assembler.       *
;* Documentation was printed using a *
;* Centronics 737 printer.           *
;*************************************
;
;  NAS-SYS ROUTINE NUMBER EQUATES
ZMRET  EQU  £5B
ZARGS  EQU  £60
ZINLIN EQU  £63
ZNUM   EQU  £64
ZTBCD3 EQU  £66
ZB2HEX EQU  £68
ZSPACE EQU  £69
ZCRLF  EQU  £6A
ZNOM   EQU  £71
ZNNOM  EQU  £77
ZERRM  EQU  £6B
ZRLIN  EQU  £79
ZBLINK EQU  £7B
RIN    EQU  £08
PRS    EQU  £28
;
;  NAS-SYS WORKSPACE RAM
       ORG £0C00
PORT0  DEFS 1
KMAP   DEFS 9
ARGC   DEFS 1
ARGN   DEFS 1
ARG1   DEFS 2
ARG2   DEFS 2
ARG3   DEFS 2
ARG49  DEFS 12
ARG10  DEFS 2
NUMN   DEFS 1
NUMV   DEFS 2
BRKADR DEFS 2
BRKVAL DEFS 1
CONFLG DEFS 1
$KOPT  DEFS 1
$XOPT  DEFS 1
CURSOR DEFS 2
ARGX   DEFS 1
MONSTK DEFS £35
STACK  EQU  $
RBC    DEFS 2
RDE    DEFS 2
RHL    DEFS 2
RAF    DEFS 2
RPC    DEFS 2
INITR  EQU $
RSP    DEFS 2
RSAE   EQU $
$KTABL DEFS 2
$KTAB  DEFS 2
$STAB  DEFS 2
$OUT   DEFS 2
$IN    DEFS 2
$UOUT  DEFS 3
$UIN   DEFS 3
$NMI   DEFS 3
;
;   VIDEO RAM
VL7    EQU £098A
;
;  NAS-SYS MONITOR ADDRESSES
ROUT   EQU  £30
STMON  EQU  £000D
;
;  CHARACTERS
CS     EQU £0C
CR     EQU £0D
CCR    EQU £18
ESC    EQU £1B
MARK   EQU £A0
;
; DEBUG EQU'S
       ORG  £0EF8 ; ** in ZEAP the DSTK can be on the same line but with but other assemblers leave DSTK at the PREVIOUS address.
DSTK   EQU $
ACUR   DEFS 2
OPT    DEFS 2
NUSR   DEFS 2
$DCTAB DEFS 2
SPTOP  EQU  $
;************** DEBUG **************
;
DEBUG  ORG  £C000
;;;REVAS  EQU  £C400
;
; RESTART JUMP
       JP   START
; INITIALISE NAS-SYS
START  LD   SP £1000
       CALL STMON
;
; SET UP $CTAB,USER O/P JUMP,
; OPTION OFF,AND ALT CURSOR
       LD   SP SPTOP
       LD   HL CTAB-£82
       PUSH HL
       LD   HL RETURN
       PUSH HL
       LD   HL 0
       PUSH HL
       LD   HL £080A
       PUSH HL
;
; SET USER O/P TO DEBUG ENTRY POINT
       LD   HL DENT
       LD   ($UOUT+1) HL
;
; MAKE O/P TABLE INCLUDE USER O/P
       RST  $18
       DEFB $55
;
; RETURN TO MONITOR
       RST  $18
       DEFB ZMRET
;
; DEBUG ENTRY POINT FOR ALL OUTPUT
; IF A CCR BEING O/P DO S-STEP DISPLAY
DENT  PUSH AF
       CP   CCR
       JR   NZ CMND
SSTEP  LD   SP DSTK
       RST  $10
       DEFB $7A
       LD   HL (BRKADR)  ; ** printed listing has these two LD swapped
       LD   A (BRKVAL)
       LD   (HL) A
       CALL SSD
       JR   DPJ
; IF CR , MAYBE A NEW COMMAND
CMND   CP   CR
       JR   NZ PNORM
; IT IS CR,IS A COLON AT START OF LINE
       CALL STLIN
       LD   A $3A
       CP   (HL)
       JR   Z DCMND
; CONTINUE  O/P NORMALLY
PNORM: POP  AF
       LD   HL (NUSR)
; JUMP TO NEW USER O/P ADDR
       JP   (HL)
;
; A COLON SAYS DEBUG COMMAND IS NEXT
; WILL NOT RETURN TO NAS-SYS
; SO THROW AWAY THE STACK
DCMND:  LD   SP DSTK
; DELETE COLON AND DO A CR
        LD   (HL) $20
        RST  $18
        DEFB ZCRLF
; NOW REPLACE THE COLON
        LD   HL (CURSOR)
        LD   DE -64
        ADD  HL DE
        LD   (HL) $3A
        EX   DE HL
; DE IS SCREEN POINTER,STEP OVER THE :
; AND USE DEBUG'S COMMAND TABLE
        INC DE
        LD A (DE)
        CP $51    ; ONLY ALLOW "A TO "P
        JR NC DERR
        LD HL ($0EFE) ; ** will not allow $DCTAB.. bug in fixup script
PA1:    PUSH HL
        LD BC ARGX
        LD A (DE)
        CP $20
        JR NZ PA2
        LD A (BC)
        CP $53
        JR NZ DPARSE
PA2     CP $41
        JR C DERR
        CP $5B
        JR NC DERR
        LD (BC) A
        LD (ARGC) A
        PUSH AF
        INC DE
        RST $18
        DEFB ZRLIN
        JR NC DPEND
DERR    RST $18
        DEFB ZERRM
DPJ     JR DPARSE
; IF S OR E CMND EXCHANGE CRT PAGE FIRST
DPEND   POP AF
        PUSH AF
        CP $53
        JR Z DP2
        CP $45
DP2     CALL Z EXCH
        POP AF
        POP HL
        CALL DSCALJ
        JR DPARSE
ALTP    RST $10
        DEFB $0B
        JR NC DPARSE
; CR WILL SWAP PAGE BACK
TIN     RST $18
        DEFB ZBLINK
        CP CR
        JR Z EXCH
        RST ROUT
        JR TIN
EXCH    LD HL (OPT)
        LD A H
        OR L
        RET Z
        SCF
        LD DE $0800
        LD BC 1024
EX1     LD A (DE)
        LDI
        DEC HL
        LD (HL) A
        INC HL
        JP PE EX1
        LD HL, (ACUR)    ; SWAP CURSOR LOCATIONS
        LD DE, (CURSOR)
        LD (ACUR) DE
CUR1    LD (CURSOR) HL
        RET
;
;THIS TAKES OVER FROM PARSE IN NAS-SYS
; MAY HAVE COME HERE WITH RUBBISH
; ON STACK FROM PA1,EDIT ERROR ETC
;
DPARSE  LD SP DSTK
        RST $10
        DEFB $64
; PRAY $NMI STILL POINTS TO TRAP
        RST $18
        DEFB ZINLIN
; IF MARK 1ST ON LINE EDIT"FIND"DSPLAY
        LD A MARK
        LD H D
        LD L E
        CP (HL)
        JR Z, EDFIND
        INC HL
; IF MARK 2ND ON LINE IGNORE REVAS XTRA
        CP (HL)
        JR Z, DPARSE
; IF MARK 3RD ON LINE EDIT SSTEP DSPLY
        INC HL
        CP (HL)
;IF NO MARK GOTO PA1, USE NAS-SYS STAB
; AND NAS-SYS STACK
        JR Z RNAM
        LD HL ($STAB)
        LD SP STACK
        JP PA1
;
; IS A REGISTER  NAME ON THE LINE ?
RNAM    LD BC RBC
        LD HL REGTAB
TSTREG  LD A (DE)
        CP (HL)
        INC HL
        JR Z FOUND
; STEP OVER REG IMAGE ADDR
        INC C
        INC C
; STEP OVER ROUTINE ADDR
        INC HL
        INC HL
        LD A (HL)
        OR A
        JR NZ TSTREG
; EDITING ERROR
EDERR   JR DERR
; FOUND REG NAME,BC POINTS TO IMAGE
; STEP OVER REG NAME AND MARK
FOUND   INC DE
        INC DE
        INC DE
        LD A (HL)       ; GET RTNE ADDR & GO TO IT
        INC HL
        LD H (HL)
        LD L A
        RST $10
        DEFB $72
FIN     RST $18
        DEFB ZNNOM      ; NEW DISPLAY TO CRT ONLY
        PUSH HL         ; MAY HAVE A NEW BYTE
        RST $10
        DEFB $27        ; AT PROG ADDR SO
        LD DE -64       ; IF POSS. REDO THE
        LD B $07        ; EXISTING DISPLAY
        LD HL VL7       ; LOOK FOR THE LINE
SPLINE  LD A $53        ; WITH SP ON
        CP (HL)
        JR Z, REDO
; KEEP LOOKING
UPONE   ADD HL DE
        DJNZ SPLINE
        CALL SSD        ; NOT FOUND,DO NEW DISPLAY
        JR NOMOP
REDO    PUSH HL         ; FOUND,RE-DO OLD DISPLAY
        LD HL (CURSOR)
        EX (SP), HL     ; SAVE EXISTING CURSOR POSN
        RST $10
        DEFB $9E
        CALL SSD
        POP HL
        RST $10
        DEFB $98
NOMOP   POP HL
        RST $18         ; RESTORE O/P TABLE POINTER
        DEFB ZNOM
PAJ     JR DPARSE
;
;
BRSTO   XOR A
        LD (CONFLG) A
        LD HL (BRKADR)
        LD A (HL)
        LD (BRKVAL) A
RETURN  RET
;
; EDIT A "FIND" LINE
EDFIND  RST $10
        DEFB $85
        INC DE
; GET THE ADDRESS
        RST $10
        DEFB $6B
        PUSH BC
        LD HL 25
; GET THE BYTES
        RST $10
        DEFB $10
; REPRINT THE LINE & RET TO DPARSE
        POP HL
        CALL PHA
        JR PAJ
; GET REG VALUE OFF SCREEN
VALUES  RST $10
        DEFB $4C
; IF ZERO CAN EDIT THE BYTES
        RET NZ
;
; GET THE BYTES OFF THE SCREEN
GBDEC   DEC BC
        DEC BC
        DEC BC
        DEC BC
GBL     LD HL 31

GBY:    ADD HL, DE

GB1:    PUSH HL
        RST $18
        DEFB ZNUM
        POP HL
        SBC A, A
        OR A
        SBC HL, DE
        ADD HL, DE
        RET C
        RLA

ERJ:    JR C, EDERR
        LD A, ($0C21)
        LD (BC), A
        INC BC
        JR GB1

XYC:    RST $10
        DEFB $3E
        POP HL
        EX (SP), HL
        SBC HL, BC
        POP HL
        JR Z, GBDEC
        PUSH BC

JUMP:   JP (HL)


PCR:    RST $10
        DEFB $22
        RET NZ
        LD HL, $0011
        JR GBY

IXY:    DEC DE
        DEC DE
        LD A, (DE)
        INC DE
        INC DE
        CP $59
        JR Z, IYR
        PUSH IX
        RST $10
        DEFB $E0
        POP IX
        RET

IYR:    PUSH IY
        RST $10
        DEFB $D9
        POP IY
        RET


SPR:    RST $10
        DEFB $03
        JR Z, GBL
        RET

IMAGEV: PUSH BC
        RST $10
        DEFB $0E
        POP HL
        PUSH HL
        LD A, (HL)
        INC HL
        LD H, (HL)
        LD L, A
        SBC HL, BC
        POP HL
        RET Z
        LD (HL), C
        INC HL
        LD (HL), B
        RET

NUMBR:  RST $18
        DEFB ZNUM
        JR C, ERJ
        LD BC, ($0C21)
        RET

REGN:   RST $18
        DEFB ZB2HEX

REGDIS: LD A, $A0
        RST ROUT
        RST $18
        DEFB ZTBCD3
        LD B, $0A
        DEC HL
        DEC HL
        DEC HL
        DEC HL

SPDIS:  RST $18
        DEFB ZSPACE
        LD A, H
        CP $08
        JR C, RD1
        CP $0C
        JR NC, RD1
        LD DE, ($0EFA)
        LD A, D
        OR E
        JR Z, RD1
        ADD HL, DE
        LD DE, $F800
        ADD HL, DE

RD1:    LD A, (HL)
        INC HL
        RST $18
        DEFB ZB2HEX
        RST $18
        DEFB ZSPACE
        DJNZ RD1
        RST ROUT
        RET

SSD     CALL STLIN
        LD ($0C29), HL
        RST PRS
        DEFM /SP/
        DEFB MARK,0
        LD HL, ($0C6B)
        RST $18
        DEFB ZTBCD3
        LD B, $0C
        CALL SPCS
        LD B, $06
        RST $10
        DEFB $C5
        RST PRS
        DEFB CR
        DEFM /IX/
        DEFB 0
        PUSH IX
        POP HL
        RST $10
        DEFB $B0
; DISPLAY IFF2
        RST PRS
        DEFM / IFF2 /
        DEFB 0
        LD A, I
        LD A, $30
        JP PO, IFF
        INC A

IFF:    RST ROUT
        RST PRS
        DEFB CR
        DEFM /IY/
        DEFB 0
        PUSH IY
        POP HL
        RST $10
        DEFB $95
; DISPLAY I REG
        RST PRS
        DEFM / I /
        DEFB 0
        LD A, I
;
; SAVE ALT REGS ON STACK
        EXX
        PUSH BC
        PUSH DE
        PUSH HL
        EXX
; FINISH I REG
        RST $10
        DEFB $73
; DISPLAY HL,(HL) & HL'
        RST PRS
        DEFM /HL/
        DEFB 0
        LD HL, ($0C65)
        CALL REGDIS
        RST PRS
        DEFM /HL/
        DEFB 0
        RST $10
        DEFB $5A
        LD A, $DE
        LD HL, ($0C63)
        CALL REGN
        LD A, $DE
        RST $10
        DEFB $4C
        LD A, $BC
        LD HL, ($0C61)
        CALL REGN
        LD A, $BC
        RST $10
        DEFB $40
        RST PRS
        DEFB $41
        DEFB $46
        DEFB $A0
        DEFB $00
        LD HL, ($0C67)
        RST $18
        DEFB ZTBCD3
        RST ROUT
        LD A, L
        LD HL, $C3C1
        LD B, $0C

PCL:    INC HL
        SLA A
        PUSH AF
        LD A, (HL)
        JR C, PRC
        LD A, $20

PRC:    RST ROUT
        POP AF
        DJNZ PCL
        RST PRS
        DEFB $5E
        DEFB $00
        LD B, $12
        RST $10
        DEFB $5A
        EX AF, AF'
        PUSH AF
        EX AF, AF'
        LD A, $AF
        RST $10
        DEFB $14
        LD DE, REVOUT
        RST $10
        DEFB $1F
        LD HL, ($0C69)

RV1:    LD B, H
        LD C, L
        LD D, H
        LD E, L
        PUSH IX
        CALL L_CFFD
        POP IX
        RET

ALTN:   RST $18
        DEFB ZB2HEX

ALT:    LD A, $27
        RST ROUT
        POP HL
        EX (SP), HL
        LD A, H
        RST $18
        DEFB ZB2HEX
        LD A, L

B2HCR:  RST $18
        DEFB ZB2HEX

CRRET:  RST $18
        DEFB ZCRLF
        RET


REVAD:  LD HL, ($C403)
        LD (HL), $C3
        INC HL
        LD (HL), E
        INC HL
        LD (HL), D
        INC HL
        LD (HL), $01
        RET

REVOUT: RST PRS
        DEFB $50
        DEFB $43
        DEFB $A0
        DEFB $00

REVO2:  LD B, $12

REVO:   LD A, (HL)
        INC HL
        RST ROUT
        DJNZ REVO
        INC HL
        INC HL
        INC HL

BOUT:   LD A, (HL)
        RST ROUT
        INC HL
        CP CR
        JR NZ, BOUT
        LD DE, REVO3
        JR REVAD

REVO3:  RST PRS
        DEFB $20
        DEFB $A0
        DEFB $20
        DEFB $00
        JR REVO2

SPCS:   RST $18
        DEFB ZSPACE
        DJNZ SPCS
        RET

STLIN:  LD HL, ($0C29)
        LD A, L
        AND $C0
        OR $0A
        LD L, A
        RET

REVENT: PUSH HL
        LD DE, REVO3
        RST $10
        DEFB $BC

RM1:    POP HL

RM2:    RST $10
        DEFB $9D
        PUSH DE

INP:    RST $18
        DEFB ZBLINK
        CP CR
        JR Z, NL
        RST ROUT
        CP $1B
        JR NZ, INP
        POP AF
        JR CRRET

NL:     RST $10
        DEFB $DC
        EX DE, HL
        RST $18
        DEFB ZNUM
        JR C, FERR
        LD A, (HL)
        OR A
        JR Z, RM1
        RST $18
        DEFB ZCRLF
        POP HL
        LD HL, ($0C21)
        JR RM2


FIND:   DEC HL
        PUSH HL
        RST $18
        DEFB ZSPACE
        RST $18
        DEFB ZINLIN
        LD HL, $0C10
        LD BC, $0000

MORE:   PUSH HL
        RST $18
        DEFB ZNUM
        LD A, (HL)
        OR A
        JR Z, NOARGS
        INC HL
        LD A, (HL)
        POP HL

STORE:  LD (HL), A
        INC HL

L_C331:
        INC B
        BIT 3, B
        JR NZ, F2
        RLC C
        JR MORE

NOARGS: POP HL
        LD A, (DE)
        CP $2C
        JR NZ, MINUS
        INC DE
        LD A, (DE)
        INC DE
        JR STORE

MINUS:  CP $2D
        JR Z, FLAG
        OR A
        JR Z, F2

FERR:   JP DERR

FLAG:   SET 0, C
        INC DE
        JR L_C331

F2:     LD A, C
        INC A
        JR Z, FERR
        PUSH BC
        LD A, $06

BDUN:   CP B
        JR C, CDUN
        RLC C
        INC B
        JR BDUN

CDUN:   POP AF
        LD B, A
        POP HL

NEXT:   LD DE, ($0C0E)
        INC HL
        OR A
        SBC HL, DE
        ADD HL, DE
        RET NC
        PUSH BC
        PUSH HL
        LD DE, $0C10

FTEST:  RLC C
        JR NC, COMP
        INC HL
        DEC B
        JR FTEST

COMP:   LD A, (DE)
        CP (HL)
        INC HL
        JR NZ, NEXTJ
        INC DE
        DJNZ FTEST
        POP HL
        PUSH HL
        RST $10
        DEFB $04

NEXTJ:  POP HL
        POP BC
        JR NEXT

PHA:    LD A, $A0
        RST ROUT
        RST $18
        DEFB ZTBCD3
        LD D, H
        LD E, L
        LD B, $08
        CALL SPDIS
        RST ROUT
        LD B, $08

PRA:    LD A, (DE)
        INC A
        AND $7F
        CP $21
        LD A, (DE)
        JR NC, PRA2
        LD A, $2E

PRA2:   RST ROUT
        INC DE
        DJNZ PRA
        RST $18
        DEFB ZCRLF
        RET

CHUSR:  LD ($0EFC), HL
        RET

OPTN:   LD ($0EFA), HL
        RET

DSCALJ: LD E, A
        LD D, $00
        ADD HL, DE
        ADD HL, DE
        LD E, (HL)
        INC HL
        LD D, (HL)
        PUSH DE
        RST $18
        DEFB ZARGS
        RET

STR:    DEFM "SZ H PNC"

REGTAB: DEFM "B"
        DEFW VALUES
        DEFM "D"
        DEFW VALUES
        DEFM "H"
        DEFW VALUES
        DEFM "A"
        DEFW IMAGEV
        DEFM "P"
        DEFW PCR
        DEFM "S"
        DEFW SPR
        DEFM "I"
        DEFW IXY
        DEFB $00

CTAB:   DEFW ALTP, DERR, CHUSR, REVENT
        DEFW DERR, FIND, DERR, DERR
        DEFW DERR, DERR, DERR, DERR
        DEFW DERR, DERR, OPTN, SSD


; END OF NAS-DEBUG.



; START OF NAS-DIS

        LD A, $C3
        LD (L_0E00), A
        LD ($0E03), A
        LD HL, PRINT
        LD ($0E01), HL
        LD A, ($0C0B)
        CP $02
        JP C, REVASC
        RST $18
        DEFB ZARGS
        JR NZ, SCO
        LD C, $01

SCO:    LD B, C
        LD ($0C10), BC
        LD B, D
        LD C, E
        LD HL, $FFFF
        JR REVAS

PRINT:  LD A, (HL)
        RST ROUT
        INC HL
        CP CR
        JR NZ, PRINT
        LD HL, $0C10
        DEC (HL)
        RET NZ
        INC HL
        LD A, (HL)
        DEC HL
        LD (HL), A
        RST RIN
        SUB $1B
        RET NZ
        RST $18
        DEFB $5B

REVAS:
        LD ($0E04), BC
        LD ($0E06), DE
        LD ($0E08), HL

NEXTL:
        LD HL, ($0E08)
        LD DE, ($0E06)
        XOR A
        SBC HL, DE
        RET C
        CALL INITB
        CALL BYTE
        CALL DECODE
        LD HL, $0E0C
        LD A, (HL)
        INC HL
        CP (HL)
        CALL NZ, NOTVAL
        LD HL, $0E14
        CALL L_0E00
        JR NEXTL


INITB:
        LD DE, $0E14
        PUSH DE
        POP IX
        LD HL, $0000
        LD ($0E12), HL
        LD ($0E0C), HL
        LD HL, ($0E04)
        LD ($0E0E), HL
        CALL HEX4
        EX DE, HL
        INC HL
        LD ($0E0A), HL
        DEC HL
        LD B, $2B

INITB0:
        LD (HL), $20
        INC HL
        DJNZ INITB0
        LD (IX+$2A), $3B
        LD (HL), CR
        LD DE, $0E2D
        RET


HEX4:
        LD A, H
        CALL HEX2
        LD A, L

HEX2:
        PUSH AF
        RRCA
        RRCA
        RRCA
        RRCA
        CALL HEX1
        POP AF

HEX1:
        PUSH AF
        AND $0F
        ADD A, $90
        DAA
        ADC A, $40
        DAA
        LD (DE), A
        INC DE
        POP AF
        RET


BYTE:
        INC IX
        LD HL, ($0E04)
        INC HL
        LD ($0E04), HL
        LD HL, ($0E06)
        LD A, (HL)
        INC HL
        LD ($0E06), HL
        LD HL, ($0E0A)
        INC HL
        EX DE, HL
        CALL HEX2
        EX DE, HL
        LD ($0E0A), HL
        PUSH AF
        INC A
        AND $7F
        CP $21
        DEC A
        JR NC, BYTE0
        LD A, $2E

BYTE0:
        LD (IX+$2A), A
        POP AF
        RET


WREX:
        EX DE, HL
        LD (HL), $45
        INC HL
        LD (HL), $58
        JR WRLD0


WRLD:
        EX DE, HL
        LD (HL), $4C
        INC HL
        LD (HL), $44

WRLD0:
        LD DE, $0E32
        RET


COMMA:
        EX DE, HL
        LD (HL), $2C
        INC HL
        EX DE, HL
        RET


POUND:
        EX DE, HL
        LD (HL), $23
        INC HL
        EX DE, HL
        RET


COPY6:  LDI
COPY5:  LDI
COPY4:  LDI
COPY3:  LDI
COPY2:  LDI
        LDI
        RET

FTADR:  ADD A, L
        LD L, A
        RET NC
        INC H
        RET

DECODE: PUSH AF
        AND $C0
        CP $40
        JP Z, LOAD8
        CP $80
        JP Z, ARITH8
        POP AF
        PUSH AF
        AND $8F
        RLCA
        RLCA
        LD HL, TABLE
        CALL FTADR
        LD A, (HL)
        INC HL
        LD H, (HL)
        LD L, A
        JP (HL)

INC:    LD HL, INCM
        JR ID0

DEC:    LD HL, DECM

ID0:    CALL COPY3S
        POP AF
        BIT 2, A
        JR Z, REGPR
        RRCA
        RRCA
        RRCA
        JR SREG


LD16:   CALL WRLD
        POP AF
        CALL REGPR
        CALL COMMA

LD16A:  CALL BYTE
        LD C, A
        CALL BYTE
        LD H, A
        LD L, C

LD16B:  LD ($0E12), DE
        LD ($0E10), HL
        CALL POUND
        JP HEX4


ADDHL:  LD HL, ARTAB

L_C56B: CALL COPY3S
        LD A, $20
        CALL REGPR
        CALL COMMA

L_C576: POP AF

REGPR:  LD B, A
        RRCA
        RRCA
        RRCA
        ADD A, $02
        LD C, $06
        AND C
        LD HL, RPRTAB
        JR NZ, NOTSP
        DEC HL
        BIT 7, B
        JP Z, COPY2
        DEC HL
        DEC HL

NOTSP:
        CP C
        JR NZ, L_C597
        LD A, ($0E0C)
        LD ($0E0D), A
        ADD A, C

L_C597:
        CALL FTADR
        JP COPY2


LOAD8:
        POP AF
        CP $76
        JR Z, HALT
        PUSH AF
        CALL WRLD
        RRCA
        RRCA
        RRCA
        CALL SREG
        CALL COMMA

L8B:
        POP AF
        BIT 6, A
        JR Z, IMM

SREG:
        INC A
        AND $07
        CP $07
        JR Z, MEM
        LD HL, $C9C9
        CALL FTADR
        LDI
        RET


MEM:
        LD A, $28
        LD (DE), A
        INC DE
        LD HL, HXYTAB
        LD A, ($0E0C)
        LD ($0E0D), A
        PUSH AF
        CALL L_C597
        POP AF
        AND A
        JR Z, NOTIXY
        CALL BYTE
        AND A
        LD C, $2B
        JR Z, NOTIXY
        JP P, PLUS
        NEG
        LD C, $2D

PLUS:
        LD B, A
        LD A, C
        LD (DE), A
        INC DE
        LD A, B
        CALL PHEX2

NOTIXY:
        LD A, $29
        LD (DE), A
        INC DE
        RET


IMM:
        CALL BYTE

PHEX2:
        CALL POUND
        JP HEX2


HALT:
        LD HL, HALTM
        JP COPY4


ARITH8:
        POP AF
        XOR $40
        PUSH AF
        RRCA
        RRCA
        AND $0E
        LD B, A
        RRCA
        ADD A, B
        LD HL, ARTAB
        CALL NZ, FTADR
        LD A, B
        CALL COPY3S
        LD HL, $CAB0
        CP $06
        CALL Z, COPY2
        CP $03
        CALL C, COPY2
        JR L8B


POP:
        LD HL, POPM
        JR PP0


PUSH:
        LD HL, PUSHM

PP0:
        CALL COPY4
        INC DE
        JP L_C576


CALETC:
        POP AF
        CP $ED
        JP Z, EXTND
        CP $CD
        JR Z, L_C658
        SUB $F9
        JR NC, CE0
        LD A, $02

CE0:
        LD ($0E0C), A
        CALL BYTE
        LD B, A
        AND $0F
        CP CR
        LD A, B
        RET Z
        JP DECODE


CJR:
        POP AF

L_C658:
        PUSH AF
        AND $06
        RLCA
        LD HL, CJRTAB
        CALL NZ, FTADR
        CALL COPY4
        INC DE
        POP AF
        CP $C9
        RET Z
        BIT 0, A
        JR NZ, UNCND
        PUSH AF
        CALL CCODES
        POP AF
        AND $07
        RET Z
        CALL COMMA

UNCND:
        JP LD16A


CCODES:
        RRCA
        RRCA
        AND $0E
        LD HL, CCTAB
        JP L_C597


ROTMIS:
        POP AF
        RRCA
        AND $1C
        LD HL, RMTAB
        CALL NZ, FTADR
        JP COPY4


RST:
        LD HL, RSTM
        CALL COPY3S
        POP AF
        AND $38
        CALL PHEX2
        LD HL, $0E03
        BIT 0, (HL)
        RET Z
        CP $10
        RET C
        CP $20
        RET Z
        JR C, FLUSH
        CP $28
        RET NZ

BORM:
        CALL FLUSH
        LD B, $03
        JR C, UNPRN
        INC B
        LD HL, $0E30
        LD (HL), $4D
        INC HL
        INC HL
        LD (HL), $2F
        INC HL
        EX DE, HL
        JR MS1


MOREMS:
        CALL PRTABL
        JR C, DONEM
        CALL BYTE

MS1:
        LD (DE), A
        INC DE
        DJNZ MOREMS

DONEM:
        EX DE, HL
        LD (HL), $2F
        JR BORM


UN0:
        CALL BYTE

UNPRN:
        OR A
        JP Z, NOTVAL
        CALL PRTABL
        JR NC, UN1
        DJNZ UN0

UN1:
        CALL NOTVAL
        JR BORM


FLUSH:
        LD HL, $0E14
        CALL L_0E00
        CALL INITB
        CALL BYTE
        PUSH AF
        CALL NOTVAL
        POP AF
        JR PRTB1


PRTABL:
        LD HL, ($0E06)
        LD A, (HL)

PRTB1:
        CP $20
        RET C
        CP $2F
        SCF
        RET Z
        CP $7F
        CCF
        RET


NOPETC:
        POP AF
        CP $10
        JR Z, DJNZ
        JR C, NOP

JR:
        EX DE, HL
        LD (HL), $4A
        INC HL
        LD (HL), $52
        LD DE, $0E32
        CP $18
        JR Z, UCD
        AND $18
        CALL CCODES
        CALL COMMA

UCD:
        CALL BYTE
        LD C, A
        RLCA
        SBC A, A
        LD B, A
        LD HL, ($0E04)
        ADD HL, BC
        JP LD16B


NOP:
        LD HL, NOPM

COPY3S:
        CALL COPY3
        INC DE
        INC DE
        RET


DJNZ:
        LD HL, DJNZM
        CALL COPY4
        INC DE
        JR UCD


EXAETC:
        POP AF
        CP $08
        JR NZ, JR
        CALL WREX
        LD HL, EXAFM
        JP COPY6


JPETC:
        POP AF
        CP $D3
        JP C, L_C658
        JP Z, OUT
        CP $F3
        JR Z, DI
        CALL WREX
        LD HL, BSPBM
        CALL COPY5
        LD A, $20
        JP REGPR


DI:
        LD A, $44
        JR DEI


EI:
        LD A, $45

DEI:
        EX DE, HL
        LD (HL), A
        INC HL
        LD (HL), $49
        RET


CBETC:
        POP AF
        CP $DB
        JP Z, IN
        JP C, CB
        CP $FB
        JR Z, EI
        CALL WREX
        LD HL, $C9CC
        CALL COPY2
        CALL COMMA
        JP COPY2


RETETC:
        POP AF
        CP $D9
        JP C, L_C658
        JR Z, EXX
        CP $F9
        JR Z, LDSP
        LD HL, $C9FC
        CALL COPY2
        LD HL, $0E32
        JR L_C7EC


LDSP:
        CALL WRLD
        LD HL, SPM
        CALL COPY3
        LD A, $20
        JP REGPR


EXX:
        CALL WREX
        INC HL
        LD (HL), $58
        RET


STIND:
        CALL WRLD
        POP AF
        PUSH AF
        CP $22
        JR Z, ST16I
        POP AF
        CALL LD1
        CALL COMMA

ST1:
        LD A, $41
        LD (DE), A
        INC DE
        RET


LDIND:
        CALL WRLD
        POP AF
        PUSH AF
        CP $2A
        JR Z, LD16I
        CALL ST1
        CALL COMMA
        POP AF

LD1:
        CP $22

L_C7EB:
        EX DE, HL

L_C7EC:
        LD (HL), $28
        INC HL
        EX DE, HL
        CCF
        CALL NC, REGPR
        CALL C, LD16A
        JP NOTIXY


ST16I:
        CALL LD1
        CALL COMMA
        JP L_C576


LD16I:
        POP AF

L_C804:
        CALL REGPR
        CALL COMMA
        AND A
        JR L_C7EB


CB:
        LD A, ($0E0C)
        AND A
        PUSH AF
        JR Z, NOTXY
        LD DE, $0E34
        LD A, $06
        CALL SREG
        LD DE, $0E2D

NOTXY:
        CALL BYTE
        PUSH AF
        CP $40
        JR C, ROTATE
        LD HL, SPM
        RLCA
        RLCA
        AND $03
        LD B, A
        RLCA
        ADD A, B
        CALL FTADR
        CALL COPY3S
        POP AF
        PUSH AF
        RRCA
        RRCA
        RRCA
        AND $07
        OR $30
        LD (DE), A
        INC DE
        CALL COMMA

TESTXY:
        POP BC
        POP AF
        LD A, B
        JP Z, SREG
        AND $07
        CP $06
        RET Z
        JP NOTVAL


ROTATE:
        RRCA
        RRCA
        ADD A, $02
        AND $0E
        CP $0E
        JP Z, NTVL
        LD B, A
        RRCA
        ADD A, B
        LD HL, ROTTAB
        CALL FTADR
        CALL COPY3S
        JR TESTXY


AUTO:
        BIT 2, A
        JP NZ, NOTVAL
        PUSH AF
        AND $03
        RLCA
        LD HL, OPTAB
        CALL L_C597
        POP AF
        PUSH AF
        INC A
        AND $13
        JR NZ, AUTO0
        DEC DE
        CALL COPY2

AUTO0:
        POP AF
        LD HL, $CA7A
        RRCA
        RRCA
        AND $06
        JP L_C597


ADCSBC:
        LD HL, $C9E1
        LD A, C
        PUSH AF
        BIT 3, A
        JR Z, AS0
        LD HL, $C9DB

AS0:
        JP L_C56B


IN:
        LD A, $FF

INRC:
        CP $0E
        JP Z, NOTVAL
        LD HL, INM
        CALL COPY3S
        PUSH AF
        CALL SREG
        CALL COMMA
        POP AF

PORT:
        EX DE, HL
        LD (HL), $28
        INC HL
        INC A
        JR Z, INA
        LD (HL), $43
        INC HL
        EX DE, HL

L_C8C0:
        JP NOTIXY


INA:
        EX DE, HL
        CALL IMM
        JR L_C8C0


EXTND:
        CALL BYTE
        CP $C0
        JP NC, NOTVAL
        CP $40
        JP C, NOTVAL
        CP $A0
        JR NC, AUTO
        CP $80
        JP NC, NOTVAL
        LD C, A
        AND $07
        LD B, A
        LD A, C
        RRCA
        RRCA
        RRCA
        JR Z, INRC

NOTIN:  DJNZ NOTOUT
        DEFB 021H
OUT:    LD A, 0FFH
        CP $2E
        JP Z, NOTVAL
        LD HL, OUTM
        CALL COPY3S
        PUSH AF
        CALL PORT
        CALL COMMA
        POP AF
        JP SREG


NOTOUT:
        DEC B
        JR Z, ADCSBC
        DJNZ NOTLD
        AND $0E
        CP $0C
        JP Z, NOTVAL
        CALL WRLD
        BIT 3, C
        LD A, C
        JP NZ, L_C804
        PUSH AF
        JP ST16I


NOTLD:
        LD A, C
        LD BC, $000C
        LD HL, REMEXT
        CPIR
        JR NZ, NOTVAL
        LD A, C
        RLCA
        CP $08
        JR C, LDRI
        RLCA
        LD HL, $CA7E
        CP $1C
        JR C, INTMOD
        CALL FTADR
        JP COPY4


LDRI:
        CALL WRLD
        LD HL, IRTAB
        CALL FTADR
        JP COPY3


INTMOD:
        CALL L_C597
        LD DE, $0E32
        LDI
        RET


NTVL:
        POP HL
        POP HL

NOTVAL:
        LD HL, DEFB
        LD DE, $0E2D
        CALL COPY4
        INC DE
        LD HL, $0E1A
        LD C, $15
        LD A, $20

NVLP:
        CALL POUND
        CALL COPY2
        INC HL
        CP (HL)
        JR Z, DNV
        CALL COMMA
        JR NVLP


DNV:
        LD HL, $0000
        LD ($0E12), HL
        LD A, C
        CP CR
        RET NZ
        LD (DE), A
        RET


TABLE:
        DEFW NOPETC, CJR, LD16, POP, STIND, CJR, INC, JPETC
        DEFW INC, CJR, DEC, PUSH, LOAD8, ARITH8, ROTMIS, RST
        DEFW EXAETC, CJR, ADDHL, RETETC, LDIND, CJR, DEC, CBETC
        DEFW INC, CJR, DEC, CALETC, LOAD8, ARITH8, ROTMIS, RST

INCM:   DEFM "INC"

DECM:   DEFM "DEC"
        DEFM "AFS"

RPRTAB: DEFM "PABCDE"

HXYTAB: DEFM "HLIXIY"

HALTM:  DEFM "HALT"

ARTAB:  DEFM "ADDADCSUBSBC"
        DEFM "ANDXOROR CP "

PUSHM:  DEFM "PUSH"

POPM:   DEFM "POP "

CJRTAB: DEFM "RET JP  CALL"

CCTAB:  DEFM "NZ ZNC CPOPE P M"

RMTAB:  DEFM "RLCARRCARLA RRA "
        DEFM "DAA CPL SCF CCF "

RSTM:   DEFM "RST"

NOPM:   DEFM "NOP"

DJNZM:  DEFM "DJNZ"

EXAFM:  DEFM "AF,AF'"

BSPBM:  DEFM "(SP),"

INM:    DEFM "IN "

OUTM:   DEFM "OUT"

SPM:    DEFM "SP,"

BRSTAB: DEFM "BITRESSET"

ROTTAB: DEFM "SRLRLCRRCRL RR SLASRA"

OPTAB:  DEFM "LDCPINOTUTI D IRDR"

REMEXT: DEFB $44, $45, $4D, $67, $6F, $46
        DEFB $56, $5E, $57, $4F, $5F, $47

EXTMNE: DEFM "IM2 IM1 IM0 RLD "
        DEFM "RRD RETIRETNNEG "

IRTAB:  DEFM "I,A,R,A,I"

DEFB:   DEFM "DEFB"

REVASC: LD DE, $0E80
        LD HL, RAMLD
        LD BC, $0012
        LDIR

L_CAC6: RST PRS
        DEFB CR
        DEFM "Options? ("

OTAB:   DEFM "STZXLPDR"
        DEFM "U)-"
        DEFB 0
        LD DE, $0000
        LD A, $01
        DEFB 1
XFOUND: SUB 'U'
        JR NZ, OPT0
        LD ($0E03), A

OPT0:   LD A, E
        OR D
        LD D, A
        RST RIN
        RST ROUT
        SCF
        LD E, $00
        LD HL, OTAB

LUOP:   RL E
        CPI
        JR Z, XFOUND
        JR NC, LUOP
        CP CR
        JR NZ, L_CAC6
        LD A, D
        BIT 2, A
        JR Z, OPT1
        OR $11

OPT1:   LD ($0E44), A
        PUSH AF
        AND $1C
        JR Z, NLABS

GETSTA: POP AF
        PUSH AF
        BIT 2, A
        JR Z, ST
        RST PRS
        DEFB $5A
        DEFB $45
        DEFB $41
        DEFB $50
        DEFB $20
        DEFB $66
        DEFB $69
        DEFB $00
        JR ST0

ST:     RST PRS
        DEFB $53
        DEFB $79
        DEFB $6D
        DEFB $62
        DEFB $6F
        DEFB $6C
        DEFB $20
        DEFB $74
        DEFB $61
        DEFB $62
        DEFB $00

ST0:    RST PRS
        DEFB $6C
        DEFB $65
        DEFB $20
        DEFB $61
        DEFB $72
        DEFB $65
        DEFB $61
        DEFB $3F
        DEFB CR, 0
        CALL GETTWO
        JR C, GETSTA
        LD ($0E4E), BC
        LD ($0E50), DE
        LD A, $FF
        LD (DE), A

NLABS:  POP AF
        BIT 5, A
        JR Z, NOTITL

ASKT:   RST PRS
        DEFB $54
        DEFB $69
        DEFB $74
        DEFB $6C
        DEFB $65
        DEFB $3F
        DEFB CR,0
        RST $18
        DEFB ZINLIN
        LD HL, $053C
        LD A, (DE)
        CP $3D
        JR NZ, SETLPP
        INC DE
        RST $18
        DEFB ZNUM
        JR C, ASKT
        LD HL, ($0C21)

SETLPP: LD ($0E7E), HL
        LD HL, $0101
        LD ($0E7C), HL
        EX DE, HL
        LD DE, $0E92
        XOR A

COPYT:  LDI
        CP (HL)
        JR NZ, COPYT
        EX DE, HL
        LD A, $20

BACK:   DEC HL
        CP (HL)
        JR Z, BACK
        INC HL
        LD (HL), CR

NOTITL: RST PRS
        DEFB $57
        DEFB $68
        DEFB $61
        DEFB $74
        DEFB $20
        DEFB $6F
        DEFB $6E
        DEFB $3F
        DEFB CR,0
        RST $18
        DEFB ZINLIN
        RST $18
        DEFB ZRLIN
        JR C, NOTITL
        LD A, ($0C0B)
        CP $02
        JR C, NOTITL
        RST $18
        DEFB ZARGS
        INC DE
        LD ($0E14), DE
        LD D, H
        LD E, L
        DEC HL
        LD ($0E46), SP
        PUSH HL
        INC HL
        JR Z, ONLY2
        LD H, B
        LD L, C

ONLY2:  SBC HL, DE
        LD ($0E54), HL
        LD BC, $0000
        LD DE, $FFFF
        LD HL, $0E44
        BIT 7, (HL)
        JR Z, DA
        RES 7, (HL)
RNGRQ:  RST PRS
        DEFM "Listing range?"
        DEFB CR,0
        CALL GETTWO
        JR C, RNGRQ

DA:     LD ($0E48), BC
        LD ($0E4A), DE

DAREA:  RST PRS
        DEFM "DATA areas?"
        DEFB CR,0
        XOR A

L_CBF3: PUSH AF

DAREA0: CALL GETTWO
        JR C, DAREA1
        LD H, B
        LD L, C
        LD BC, ($0E54)
        PUSH BC
        SBC HL, BC
        EX (SP), HL
        POP BC
        EX DE, HL
        OR A
        SBC HL, DE
        EX DE, HL
        POP AF
        POP HL
        PUSH HL
        PUSH AF
        SCF
        INC HL
        SBC HL, BC
        JR NC, DAREA2
        LD HL, ($0E14)
        SBC HL, DE
        JR C, DAREA2
        POP AF
        PUSH BC
        PUSH DE
        INC A
        JR L_CBF3
DAREA1: AND A
        JR Z, DAREA3
        CP $2D
        JR NZ, DAREA2
        POP AF
        AND A
        JR Z, DAREA
        POP HL
        POP HL
        DEC A
        PUSH AF
        RST PRS
        DEFB $13
        DEFB $1B
        DEFB $13
        DEFB $1B
        DEFB $00
        JR DAREA0

DAREA2: RST $18
        DEFB ZERRM
        RST PRS
        DEFB $13
        DEFB $13
        DEFB $17
        DEFB $00
        JR DAREA0


DAREA3: POP AF
        LD HL, ($0E14)
        PUSH HL
        LD HL, $FFFF
        PUSH HL
        RST PRS
        DEFB $47
        DEFB $6F
        DEFB $3F
        DEFB $00
        RST $18
        DEFB ZBLINK
        LD ($0E45), A
        RST $18
        DEFB ZCRLF
        LD A, ($0E44)
        AND $18
        LD HL, PASS1
        CALL NZ, PASS
        LD HL, $0E44
        SET 7, (HL)
        BIT 2, (HL)
        JR Z, ALLIN0
        LD HL, ($0E50)
        LD ($0F02), HL
        LD HL, ($0E4E)
        LD ($0F00), HL
        LD DE, ($0E52)
        LD ($0E4E), DE
        LD DE, ($0E82)
        INC HL
        INC HL
        LD (HL), E
        INC HL
        LD (HL), D
        INC HL
        LD (HL), $00
        LD ($0E56), HL

ALLIN0: LD HL, PASS2
        CALL PASS
        LD HL, $0E44
        RES 7, (HL)
        BIT 4, (HL)
        PUSH HL
        CALL NZ, LABEL
        POP HL
        BIT 3, (HL)
        JR NZ, PCRT

EXIT:   RST $18
        DEFB $5B

PCRT:   LD A, (HL)
        LD HL, $0E7D
        DEC (HL)
        DEC HL
        PUSH HL
        BIT 5, A
        CALL NZ, EJECT
        POP HL
        INC (HL)
        LD HL, $FFFF
        LD ($0E4A), HL
        LD IY, ($0E50)

XREF1:  LD A, (IY+0)
        INC A
        JR Z, EXIT
        DEC IY
        LD C, A
        LD B, $09
        LD DE, $0E14

XREF2:  LD L, (IY+0)
        DEC IY
        LD H, (IY+0)
        DEC IY
        CALL HEX4
        LD A, $20
        LD (DE), A
        INC DE
        DEC C
        JR Z, XREF3
        DJNZ XREF2

XREF3:  PUSH BC
        EX DE, HL
        LD (HL), CR
        LD HL, $0E14
        CALL OUTPUT
        POP BC
        LD A, C
        AND A
        JR Z, XREF1
        LD HL, $0E14
        LD B, $05

XREF4:  LD (HL), $20
        INC HL
        DJNZ XREF4
        EX DE, HL
        LD B, $08
        JR XREF2


GETTWO: RST $18
        DEFB ZINLIN
        LD A, $1B
        RST ROUT
        PUSH DE
        RST $18
        DEFB ZRLIN
        POP DE
        LD A, (DE)
        RET C
        LD A, ($0C0B)
        CP $02
        SCF
        RET NZ
        RST $18
        DEFB ZARGS
        LD B, H
        LD C, L
        OR A
        DEC HL
        SBC HL, DE
        CCF
        RET

NEXTAD: LD HL, ($0E4C)
        DEC HL
        LD D, (HL)
        DEC HL
        LD E, (HL)
        LD ($0E4C), HL
        PUSH HL
        POP IX
        LD H, D
        LD L, E
        LD BC, ($0E54)
        ADD HL, BC
        LD B, H
        LD C, L
        LD H, (IX-$01)
        LD L, (IX-$02)
        RET


PASS:   LD ($0E01), HL
        LD HL, ($0E50)
        LD ($0E52), HL
        LD HL, ($0E46)
        LD ($0E4C), HL

PASSL:  CALL NEXTAD
        INC BC
        INC DE
        DEC HL
        CALL REVAS
        CALL NEXTAD
        LD A, L
        AND H
        INC A
        RET Z
        LD A, ($0E44)
        AND $80
        JR Z, PASSL
        LD DE, ($0E06)
        SBC HL, DE
        JR C, PASSL
        INC HL
        PUSH HL

DATA1:  CALL INITB
        LD B, $03

DATA2:  CALL BYTE
        POP HL
        DEC HL
        LD A, L
        OR H
        PUSH HL
        JR Z, DATA3
        DJNZ DATA2

DATA3:  PUSH AF
        CALL NOTVAL
        LD HL, $0E14
        CALL PASS2
        POP AF
        JR NZ, DATA1
        POP HL
        JR PASSL


PASS1:  LD HL, ($0E12)
        LD A, L
        OR H
        RET Z
        LD HL, ($0E50)

SRCHL:  LD A, (HL)
        PUSH HL
        POP IY
        INC A
        JR Z, PAST
        LD B, A
        DEC HL
        LD E, (HL)
        DEC HL
        LD D, (HL)
        DEC HL
        PUSH HL
        LD HL, ($0E10)
        AND A
        SBC HL, DE
        POP HL
        JR SRCH1


SRCH0:  DEC HL
        DEC HL

SRCH1:  DJNZ SRCH0
        LD A, ($0E44)
        JR C, PAST
        JR NZ, SRCHL
        BIT 3, A
        RET Z
        LD C, $02
        CALL MVUP

FND:    LD DE, ($0E0E)
        LD (HL), E
        DEC HL
        LD (HL), D
        INC (IY+0)
        RET


PAST:   LD HL, ($0E82)
        INC HL
        INC HL
        LD ($0E82), HL
        PUSH IY
        POP HL
        LD A, ($0E44)
        LD C, $05
        BIT 3, A
        JR NZ, XR
        LD C, $03

XR:     CALL MVUP
        LD (HL), $00
        LD DE, ($0E10)
        DEC HL
        LD (HL), E
        DEC HL
        LD (HL), D
        DEC HL
        BIT 3, A
        RET Z
        JR FND


MVUP:   LD DE, ($0E52)
        INC HL
        AND A
        LD B, $00
        SBC HL, DE
        EX DE, HL
        SBC HL, BC
        LD B, D
        LD C, E
        EX DE, HL
        LD HL, ($0E4E)
        DEC HL
        SBC HL, DE
        JR NC, OVRFLW
        LD HL, ($0E52)
        LD ($0E52), DE
        LDIR
        DEC HL
        RET


OVRFLW: RST PRS
        DEFB $4F
        DEFB $76
        DEFB $65
        DEFB $72
        DEFB $66
        DEFB $6C
        DEFB $6F
        DEFB $77
        DEFB CR,0
        LD HL, $0E14
        CALL OUTLIN
        RST $18
        DEFB $5B

PASS2:  LD BC, $0013
        LD IY, $0E58
        PUSH HL
        POP IX
        ADD IX, BC
        LD A, ($0E44)
        BIT 0, A
        JR Z, KEEPO
        ADD HL, BC
        ADD IY, BC

KEEPO:  BIT 4, A
        JR Z, OUTPUT
        PUSH HL
        CALL LABEL
        LD HL, ($0E12)
        LD A, L
        OR H
        JR Z, NOLB
        LD (HL), $4C

NOLB:   POP HL

OUTPUT: LD B, H
        LD C, L
        LD HL, ($0E4A)
        LD DE, ($0E0E)
        AND A
        SBC HL, DE
        RET C
        LD HL, ($0E48)
        EX DE, HL
        SBC HL, DE
        RET C
        PUSH BC
        LD A, ($0E44)
        PUSH AF
        BIT 5, A
        CALL NZ, DPAGE
        POP AF
        POP HL
        PUSH AF
        RRCA
        JR NC, ALLLIN
        EX DE, HL
        LD HL, $0009
        ADD HL, DE
        LD A, (HL)
        EX DE, HL
        LD DE, $0E58
        LD BC, $203B
        SUB $42
        JR NZ, SQSH1
        LD C, A

SQSH1:
        LD A, (HL)
        CP CR
        JR Z, SQSH3
        CP C
        JR Z, SQSH3
        LD (DE), A
        INC DE
        INC HL
        CP $2F
        JR NZ, SQSH2
        LD A, B
        CPL
        LD B, A
        LD A, C
        CPL
        LD C, A

SQSH2:
        CP B
        JR NZ, SQSH1
        CP (HL)
        JR NZ, SQSH1
        INC HL
        JR SQSH2


SQSH3:  EX DE, HL
        DEC HL
        LD A, (HL)
        CP $20
        JR Z, SQSH4
        INC HL

SQSH4:  LD (HL), CR
        LD HL, $0E58

ALLLIN: CALL OUTLIN
        POP AF
        BIT 2, A
        RET Z
        LD DE, ($0E80)
        LD HL, ($0E56)
        INC HL
        LD (HL), E
        INC HL
        LD (HL), D
        INC HL
        EX DE, HL
        LD A, $01
        ADD A, L
        DAA
        LD L, A
        LD A, $00
        ADC A, H
        DAA
        LD H, A
        LD ($0E80), HL
        LD HL, $0E58
        LD A, CR

Z1:     LDI
        CP (HL)
        JR NZ, Z1
        EX DE, HL
        LD ($0E56), HL
        LD (HL), $00
        INC HL
        LD (HL), $FF
        INC HL
        PUSH HL
        LD DE, ($0F00)
        SBC HL, DE
        EX DE, HL
        LD (HL), E
        INC HL
        LD (HL), D
        POP DE
        LD HL, ($0E4E)
        SBC HL, DE
        RET NC
        JP OVRFLW


OUTLIN: LD B, (HL)
        CALL CHROUT
        INC HL
        CP CR
        JR NZ, OUTLIN
        RET


LABEL:  LD HL, ($0E52)
        LD A, (HL)
        INC A
        RET Z
        LD B, A
        DEC HL
        LD E, (HL)
        DEC HL
        LD D, (HL)
        DEC HL
        JR LABEL1


LABEL0: DEC HL
        DEC HL

LABEL1: DJNZ LABEL0
        LD B, H
        LD C, L
        LD HL, ($0E0E)
        LD A, ($0E44)
        RLCA
        CCF
        JR C, LABEL2
        SBC HL, DE
        RET C

LABEL2: LD ($0E52), BC
        JR Z, ALAB
        LD B, H
        LD C, L
        PUSH BC
        LD B, $13
        LD HL, $0E58

CEQUB:  LD (HL), $20
        INC HL
        DJNZ CEQUB
        PUSH AF
        CALL ALAB1
        POP AF
        PUSH HL
        LD HL, EQU
        LD BC, $0006
        LDIR
        EX DE, HL
        POP DE
        POP BC
        RRCA
        JR NC, ABSOL
        LD A, B
        AND A
        JR NZ, ABSOL
        LD A, C
        CP $05
        JR NC, ABSOL
        LD (HL), $24
        INC HL
        LD (HL), $2D
        INC HL
        OR $30
        LD (HL), A
        INC HL
        JR PEQU

ABSOL:  LD (HL), $23
        INC HL
        EX DE, HL
        CALL HEX4
        EX DE, HL

PEQU:   LD (HL), CR
        PUSH IY
        POP HL
        CALL OUTPUT
        JR LABEL


ALAB:   PUSH IX
        POP HL

ALAB1:  LD (HL), $4C
        INC HL
        EX DE, HL
        JP HEX4

DPAGE:  LD HL, $0E7C
        DEC (HL)
        RET NZ

EJECT:  LD A, ($0E7D)
        ADD A, (HL)
        LD D, A
        LD B, CR
        JR EJ1

EJ0:    CALL CHROUT

EJ1:    DEC D
        JR NZ, EJ0
        LD HL, ($0E7E)
        LD ($0E7C), HL
        LD HL, $0E8D
        INC (HL)
        LD A, (HL)
        CP $3A
        JR NZ, NOINC
        LD (HL), $30
        DEC HL
        INC (HL)

NOINC:  LD HL, $0E84
        CALL OUTLIN
        LD B, CR

CHROUT: LD A, B
        RST ROUT
        PUSH HL
        LD HL, $0E44
        CALL PUNCH
        CP CR
        JR NZ, EXCHR
        LD A, $0A
        CALL PUNCH
        LD A, ($0E45)
        CP $20
        JR Z, WAIT
        RST $18
        DEFB $62
        JR NC, NOWT

WAIT:   RST RIN
        LD ($0E45), A

NOWT:   CP $1B
        JP Z, EXIT
        LD A, B
        BIT 6, (HL)
        JR Z, EXCHR
        PUSH BC
        LD B, $80

DLOOP:  RST $38
        DJNZ DLOOP
        POP BC
        LD A, B

EXCHR:  POP HL
        RET


PUNCH:  BIT 1, (HL)
        RET Z
        RST $18
        DEFB $6F
        RET


RAMLD:  DEFW L_0010, $0000
        DEFB $20, $20, $20, $50, $41, $47, $45, $20, $30, $30, $20, $20, $20, $20

EQU:    DEFB $20, $45, $51, $55, $20, $20

L_CFFD:
        JP REVAS




; $C000 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBCBCCCCCCCCCB
; $C030 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $C080 CCCCBCCCBCCCCCCCCCCCCCCCCCCCCCBCCCBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $C0D0 CCCBCBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBCBCCBCCCCCCCCCCCCCCC
; $C120 CCCCCCCCCCCCBCCCCCBCCBCCCCCCCCCCCCCCCBCCBCCCCCBCCCCCCCBCCCCCCCCCCCBCCCCCCCCCCCCC
; $C170 CCCCCBCCCCCCCCCCBCCCCCCCCCCCCCCCCCCBCCCCCCBCCCCBCCCCCBCCCCCCCCCCCCCCCBCCCCCCCCBC
; $C1C0 CCCBCCCCCCCBCCCCCCCCCCCCCCCCCCCCCCCCCBCBCCCCCCCCCCCBBBBCCCCBCCCCCCCCBCBBBBCCCCBC
; $C210 BBBBBBBCCCCCCCCCCBBBBCCCCBCBBBBCCCCCCCCBCBBBCCCCCCCBBBCBCCCCCCCCCCCBCCCCCCCCCCCB
; $C260 CBBBBCCCCBCCCCCCCCCCCCCCCCCCCCCBBCCCBCCCCCCBCCCCBCCCCCCCCCCCCCCCCBCCCCCCCBCCBCBC
; $C2B0 CCCCCCCCCCCCCCBBBBCCCCCCCCCCCCCCCCCCCCCCCBBBBCCCBCCCCCCCCCCCCCCCCCCBCCBCCBCCCCCC
; $C300 CCCCCCCBCCBCCCCCCCBCCCCCCCCCBCBCCCCCCCCBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $C350 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBCCCCCCCCBCCCCCCCCCCCCCC
; $C3A0 CCCCCCCCCCCCBCCCCCCCCCCCCCCCCCCCBCBBBBBBBBBWWBWWBWWBWWBWWBWWBWWBWWWWWWWWWWWWWWWW
; $C3F0 WWWWWWWWWWWWWWWWCCCCCCCCCCCCCCCCCCCCCCCBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBCC
; $C440 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $C490 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $C4E0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $C530 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $C580 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $C5D0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $C620 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $C670 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $C6C0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $C710 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $C760 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $C7B0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $C800 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $C850 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $C8A0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $C8F0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $C940 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCWWWWWWWWWWWWWWWWW
; $C990 WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $C9E0 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $CA30 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
; $CA80 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBCCCCCCCCCCCCBBBBBBBBB
; $CAD0 BBBBBBBBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBBBBB
; $CB20 CCCBBBBBBBBBBBCBBBBBBBBBBCCCCCCCCCCCCCCCCCCCCCCBBBBBBBBCBCCCCCCCCCCBCCCCCCCCCCCC
; $CB70 CCCCCCCCCCCCCCCCCCCCCCCBBBBBBBBBBCBCBCCCCCCCCCCBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $CBC0 CCCCCCCBBBBBBBBBBBBBBBBCCCCCCCCCCCCCCBBBBBBBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $CC10 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBBCCCBCBBBBCCCCCCCCCCCCBBBBCBCCCCBCCCCCCCCCCC
; $CC60 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBCCCCCCCCCCCC
; $CCB0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCB
; $CD00 CCCCCBCCCCCCCCCCCBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $CD50 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $CDA0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $CDF0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBBBBBBBBBBCCCCCCCBCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $CE40 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $CE90 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $CEE0 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $CF30 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
; $CF80 CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCBCCCCCCCCCCC
; $CFD0 CCCCCCCCCCCCCCCCCCCBCWWWWBBBBBBBBBBBBBBBBBBBBCC

; Labels
;
; $0008 => L_0008        ABSOL  => $CF5F
; $000D => STMON         ADCSBC => $C891
; $0010 => L_0010        ADDHL  => $C568
; $0018 => L_0018        ALAB   => $CF71
; $0028 => L_0028        ALAB1  => $CF74
; $0030 => L_0030        ALLIN0 => $CC8C
; $0038 => L_0038        ALLLIN => $CEAE
; $0E00 => L_0E00        ALT    => $C2A2
; $C000 => DEBUG         ALTN   => $C2A0
; $C003 => START         ALTP   => $C09D
; $C026 => DENT          ARITH8 => $C604
; $C02B => SSTEP         ARTAB  => $C9D8
; $C03C => CMND          AS0    => $C89D
; $C048 => PNORM         ASKT   => $CB4E
; $C04D => DCMND         AUTO   => $C86C
; $C067 => PA1           AUTO0  => $C886
; $C075 => PA2           B2HCR  => $C2AB
; $C087 => DERR          BACK   => $CB7F
; $C089 => DPJ           BDUN   => $C35B
; $C08B => DPEND         BORM   => $C6B0
; $C093 => DP2           BOUT   => $C2CC
; $C09D => ALTP          BRSTAB => $CA52
; $C0A1 => TIN           BRSTO  => $C138
; $C0AA => EXCH          BSPBM  => $CA44
; $C0B7 => EX1           BYTE   => $C4B8
; $C0CB => CUR1          BYTE0  => $C4E0
; $C0CF => DPARSE        CALETC => $C637
; $C0EE => RNAM          CB     => $C80D
; $C0F4 => TSTREG        CBETC  => $C77C
; $C101 => EDERR         CCODES => $C67C
; $C103 => FOUND         CCTAB  => $CA04
; $C10C => FIN           CDUN   => $C363
; $C119 => SPLINE        CE0    => $C647
; $C11E => UPONE         CEQUB  => $CF31
; $C126 => REDO          CHROUT => $CFAA
; $C133 => NOMOP         CHUSR  => $C3AE
; $C136 => PAJ           CJR    => $C657
; $C138 => BRSTO         CJRTAB => $C9F8
; $C143 => RETURN        CMND   => $C03C
; $C144 => EDFIND        COMMA  => $C4F7
; $C155 => VALUES        COMP   => $C37D
; $C158 => GBDEC         COPY2  => $C50B
; $C15C => GBL           COPY3  => $C509
; $C15F => GBY           COPY3S => $C738
; $C160 => GB1           COPY4  => $C507
; $C16B => ERJ           COPY5  => $C505
; $C174 => XYC           COPY6  => $C503
; $C17E => JUMP          COPYT  => $CB77
; $C17F => PCR           CRRET  => $C2AD
; $C187 => IXY           CTAB   => $C3E0
; $C197 => IYR           CUR1   => $C0CB
; $C19E => SPR           DA     => $CBDC
; $C1A3 => IMAGEV        DAREA  => $CBE4
; $C1B4 => NUMBR         DAREA0 => $CBF4
; $C1BD => REGN          DAREA1 => $CC20
; $C1BF => REGDIS        DAREA2 => $CC37
; $C1CA => SPDIS         DAREA3 => $CC40
; $C1E2 => RD1           DATA1  => $CD67
; $C1EC => SSD           DATA2  => $CD6C
; $C21F => IFF           DATA3  => $CD78
; $C271 => PCL           DCMND  => $C04D
; $C27A => PRC           DEBUG  => $C000
; $C294 => RV1           DEC    => $C538
; $C2A0 => ALTN          DECM   => $C9C2
; $C2A2 => ALT           DECODE => $C515
; $C2AB => B2HCR         DEFB   => $CAB7
; $C2AD => CRRET         DEI    => $C776
; $C2B0 => REVAD         DENT   => $C026
; $C2BD => REVOUT        DERR   => $C087
; $C2C2 => REVO2         DI     => $C770
; $C2C4 => REVO          DJNZ   => $C73E
; $C2CC => BOUT          DJNZM  => $CA3A
; $C2D8 => REVO3         DLOOP  => $CFD8
; $C2DF => SPCS          DNV    => $C973
; $C2E4 => STLIN         DONEM  => $C6D1
; $C2EE => REVENT        DP2    => $C093
; $C2F4 => RM1           DPAGE  => $CF7B
; $C2F5 => RM2           DPARSE => $C0CF
; $C2F8 => INP           DPEND  => $C08B
; $C306 => NL            DPJ    => $C089
; $C319 => FIND          DSCALJ => $C3B6
; $C325 => MORE          EDERR  => $C101
; $C32F => STORE         EDFIND => $C144
; $C331 => L_C331        EI     => $C774
; $C33A => NOARGS        EJ0    => $CF89
; $C345 => MINUS         EJ1    => $CF8C
; $C34C => FERR          EJECT  => $CF80
; $C34F => FLAG          EQU    => $CFF7
; $C354 => F2            ERJ    => $C16B
; $C35B => BDUN          EX1    => $C0B7
; $C363 => CDUN          EXAETC => $C747
; $C366 => NEXT          EXAFM  => $CA3E
; $C375 => FTEST         EXCH   => $C0AA
; $C37D => COMP          EXCHR  => $CFDD
; $C389 => NEXTJ         EXIT   => $CCA2
; $C38D => PHA           EXTMNE => $CA8E
; $C39C => PRA           EXTND  => $C8C9
; $C3A7 => PRA2          EXX    => $C7BD
; $C3AE => CHUSR         F2     => $C354
; $C3B2 => OPTN          FERR   => $C34C
; $C3B6 => DSCALJ        FIN    => $C10C
; $C3C2 => STR           FIND   => $C319
; $C3CA => REGTAB        FLAG   => $C34F
; $C3E0 => CTAB          FLUSH  => $C6E9
; $C41C => SCO           FND    => $CDBB
; $C428 => PRINT         FOUND  => $C103
; $C43E => REVAS         FTADR  => $C510
; $C449 => NEXTL         FTEST  => $C375
; $C46E => INITB         GB1    => $C160
; $C48E => INITB0        GBDEC  => $C158
; $C49D => HEX4          GBL    => $C15C
; $C4A2 => HEX2          GBY    => $C15F
; $C4AB => HEX1          GETSTA => $CB11
; $C4B8 => BYTE          GETTWO => $CCFE
; $C4E0 => BYTE0         HALT   => $C5FE
; $C4E5 => WREX          HALTM  => $C9D4
; $C4ED => WRLD          HEX1   => $C4AB
; $C4F3 => WRLD0         HEX2   => $C4A2
; $C4F7 => COMMA         HEX4   => $C49D
; $C4FD => POUND         HXYTAB => $C9CE
; $C503 => COPY6         ID0    => $C53B
; $C505 => COPY5         IFF    => $C21F
; $C507 => COPY4         IMAGEV => $C1A3
; $C509 => COPY3         IMM    => $C5F5
; $C50B => COPY2         IN     => $C8A0
; $C510 => FTADR         INA    => $C8C3
; $C515 => DECODE        INC    => $C533
; $C533 => INC           INCM   => $C9BF
; $C538 => DEC           INITB  => $C46E
; $C53B => ID0           INITB0 => $C48E
; $C548 => LD16          INM    => $CA49
; $C552 => LD16A         INP    => $C2F8
; $C55B => LD16B         INRC   => $C8A2
; $C568 => ADDHL         INTMOD => $C948
; $C56B => L_C56B        IRTAB  => $CAAE
; $C576 => L_C576        IXY    => $C187
; $C577 => REGPR         IYR    => $C197
; $C58D => NOTSP         JPETC  => $C755
; $C597 => L_C597        JR     => $C712
; $C59D => LOAD8         JUMP   => $C17E
; $C5AF => L8B           KEEPO  => $CE3B
; $C5B4 => SREG          L8B    => $C5AF
; $C5C4 => MEM           L_0008 => $0008
; $C5E8 => PLUS          L_0010 => $0010
; $C5F0 => NOTIXY        L_0018 => $0018
; $C5F5 => IMM           L_0028 => $0028
; $C5F8 => PHEX2         L_0030 => $0030
; $C5FE => HALT          L_0038 => $0038
; $C604 => ARITH8        L_0E00 => $0E00
; $C628 => POP           L_C331 => $C331
; $C62D => PUSH          L_C56B => $C56B
; $C630 => PP0           L_C576 => $C576
; $C637 => CALETC        L_C597 => $C597
; $C647 => CE0           L_C658 => $C658
; $C657 => CJR           L_C7EB => $C7EB
; $C658 => L_C658        L_C7EC => $C7EC
; $C679 => UNCND         L_C804 => $C804
; $C67C => CCODES        L_C8C0 => $C8C0
; $C686 => ROTMIS        L_CAC6 => $CAC6
; $C693 => RST           L_CBF3 => $CBF3
; $C6B0 => BORM          L_CFFD => $CFFD
; $C6C5 => MOREMS        LABEL  => $CF02
; $C6CD => MS1           LABEL0 => $CF10
; $C6D1 => DONEM         LABEL1 => $CF12
; $C6D6 => UN0           LABEL2 => $CF23
; $C6D9 => UNPRN         LD1    => $C7E9
; $C6E4 => UN1           LD16   => $C548
; $C6E9 => FLUSH         LD16A  => $C552
; $C6FC => PRTABL        LD16B  => $C55B
; $C700 => PRTB1         LD16I  => $C803
; $C70B => NOPETC        LDIND  => $C7D9
; $C712 => JR            LDRI   => $C93C
; $C727 => UCD           LDSP   => $C7AF
; $C735 => NOP           LOAD8  => $C59D
; $C738 => COPY3S        LUOP   => $CAF6
; $C73E => DJNZ          MEM    => $C5C4
; $C747 => EXAETC        MINUS  => $C345
; $C755 => JPETC         MORE   => $C325
; $C770 => DI            MOREMS => $C6C5
; $C774 => EI            MS1    => $C6CD
; $C776 => DEI           MVUP   => $CDEF
; $C77C => CBETC         NEXT   => $C366
; $C798 => RETETC        NEXTAD => $CD1A
; $C7AF => LDSP          NEXTJ  => $C389
; $C7BD => EXX           NEXTL  => $C449
; $C7C4 => STIND         NL     => $C306
; $C7D4 => ST1           NLABS  => $CB49
; $C7D9 => LDIND         NOARGS => $C33A
; $C7E9 => LD1           NOINC  => $CFA2
; $C7EB => L_C7EB        NOLB   => $CE4C
; $C7EC => L_C7EC        NOMOP  => $C133
; $C7FA => ST16I         NOP    => $C735
; $C803 => LD16I         NOPETC => $C70B
; $C804 => L_C804        NOPM   => $CA37
; $C80D => CB            NOTIN  => $C8E9
; $C81F => NOTXY         NOTITL => $CB86
; $C845 => TESTXY        NOTIXY => $C5F0
; $C853 => ROTATE        NOTLD  => $C91D
; $C86C => AUTO          NOTOUT => $C904
; $C886 => AUTO0         NOTSP  => $C58D
; $C891 => ADCSBC        NOTVAL => $C953
; $C89D => AS0           NOTXY  => $C81F
; $C8A0 => IN            NOWT   => $CFCB
; $C8A2 => INRC          NTVL   => $C951
; $C8B5 => PORT          NUMBR  => $C1B4
; $C8C0 => L_C8C0        NVLP   => $C964
; $C8C3 => INA           ONLY2  => $CBB2
; $C8C9 => EXTND         OPT0   => $CAEB
; $C8E9 => NOTIN         OPT1   => $CB09
; $C8EC => OUT           OPTAB  => $CA70
; $C904 => NOTOUT        OPTN   => $C3B2
; $C91D => NOTLD         OTAB   => $CAD2
; $C93C => LDRI          OUT    => $C8EC
; $C948 => INTMOD        OUTLIN => $CEF8
; $C951 => NTVL          OUTM   => $CA4C
; $C953 => NOTVAL        OUTPUT => $CE4D
; $C964 => NVLP          OVRFLW => $CE12
; $C973 => DNV           PA1    => $C067
; $C97F => TABLE         PA2    => $C075
; $C9BF => INCM          PAJ    => $C136
; $C9C2 => DECM          PASS   => $CD37
; $C9C8 => RPRTAB        PASS1  => $CD88
; $C9CE => HXYTAB        PASS2  => $CE25
; $C9D4 => HALTM         PASSL  => $CD46
; $C9D8 => ARTAB         PAST   => $CDC6
; $C9F0 => PUSHM         PCL    => $C271
; $C9F4 => POPM          PCR    => $C17F
; $C9F8 => CJRTAB        PCRT   => $CCA4
; $CA04 => CCTAB         PEQU   => $CF67
; $CA14 => RMTAB         PHA    => $C38D
; $CA34 => RSTM          PHEX2  => $C5F8
; $CA37 => NOPM          PLUS   => $C5E8
; $CA3A => DJNZM         PNORM  => $C048
; $CA3E => EXAFM         POP    => $C628
; $CA44 => BSPBM         POPM   => $C9F4
; $CA49 => INM           PORT   => $C8B5
; $CA4C => OUTM          POUND  => $C4FD
; $CA4F => SPM           PP0    => $C630
; $CA52 => BRSTAB        PRA    => $C39C
; $CA5B => ROTTAB        PRA2   => $C3A7
; $CA70 => OPTAB         PRC    => $C27A
; $CA82 => REMEXT        PRINT  => $C428
; $CA8E => EXTMNE        PRTABL => $C6FC
; $CAAE => IRTAB         PRTB1  => $C700
; $CAB7 => DEFB          PUNCH  => $CFDF
; $CABB => REVASC        PUSH   => $C62D
; $CAC6 => L_CAC6        PUSHM  => $C9F0
; $CAD2 => OTAB          RAMLD  => $CFE5
; $CAE4 => XFOUND        RD1    => $C1E2
; $CAEB => OPT0          REDO   => $C126
; $CAF6 => LUOP          REGDIS => $C1BF
; $CB09 => OPT1          REGN   => $C1BD
; $CB11 => GETSTA        REGPR  => $C577
; $CB22 => ST            REGTAB => $C3CA
; $CB2E => ST0           REMEXT => $CA82
; $CB49 => NLABS         RETETC => $C798
; $CB4E => ASKT          RETURN => $C143
; $CB69 => SETLPP        REVAD  => $C2B0
; $CB77 => COPYT         REVAS  => $C43E
; $CB7F => BACK          REVASC => $CABB
; $CB86 => NOTITL        REVENT => $C2EE
; $CBB2 => ONLY2         REVO   => $C2C4
; $CBC6 => RNGRQ         REVO2  => $C2C2
; $CBDC => DA            REVO3  => $C2D8
; $CBE4 => DAREA         REVOUT => $C2BD
; $CBF3 => L_CBF3        RM1    => $C2F4
; $CBF4 => DAREA0        RM2    => $C2F5
; $CC20 => DAREA1        RMTAB  => $CA14
; $CC37 => DAREA2        RNAM   => $C0EE
; $CC40 => DAREA3        RNGRQ  => $CBC6
; $CC8C => ALLIN0        ROTATE => $C853
; $CCA2 => EXIT          ROTMIS => $C686
; $CCA4 => PCRT          ROTTAB => $CA5B
; $CCBC => XREF1         RPRTAB => $C9C8
; $CCCA => XREF2         RST    => $C693
; $CCE0 => XREF3         RSTM   => $CA34
; $CCF4 => XREF4         RV1    => $C294
; $CCFE => GETTWO        SCO    => $C41C
; $CD1A => NEXTAD        SETLPP => $CB69
; $CD37 => PASS          SPCS   => $C2DF
; $CD46 => PASSL         SPDIS  => $C1CA
; $CD67 => DATA1         SPLINE => $C119
; $CD6C => DATA2         SPM    => $CA4F
; $CD78 => DATA3         SPR    => $C19E
; $CD88 => PASS1         SQSH1  => $CE83
; $CD91 => SRCHL         SQSH2  => $CE98
; $CDA8 => SRCH0         SQSH3  => $CEA1
; $CDAA => SRCH1         SQSH4  => $CEA9
; $CDBB => FND           SRCH0  => $CDA8
; $CDC6 => PAST          SRCH1  => $CDAA
; $CDDC => XR            SRCHL  => $CD91
; $CDEF => MVUP          SREG   => $C5B4
; $CE12 => OVRFLW        SSD    => $C1EC
; $CE25 => PASS2         SSTEP  => $C02B
; $CE3B => KEEPO         ST     => $CB22
; $CE4C => NOLB          ST0    => $CB2E
; $CE4D => OUTPUT        ST1    => $C7D4
; $CE83 => SQSH1         ST16I  => $C7FA
; $CE98 => SQSH2         START  => $C003
; $CEA1 => SQSH3         STIND  => $C7C4
; $CEA9 => SQSH4         STLIN  => $C2E4
; $CEAE => ALLLIN        STMON  => $000D
; $CED4 => Z1            STORE  => $C32F
; $CEF8 => OUTLIN        STR    => $C3C2
; $CF02 => LABEL         TABLE  => $C97F
; $CF10 => LABEL0        TESTXY => $C845
; $CF12 => LABEL1        TIN    => $C0A1
; $CF23 => LABEL2        TSTREG => $C0F4
; $CF31 => CEQUB         UCD    => $C727
; $CF5F => ABSOL         UN0    => $C6D6
; $CF67 => PEQU          UN1    => $C6E4
; $CF71 => ALAB          UNCND  => $C679
; $CF74 => ALAB1         UNPRN  => $C6D9
; $CF7B => DPAGE         UPONE  => $C11E
; $CF80 => EJECT         VALUES => $C155
; $CF89 => EJ0           WAIT   => $CFC7
; $CF8C => EJ1           WREX   => $C4E5
; $CFA2 => NOINC         WRLD   => $C4ED
; $CFAA => CHROUT        WRLD0  => $C4F3
; $CFC7 => WAIT          XFOUND => $CAE4
; $CFCB => NOWT          XR     => $CDDC
; $CFD8 => DLOOP         XREF1  => $CCBC
; $CFDD => EXCHR         XREF2  => $CCCA
; $CFDF => PUNCH         XREF3  => $CCE0
; $CFE5 => RAMLD         XREF4  => $CCF4
; $CFF7 => EQU           XYC    => $C174
; $CFFD => L_CFFD        Z1     => $CED4
