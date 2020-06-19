;;; test program for NASCOM VDU memory
;;;
;;; design goals:
;;; - ROM-able
;;; - relocatable
;;; - use no workspace RAM
;;; - use no stack
;;;
;;; Using the 1st character of video RAM as a "seed" write an
;;; incrementing pattern to the entire 1K of the video RAM and
;;; then HALT. Therefore, although the initial screen image
;;; is unpredictable, it should should change in a predictable
;;; way each time RESET is pressed.
;;;
;;; To make each line different, do a double increment at the
;;; start of each line. So, the pattern will look like this:
;;; abcdefghi..
;;; bcdefghij..
;;; cdefghijk..
;;;
;;; Remember that NASCOM video addressing is weird: the lines
;;; from top to bottom are 16, 1..15. So, the pattern for the
;;; top line (line 16) follows on from the pattern of the
;;; bottom line (line 15). Also, each line is 64 bytes of RAM
;;; even though only 48 are visible.
;;;
;;; As a debugging aid, there is an IO access every 64 bytes,
;;; at the start of each line.
;;;
        org 0                   ;but relocatable
start:  ld hl, 0x800            ;start of video RAM
        ld a, (hl)
        inc a                   ;seed value
        ld b, 16                ;number of lines
nline:  ld c, 64                ;characters per line. 16*64=1K, whole of RAM
        out (3),a               ;port 3 is unused but decoded on IC36/9
line:   ld (hl), a              ;store value
        inc a                   ;next value to use
        inc hl                  ;next address
        dec c
        jr nz, line             ;continue this line
        sub a,63                ;value to use at start of next line
        djnz nline              ;next line
        halt                    ;done.

end:
size:   equ     end - start
        defs    1024 - size
