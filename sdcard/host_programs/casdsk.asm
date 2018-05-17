;;; PolyDos utility: CASDSK
;;;
;;; Utility for use with any PolyDos system
;;; https://github.com/nealcrook/nascom
;;;
;;; Load and execute at $0c80 -- needs to be somewhere
;;; out-of-the-way because it stays in memory.
;;;
;;; Allows disk load/store for a program that was designed to
;;; use the W and R tape routines.
;;; Intercepts the W and R routines and redirects them to a
;;; single pre-defined disk file. Acts as a "terminate and stay
;;; resident" program and therefore must sit in free memory
;;; somewhere.
;;;
;;; Example: Colossal cave adventure can "save" the game state
;;; but uses tape routines to do so. So, do this:
;;;   $ CASDSK CAVE.ME
;;;   Installed
;;;   $ COLOSSAL
;;;
;;; Now, any call to the W command (write to tape) will
;;; actually write to the file CAVE.ME, deleting any
;;; pre-existing file of that name. Any call to the R command
;;; (read from tape) will result in the contents of CAVE.ME
;;; being loaded into memory at the address from which it was
;;; saved.
;;;
;;;   $ CASDSK
;;;   Uninstalled
;;;
;;; When executed like this, with no operands, the normal R and
;;; W vectors are restored; The memory used by CASDSK can now be
;;; reused.
;;;
;;;   $ CASDSK
;;;   Not installed
;;;
;;; When executed like this, with no operands, if not previously
;;; installed, just displays a message and returns.
;;;
;;; The usual operation of PolyDos is to read and write data
;;; with a minimal granularity of 256 bytes. When saving, the
;;; same approach is taken: the write data is rounded up to
;;; the nearest 256 bytes. However, that may not be acceptable
;;; on reads, because it may overwrite data in memory.
;;; Therefore, on writes, the valid data size in the final
;;; sector (1-256 bytes) is stored in the low byte of the
;;; "execution address" entry of the data file (CAVE.ME in
;;; the example above). On reads, this size byte is used to
;;; transfer the file size.
;;;
;;; The algorithm can support any file size but the NAS-SYS
;;; calls that are intercepted are limited to a maximum size
;;; of 64Kbyte.
;;;
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

START:  EQU     $0c80

;;; Macros for using NAS-SYS routines
SCAL:   MACRO FOO
        RST 18H
        DB FOO
        ENDM

RCAL:   MACRO FOO
        RST 10H
        DB FOO - $ - 1
        ENDM

;;; Equates for NAS-SYS and PolyDos
        include "SYSEQU.asm"

        ORG     START

;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; CASDSK
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        ;; parse the command line.
casdsk: ld      de, (CLINP)
        ld      a,(de)
        or      a
        jp      nz, chkfil      ;check for file name

;;; invoked with no arguments. See if it's already running. If so, stop it
;;; by restoring the original vectors

        ld      de, mark
        ld      a, (de)
        cp      $55
        jr      nz, never       ;never been run
        inc     de
        ld      a, (de)
        cp      $aa
        jr      nz, never
        xor     a
        ld      (de), a         ;prevent a 2nd uninstall.
        ld      hl,(ord)        ;point to original read vector
        SCAL    ZSSCV
        db      'R'
        ld      hl,(owr)        ;point to original write vector
        SCAL    ZSSCV
        db      'W'
        rst     PRS
        defm    'Uni'           ;Uni..nstalled
        defb    0
        jr      idone

never:  rst     PRS
        defm    'Not i'         ;Not i..nstalled
        defb    0
        jr      idone

;;; invoked with file name. See if it's valid then store it away
chkfil: ld      hl, myfcb
        ld      b,100b          ;drive optional
        SCAL    ZCFS
        SCAL    ZCKER           ;check for error
        ld      a,c
        ld      (mydrv),a       ;preserve drive letter

;;; leave a "fingerprint" to show it's installed
        ld      a, $55
        ld      de, mark
        ld      (de), a
        cpl                     ;a goes $55->$aa
        inc     de
        ld      (de), a

