
.include "dd001-romv1.1-direct-jumptable.inc"
.include "dd001-mem.inc"
.include "dd001-sym.inc"
.include "fat12.inc"
.include "geosmac.inc"

COLOR           := $0286                        ; foreground text color
LASTSHIFT	:= $028E			; last pattern of CTRL/SHIFT/C=
CART_COLDSTART  := $8000                        ; cartridge cold start vector
VICBOCL         := $D020                        ; border color
KERNAL_SETLFS   := $FFBA                        ; Set logical file
;KERNAL_SETNAM   := $FFBD                        ; Set file name
KERNAL_OPEN     := $FFC0                        ; Open file
KERNAL_CLOSE    := $FFC3                        ; Close file
KERNAL_CHKIN    := $FFC6                        ; Open channel for input
KERNAL_CLRCHN   := $FFCC                        ; Clear I/O channels
KERNAL_CHRIN    := $FFCF                        ; Get a character from the input channel
;KERNAL_CHROUT   := $FFD2                        ; Output a character
KERNAL_LOAD     := $FFD5                        ; Load file
;KERNAL_STOP     := $FFE1                        ; Check if key pressed (RUN/STOP)
KERNAL_GETIN    := $FFE4                        ; Get a character

; somewhere above the program code, don't have to be page alligned
DataBuffer = $4000
DataBufferLength = $0400		; 2 sectors = 4 pages

	.segment "CODE"

	LoadB	COLOR, 1		; white text
        sta     LASTSHIFT		; why?

	LoadB	VICBOCL, 6		; blue border
	LoadB	MSGFLG, $80		; Kernal messages on(?) (direct mode)
	LoadB	CPU_PORT, $37		; ROM+I/O
	LoadB	VICCTR1, $1B		; screen on

        lda     #$93			; clear screen
        jsr     KERNAL_CHROUT
        cli
        ldy     #0
:	lda     StartupTxt,y		; print startup message
        beq     :+
        jsr     KERNAL_CHROUT
        iny
	bne	:-
;102D
:	lda     #13			; new line (XXX could be embedded in StartupTxt)
        jsr     KERNAL_CHROUT

;1032
MainLoop:
	ldx     #25			; 25 rows of text
:	lda     $D9,x			; something with logical screen organization?
        ora     #$80
        sta     $D9,x
        dex
        bpl     :-

	lda     #$FF
:	cmp     VICLINE			; wait for raster (why?)
        bne     :-

        lda     #'>'			; prompt
        jsr     KERNAL_CHROUT

        ldy     #0
:	jsr     KERNAL_CHRIN		; read user input
        sta     InputBuffer,y
        iny
        sty     InputBufLen
        cmp     #13			; return?
        bne     :-			; no

        ldy     #0
:	lda     InputBuffer,y		; scan user input
        iny
        cmp     #'>'			; skip over '>' prompt
        beq     :-
        cmp     #'R'			; R command?
        bne     :+
        jmp     DoRead			; yes

:	cmp     #'M'			; M command?
        beq     DoMCommand		; yes

        cmp     #'X'			; X command?
        bne     :+
        jmp     (CART_COLDSTART)	; yes

:	cmp     #':'			; : command
        bne     :+
        jmp     DoColon			; yes

:	cmp     #'W'			; W command?
        beq     GoDoWrite		; yes

        cmp     #'C'			; C command?
        beq     GoDoCCommand		; yes

        cmp     #'+'			; + command?
        beq     DoPlus			; yes

        cmp     #'-'			; - commmand?
        beq     DoMinus			; yes

        jmp     MainLoopEnd

DoPlus:
	AddVB	1, LocalSectorL
        lda     LocalSectorH
        adc     #$00
        sta     LocalSectorH
        lda     #13			; new line
        jsr     KERNAL_CHROUT
        jmp     MainLoop

DoMinus:
	lda     LocalSectorL			; not the simplest way of doing it
        subv	1
        bcs     :+
        jmp     MainLoopEnd
:	sta     LocalSectorL
        lda     LocalSectorH
        sbc     #$00
        sta     LocalSectorH
        lda     #13			; new line, could reuse code above
        jsr     KERNAL_CHROUT
        jmp     MainLoop

GoDoWrite:				; yet another way of doing it, each command called differently
	jsr     DoWrite
        jmp     MainLoop

GoDoCCommand:
	jsr     L130C
        lda     L141D
        beq     :+
        jmp     MainLoopEnd

:	jsr     InitStackProg
        sei
	MoveB	LocalSectorL, FdcCLUSTER
	MoveB	LocalSectorH, FdcCLUSTER+1
        jsr     CalcFirst
        jmp     L11B2

