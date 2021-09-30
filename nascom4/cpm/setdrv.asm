        ;; SETDRV.COM
        ;;
        ;; Utility for CP/M on NASCOM4
        ;;
        ;; The CP/M port supports 16 virtual disks on SDcard
        ;; At boot, virtual disks 0 and 1 are mapped to the 2 logical
        ;; drives (A, B if booting from SDcard; C, D if booting from floppy)
        ;;
        ;; Usage:
        ;;
        ;; SETDRV A 4    -- mount disk 4 on drive A
        ;; SETDRV B A    -- mount disk 10 on drive B
        ;; SETDRV A7     -- this is also legal.. mount disk 7 on drive A
        ;; SETDRV        -- report mounts
        ;;
        ;; When referring to drives, A,B,C,D are legal values; A and C
        ;; are synonyms for the 1st SDdrive and B and D are synonyms for
        ;; the 2nd SDdrive.
        ;; When referring to virtual disks, legal values are 0-F
        ;;
        ;; Bugs/Assumptions:
        ;; - assumes only 2 SDdrives and no more than 2 floppy drives.
        ;; - at 3/4Kbytes, this seems large for such a trivial program.
        ;;
        ;; foofoobedoo@gmail.com
        ;; 12Sep2021

START:  EQU     $100

;;; Equates for CP/M
BDOS:   EQU     $5
WARM:   EQU     $0
CLBUF:  EQU     $80
PRS:    EQU     $9
SBYTE:  EQU     $c4             ;offset from start of BIOS to 'S'

;;; Equates for this program
SDBASE: EQU     $84
CR:     EQU     $0d
LF:     EQU     $0a

        ORG     START

        ;; Parse the command line. The command line is at 80H. The first
        ;; byte is the length, and the rest is converted to upper-case but
        ;; is otherwise as-typed, with leading and trailing spaces intact,
        ;; and terminated with a 0.

        ;; (alternative would be to realise these are all hex numbers
        ;; and to have a sub to parse a number, then range test the result..
        ;; and a flag to show if the result is valid.)

SETDRV:
        LD      HL,CLBUF+1      ;skip length byte
PARSE1: LD      A,(HL)
        INC     HL
        CP      ' '
        JR      z,PARSE1        ;skip leading spaces
        OR      A
        JR      z,NOARG         ;end => no arguments

        ;; expect one of: A B C D
        CP      'A'
        JR      C,BAD1          ;drive spec error
        CP      'E'
        JR      NC,BAD1
        LD      B,A             ;drive in B

        ;; skip zero or more spaces
PARSE2: LD      A,(HL)
        INC     HL
        CP      ' '
        JR      Z,PARSE2        ;skip leading spaces
        OR      A
        JR      Z,BAD2          ;end => disk spec error

        ;; expect one of: '0'-'9', 'A'-'F'
        SUB     A,'0'
        JR      C,BAD2          ;disk spec error
        CP      0AH
        JR      c,DISKOK        ;disk 0-9
        SUB     A,'A' - '0'
        JR      C,BAD2
        CP      $6
        JR      NC,BAD2
        ADD     A,10

        ;; disk in A; 0-F
DISKOK:
        LD      C,A

        CALL    GETWS1

        ;; Everything is checked and ready to go
        ;; HL-1 stores drive 0 (A/C) disk + base
        ;; HL   stores drive 1 (B/D) disk + base
        ;;
        ;; drive is in B
        ;; disk  is in C

        LD      a,b             ;'A' 'B' 'C' or 'D'
        AND     1               ;0 => 'B' or 'D' (drive 1)
        JR      z, DRIVE        ;want drive 1
        DEC     HL              ;drive 0 storage
DRIVE:  LD      A,C
        SLA     A
        SLA     A
        SLA     A
        OR      SDBASE

        LD      (HL),A          ;done!
        JR      XIT