;;; set up new vectors for NAS-SYS R and W commands
        ld      hl, nrd
        SCAL    ZSSCV
        db      'R'
        ld      (ord), hl       ;store original R vector
        ld      hl, nwr
        SCAL    ZSSCV
        db      'W'
        ld      (owr), hl       ;store original W vector
        rst     PRS
        defm    'I'
        defb    00

idone:  rst     PRS             ;exit from install scenarios
        defm    'nstalled'
        defb    0
exitcr: SCAL    ZCRLF
exit:   SCAL    ZMRET           ;go back to command-line

;;;
;;; End of setup. Next is the replacement code for the NAS-SYS R and W commands.
;;;

;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; replacement R routine
;;; ARG1 has a load offset, which we ignore. Everything we need is in the
;;; directory entry from the write.
;;; The filename and drive are taken from workspace at the end of this program.
nrd:    ld      hl,myfcb        ;copy file name from here
        ld      de,S1FCB        ;to here
        ld      bc,10
        ldir
        ld      a,(mydrv)       ;recover drive specifier
        ld      c,a

        SCAL    ZRDIR           ;Read directory (Drive in C)
        SCAL    ZCKER           ;Check for error

        ld      hl,S1FCB
        ld      b,010000b       ;Start at beginning of directory, copy FCB to S1FCB
        SCAL    ZLOOK           ;look for non-locked, non-deleted match

        ;; Response must be either A=$30 (not found) or A=0 (found)
        or      a
        jr      z, found

nofil:  rst     PRS
        defm    'No file'       ;Read without Write
        defb    0
        ret                     ;end of R command, return to caller.

;;; S1FCB now holds complete copy of the FCB
found:  ld      hl, (S1FCB+FNSC) ;sector count
        dec     hl
        push    hl
;;; maximum number of sectors was 0100, so now HL=0000..00ff

;;; Do the data transfer in 2 parts. First part is to transfer all but
;;; the final sector

        ld      a,h
        or      l               ;set Z if no bulk tranfer
        ld      a,(mydrv)
        ld      c,a             ;drive
        jr      z, remain       ;only 1 sector so skip part 1

;;; Data transfer part 1: transfer whole sectors (if any)
        ld      b, l            ;number of sectors to transfer
        ld      hl,(S1FCB+FLDA) ;where to put it
        ld      de,(S1FCB+FSEC) ;1st sector to read
        SCAL    ZDRD            ;read it
        SCAL    ZCKER           ;Check for error

;;; Data transfer part 2: transfer 1 sector via sector buffer.
remain: ld      b,1             ;always 1 sector

        ld      hl,(S1FCB+FSEC)
        ex      de,hl
        pop     hl
        push    hl              ;copy of NSC-1
        xor     a
        adc     hl,de
        ex      de,hl           ;DE= sector to load

        ld      hl,SECBUF       ;where to put it TODO should check command file flag first!!
        SCAL    ZDRD            ;read it
        SCAL    ZCKER           ;Check for error


        pop     de              ;sector count -1. g'teed in range 0000..00ff
        push    hl              ;save SECBUF address

        ld      hl,(S1FCB+FLDA)
;;; Form destination address = HL + 256*DE, in circular number space
;;; already know DE is in range 0000..00ff so multiply is easy..
        ld      d,e
        ld      e,0
        or      a
        adc     hl,de
        ex      de,hl           ;DE= destination

        pop     hl              ;HL= source

        ld      a, (S1FCB+FEXA) ;0 => 256 bytes, set BC=0100 else set BC={0,A}
        ld      b,0
        ld      c,a
        or      a
        jr      nz, valok
        inc     b               ;BC=0100
valok:

;;; HL=source (SECBUF, still) BC=count, DE=destination

        ldir                    ;copy left-over bytes
        ret                     ;end of R command, return to caller.


