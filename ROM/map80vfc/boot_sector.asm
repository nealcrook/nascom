;;; First sector of disk for MAP80 VFC CP/M 2.2. The VFC ROM loads this to RAM at $0C00, checks the first 2 bytes
;;; are as expected then jumps to $0C02. Expects disk of 35 tracks * 10 sectors * 2 sides * 512 bytes = 350Kb
L_0000 equ $0000

        org $0C00
        defb $38, $30           ;magic numbers checked by VFC ROM to confirm it's a "system" disk

ENTRY:  ld hl, $D200            ;where in memory to load the image (set by movcpm/build process)
        ld de, $8812            ;88=read command, 12=number of sectors to load (18 sectors = 9K: load at D200-F600)
        ld bc, $01E4            ;01=start at sector 1, E4=FDC data port
        ld a, $02
        out ($EC), a            ;enable or disable ROM at 0? Must have been enabled to get us here so must disable now
                                ;that means we need remap[5]=1
        ld a, $11
        out ($FF), a            ;Gemini memory map port?

RDSECT: ld a, $01
        out ($E4), a            ;drive select: drive 0 (drives are 0..3)
        ld a, b
        out ($E2), a            ;select sector
        ld a, d
        out ($E0), a            ;command 0x88 - read sector
        jr WAIT


MVBYTE: ld (hl), a              ;store byte (data xfer loop)
        inc hl

WAIT:   in a, (c)               ;read data ready bits from external register
        jr z, WAIT
        in a, ($E3)             ;get data, don't change flags
        jp m, MVBYTE
        in a, ($E0)             ;status from FDC
        and $FC
        jr z, NEXT
        ld a, $00               ;??fatal error. Enable the VFC ROM..
        out ($EC), a
        jp L_0000               ;..and jump to it: re-attempt boot process.

NEXT:   inc b                   ;next sector
        ld a, b
        sub $0A                 ;end of track?
        jr nz, NEXT1            ;no; carry on
        ld b, a                 ;back to sector 0
        set 1, d                ;set SIDE=1 in read command

NEXT1:  dec e                   ;decrement sector count
        jr nz, RDSECT           ;go get next sector
        ld hl, ($0C03)          ;argument to HL ie load address: $D200
        ld de, $1600
        add hl, de              ;$D200+$1600=$E800
        jp (hl)                 ;Go there and never come back

        ; Start of unknown area $0C4B to $0DFF
        defb $00, $00, $00, $00, $00
        defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        defb $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        ; End of unknown area $0C4B to $0DFF