;;; no args => report current mounted files and exit
NOARG:  CALL    GETWS1
        CALL    DRV2ASC
        LD      (DRV1),A

        DEC     HL
        CALL    DRV2ASC
        LD      (DRV0),A

        LD      C,PRS
        LD      DE,MSGINFO
        CALL    BDOS
        JR      XIT

BAD1:   LD      DE,MSGBAD1
        JR      BADXIT
BAD2:   LD      DE,MSGBAD2
        JR      BADXIT
BAD3:   LD      DE,MSGBAD3
BADXIT: LD      C,PRS
        call    BDOS
XIT:    JP      WARM

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ;; SUBROUTINE GETWS1
        ;;
        ;; Return with HL pointing to the BIOS workspace storage
        ;; for SD drive1 (HL-1 is the storage for SD drive 0)
        ;;
        ;; Fatal error/exit with message if workspace layout
        ;; is not as expected.
        ;;
        ;; A, DE, Flags modified
        ;;
        ;; In the running system, address 0 contains a jump to
        ;; address 3 in the BIOS (JP WARM)
        ;; The BIOS starts with a set of jumps, followed by an
        ;; area of workspace defined by MAP80 systems. I added
        ;; 4 bytes at the end of that workspace, and those 4 bytes
        ;; are at offset 0C4H from the start of the BIOS.
        ;;
        ;; 1st byte: 'S'
        ;; 2nd byte: bits 15:8 of block start address of 1st drive's disk
        ;; ..default is 084H
        ;; 3rd byte: bits 15:8 of block start address of 2nd drive's disk
        ;; ..default is 08CH
        ;; 4th byte: 'D'
        ;;
        ;; Checking the S and the D is a sanity-check that the BIOS
        ;; is configured correctly and that this utility is compatible
        ;; with it.
        ;; If I ever built a BIOS with a different number of drives,
        ;; the D would change position and this would be immediately
        ;; apparent.
GETWS1:
        LD      HL,(WARM+1)
        LD      DE,SBYTE-3      ;offset from WARM vector
        ADD     HL,DE
        LD      A,(HL)
        CP      'S'
        JR      NZ,BAD3
        INC     HL
        INC     HL
        INC     HL
        LD      A,(HL)
        CP      'D'
        JR      NZ,BAD3
        DEC     HL              ;drive 1 storage
        RET

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ;; SUBROUTINE DRV2ASC
        ;;
        ;; Enter with HL pointing to a drive storage location
        ;; in the BIOS workspace
        ;; Extract bits 6:3 from the location and convert to
        ;; ASCII 0-9, A-F
        ;; Return the ASCII code in A
        ;;
        ;; A, Flags modified
DRV2ASC:
        LD      A,(HL)
        SRA     A
        SRA     A
        SRA     A
        AND     0FH

        ADD     A,'0'           ;0->'0'
        CP      3AH             ;greater than 9?
        RET     C               ;no; done
        ADD     A,'A'-'0'-10    ;a-f -> 'A'-'F'
        RET

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ;; MESSAGES
MSGINFO:
        DEFM    'Usage:            SETDRV n m'
        DEFB    CR,LF,CR,LF
        DEFM    'Associate drive n (A, B or C, D) with logical disk m (0-9, A-F).'
        DEFB    CR,LF
        DEFM    'Current mappings:'
        DEFB    CR,LF
        DEFM    'Drive A/C: logical disk '
DRV0:   DEFB    ' '
        DEFB    CR,LF
        DEFM    'Drive B/D: logical disk '
DRV1:   DEFB    ' '
        DEFB    CR,LF,'$'

MSGBAD1:
        DEFM   'Bad drive specification'
        DEFB    CR,LF,'$'

MSGBAD2:
        DEFM   'Bad disk specification'
        DEFB    CR,LF,'$'
MSGBAD3:
        DEFM   'Incompatible: SD magic not found in BIOS'
        DEFB    CR,LF,'$'

;;; pad to 512byte multiple to be tidy
SIZE:   EQU $ - START
        DS 300h - SIZE, 0ffh
;;; end