DoMCommand:
	LoadB	Pointer, <DataBuffer
	LoadB	Pointer+1, >DataBuffer
	LoadB	L141F, 8-1			; 8 bytes in a row
        ldy     #0
	LoadB	FdcNBUF, $3F			; 64 rows * 8 = 256 bytes
        lda     #13				; new line
        jsr     KERNAL_CHROUT

; display address
@wholerowloop:
	lda     #'>'
        jsr     KERNAL_CHROUT
        lda     #':'
        jsr     KERNAL_CHROUT
        lda     #'0'				; first addres digit is 0
        jsr     KERNAL_CHROUT
        lda     Pointer+1
	subv	$10				; why? it's on $40-$41 so convert that to $30-$31='0'-'1'
        jsr     KERNAL_CHROUT
        tya					; hex digit 3
        and     #$F0
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        tax
        lda     HexDigits,x
        jsr     KERNAL_CHROUT
        tya					; hex digit 4
        and     #$0F
        tax
        lda     HexDigits,x
        jsr     KERNAL_CHROUT

        lda     #' '
        jsr     KERNAL_CHROUT

; display 8 hex bytes
@rowloop:
	lda     (Pointer),y
        and     #$F0
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        tax
        lda     HexDigits,x
        jsr     KERNAL_CHROUT
        lda     (Pointer),y
        iny
        and     #$0F
        tax
        lda     HexDigits,x
        jsr     KERNAL_CHROUT

        lda     #' '
        jsr     KERNAL_CHROUT

        dec     L141F
        bpl     @rowloop

	LoadB	L141F, 8-1		; reset byte counter in a line
        tya
	subv	8			; rewind Y counter too
        tay

; display 8 ascii values if possible
@rowloop2:
	lda     (Pointer),y
        iny
        and     #$7F
        cmp     #'0'
        bcs     :+
        lda     #'.'
:	jsr     KERNAL_CHROUT
        dec     L141F
        bpl     @rowloop2

	LoadB	L141F, 8-1		; reset byte counter in a line again
        lda     #13
        jsr     KERNAL_CHROUT
        cpy     #0
        bne     :+
        inc     Pointer+1
:	dec     FdcNBUF			; end of sector?
        bmi     @end
        jsr     KERNAL_STOP		; RUN/STOP?
        beq     @end			; yes
        jmp     @wholerowloop

@end:	jmp     MainLoop

DoRead:
	jsr     L130C
        lda     L141D
        bne     MainLoopEnd		; abort

        sei
        jsr     InitStackProg
	MoveB	LocalSectorL, SectorL
	MoveB	LocalSectorH, SectorH
L11B2:  jsr     SetupSector

	CmpBI	SectorH, >DD_TOTAL_SECTORS	; end of disk?
        bcc     :+				; no
	CmpBI	SectorL, <DD_TOTAL_SECTORS
        bcc     :+				; no
        jmp     MainLoopEnd		; abort

; now we can read SectorL/SectorH into DataBuffer, 1 sector, 512 bytes
: 	LoadB	Pointer, <DataBuffer
	LoadB	Pointer+1, >DataBuffer
	LoadB	NumOfSectors, 1
        asl     a			; *2=2
        sta     FdcBYTESLEFT+1		; to high byte - $0200 bytes, one sector
	LoadB	FdcBYTESLEFT, 0
        jsr     ReadSectors
	LoadB	VICCTR1, $1B		; screen on
        lda     ErrorCode
        beq     :+
        jsr     ShowError
:	lda     #13
        jsr     KERNAL_CHROUT
        jmp     MainLoop

MainLoopEnd:
	lda     #'?'			; unknown command or wrong parameters
        jsr     KERNAL_CHROUT
        lda     #13
        jsr     KERNAL_CHROUT
        jmp     MainLoop

WrongAddr:
	lda     #$0A			; CTRL+J, linefeed?
        stx     $5000			; ??? this is never read
        sty     $5001			; ???
        jsr     KERNAL_CHROUT
:	lda     #$1D			; CRSR-RIGHT X-times?
        jsr     KERNAL_CHROUT
        dex
        bpl     :-
        jmp     MainLoopEnd

;1214
DoColon:
	LoadB	L141E, 7		; read 8 bytes

        lda     InputBuffer,y
        iny
        cmp     #'0'
        bne     WrongAddr		; address must start with 0
        lda     InputBuffer,y
        iny
        sec
        sbc     #'0'
        cmp     #2
        bcs     WrongAddr		; then no larger than 2
        sta     LocalSectorH

        tya
        tax
        jsr     GetHexByte
        bcs     WrongAddr

	MoveB	LocalSectorL, Pointer
        lda     LocalSectorH
	addv	>DataBuffer
        sta     Pointer+1

        ldy     #0
@rowloop:
	lda     InputBuffer,x
        inx
        cmp     #' '
        beq     :+
@exit:  jmp     MainLoop