;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; replacement W routine
;;; ARG1 has the start address, ARG2 has the end address +1.
;;; The filename and drive are taken from workspace at the end of this program.
nwr:    ld      hl,myfcb        ;copy file name from here
        ld      de,S1FCB        ;to here
        ld      bc,10
        ldir
        ld      a,(mydrv)       ;recover drive specifier
        ld      c,a

        SCAL    ZRDIR           ;Read directory (Drive in C)
        SCAL    ZCKER           ;Check for error

        ld      hl,(ARG2)       ;The Write command end address+1
        ld      de,(ARG1)       ;The Write command start address
        push    de              ;Save start address
        xor     a               ;clear carry
        sbc     hl,de           ;Exact byte count in HL

;;; calculate number of sect to write, and left-over byte count for final sector
;;; eg: HL=0001  need sect=0001, final sector left-over=01 (1)
;;;     HL=00ff  need sect=0001, final sector left-over=ff (255)
;;;     HL=0100  need sect=0001, final sector left-over=00 (256)
;;;     HL=0101  need sect=0002, final sector left-over=01 (1)
;;;     HL=ffff  need sect=0100, final sector left-over=ff (255) 64K-1
;;;     HL=0000  need sect=0100, final sector left-over=00 (256) 64K
;;;
;;; it's only a matter of pride that I make the final case work..

        ld      a,l
        ld     (S1FCB+FEXA),a   ;Store left-over byte count in "execute address" for use by R

        or      a
        ld      l,h
        ld      h,0
        jr      z, rup
        inc     l               ;round up to whole number of sectors
rup:

;;; for the 64K case, need to write 0100 (256) sectors. For the directory entry, need to store
;;; a sector count of 0100 but for the call to DWR, have B=0 to indicate 256 sectors.

;;; cope with the case where L=0

        ld      a,l
        or      a               ;set flags
        jr      nz, nwr1
        inc     h               ;64K case, HL=0100 instead of 0000

nwr1:   ld      b,a             ;sector count for DWR: 0 =>256 sectors

        ld      (S1FCB+FNSC),hl ;File length in sectors
        ld      hl,0            ;Clear System/User flag bytes
        ld      (S1FCB+FSFL),hl
        ld      hl,(NXTSEC)     ;Get next free sector
        ld      (S1FCB+FSEC),hl ;Store as start sector address
        ex      de,hl           ;And put into DE

        pop     hl              ;The Write command start address
        ld      (S1FCB+FLDA),hl ;Copy into load address

;;; C has been preserved all through this code; it still holds the drive code.

        ;; HL= mem start address, DE= disk start sector, B= number of sectors
        ;; C= drive
        SCAL    ZDWR            ;Write
        SCAL    ZCKER           ;Check for error
        ld      hl,S1FCB        ;Point to FCB
        call    entr            ;Enter FCB into directory
        SCAL    ZCKER           ;Check for error
        ret                     ;End of W command, return to caller.

;;; SUBROUTINE used by W command
;;; enter into the directory the FCB pointed to by HL. If a file
;;; already exists with the same name it will be deleted, unless it's locked, in
;;; which case, error.
entr:   SCAL    ZENTER          ;Try to enter the file
        ret     z               ;Success; done.
        cp      $31             ;Existing File error?
        ret     nz              ;No; some other error -> caller must handle
        push    hl              ;Save FCB address
        ;; DE now points to the FCB found by "ENTER", HL is our FCB
        ld      hl,FSFL         ;Point to system flag
        add     hl,de           ;byte of directory FCB
        bit     0,(hl)          ;Locked file?
        ld      a,$33           ;Error 33 if so
        jr      nz,skip
        set     1,(hl)          ;Delete the file
        pop     hl              ;Restore FCB address
        jr      entr            ;Retry (TODO: forever!!)
skip:   pop     hl
        ret


;;; pad to 512bytes
size:   equ $ - START
        DS 200h - size, 0ffh

;;; workspace beyond the aligned end of the file, so that it is not overwritten when the
;;; program is run for a second time to restore the original settings
mark:   equ $                   ;aa55 if the program has written the vectors
ord:    equ $+2                 ;original R command vector
owr:    equ $+4                 ;original W command vector
myfcb:  equ $+6                 ;10 bytes (file name only).
mydrv:  equ $+16                ;1byte for drive number
;;; end