:	lda     InputBuffer,x
        cmp     #'.'
        beq     @exit
        jsr     GetHexByte
        bcc     :+
        jmp     WrongAddr

:	lda     LocalSectorL
        sta     (Pointer),y
        iny
        bne     :+
        inc     Pointer+1
:	dec     L141E			; next byte in a row
        bpl     @rowloop

        lda     #13
        jsr     KERNAL_CHROUT		; new line
        jmp     MainLoop

GetHexByte:	; C=0 ok, C=1 wrong characters, byte in LocalSectorL
	jsr     GetHexDigit
        bcc     :+
        rts

:	asl     a
        asl     a
        asl     a
        asl     a
        sta     LocalSectorL
        jsr     GetHexDigit
        bcc     :+
        rts

:	ora     LocalSectorL
        sta     LocalSectorL
        clc
        rts

GetHexDigit:
	lda     InputBuffer,x
        inx
        sec
        sbc     #'0'
        bcc     @err
        cmp     #$0A
        bcc     @ok
        cmp     #$11
        bcc     @err
        cmp     #$17
        bcs     @err
        sec
        sbc     #$07
@ok:	clc
        rts

@err:	sec
        rts

DoWrite:
	jsr     L130C
        lda     L141D
        beq     :+
        jmp     MainLoopEnd

:	sei
	LoadB	VICCTR1, $0b		; screen off
        jsr     InitStackProg
	MoveB	LocalSectorL, SectorL
	MoveB	LocalSectorH, SectorH
        cmp     #>DD_TOTAL_SECTORS	; end of disk?
        bcc     :+			; no
	CmpBI	SectorL, <DD_TOTAL_SECTORS
        bcc     :+			; no
        pla				; why???
        pla
	LoadB	VICCTR1, $1B		; screen on
        jmp     MainLoopEnd		; abort end

:	jsr     SetupSector
	LoadB	NumOfSectors, 1
	LoadW	Pointer, DataBuffer
        jsr     SeekTrack
        jsr     SetWatchdog
        jsr     WriteSector
        jsr     StopWatchdog
	LoadB	VICCTR1, $1B		; screen on
        lda     ErrorCode
        beq     :+
        jsr     ShowError
:	lda     #13			; new line
        jmp     KERNAL_CHROUT

; read bytes from input buffer?
L130C:  ldx     #$00
        stx     L141D
L1311:  lda     InputBuffer,y
        iny
        cmp     #$20
        beq     L1341
        cmp     #$0D
        beq     L1341
        cmp     #$3F
        beq     L1341
        sec
        sbc     #$30
        bcc     L1370
        cmp     #$0A
        bcs     L1334
        sta     L1423,x
        inx
        cpx     #$04
        bcs     L1370
        bcc     L1341

L1334:  sec
        sbc     #$07
        bcc     L1370
        cmp     #$10
        bcs     L1370
        sta     L1423,x
        inx
L1341:  cpy     InputBufLen
        bne     L1311
        cpx     #$00
        beq     :+
        dex
	LoadB	LocalSectorH, 0
        lda     L1423,x
        sta     LocalSectorL
        dex
        bmi     :+

        lda     L1423,x
        asl     a
        asl     a
        asl     a
        asl     a
        ora     LocalSectorL
        sta     LocalSectorL
        dex
        bmi     :+
        lda     L1423,x
        sta     LocalSectorH
:	rts

L1370:  LoadB	L141D, $3F
        rts

; XXX having brief info about commands here would be nice
; XXX does it display current sector number somewhere?

StartupTxt:
        .byte   "DISKMON  IS COPYRIGHT TIB.PLC A"
        .byte   "ND NO    PART OF THIS PROGRAM M"
        .byte   "AY BE RESOLD BY   THE USER WITH"
        .byte   "OUT PERMISION OF TIB.PLC   X   "
        .byte   "     = ABORT TO MAIN MENU"
        .byte   $00

HexDigits:
        .byte   "0123456789ABCDEF"

InputBufLen:  .byte   $00

L141D:  .byte   $00
L141E:  .byte   $00
L141F:  .byte   $00,$00

LocalSectorL:  .byte   $00
LocalSectorH:  .byte   $00

L1423:  .byte   $00,$00,$00,$00

InputBuffer:
; junk bytes follow
	.byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $15,$13,$05
        .byte   " "
        .byte   $12,$05,$14,$15,$12,$0E
        .byte   "     "
        .byte   $14,$0F
        .byte   " "
        .byte   $05,$18,$05,$03,$15,$14,$05
        .byte   " "
        .byte   $01
        .byte   "  ."
        .byte   $05,$18,$05
        .byte   " "
        .byte   $06,$09,$0C,$05
        .byte   "  $="
        .byte   $05,$12,$01,$13,$05,$04,$00
        .byte   "0123456789ABCDEF"

        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00

