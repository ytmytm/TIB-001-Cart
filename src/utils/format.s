
.include "dd001-romv1.1-direct-jumptable.inc"
.include "dd001-mem.inc"
.include "dd001-sym.inc"
.include "fat12.inc"
.include "geosmac.inc"

NDX             := $00C6                        ; Number of characters in keyboard queue
COLOR           := $0286                        ; foreground text color
CART_COLDSTART  := $8000                        ; cartridge cold start vector
VICBOCL         := $D020                        ; border color
KERNAL_SETLFS   := $FFBA                        ; Set logical file
KERNAL_SETNAM   := $FFBD                        ; Set file name
KERNAL_OPEN     := $FFC0                        ; Open file
KERNAL_CLOSE    := $FFC3                        ; Close file
KERNAL_CHKIN    := $FFC6                        ; Open channel for input
KERNAL_CLRCHN   := $FFCC                        ; Clear I/O channels
KERNAL_CHRIN    := $FFCF                        ; Get a character from the input channel
;KERNAL_CHROUT   := $FFD2                        ; Output a character
KERNAL_LOAD     := $FFD5                        ; Load file
;KERNAL_STOP     := $FFE1                        ; Check if key pressed (RUN/STOP)
KERNAL_GETIN    := $FFE4                        ; Get a character

	.segment "CODE"

	LoadB	StartofDir, $C0		; buffer?
        LoadB	EndofDir, $C2		; buffer?
	LoadB	COLOR, 1		; white text
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
        jmp     :-
:

DoFormatLoop:
	LoadB	NDX, 0			; clear keyboard queue
        lda     #13			; new line
        jsr     KERNAL_CHROUT
        ldy     #0
:	lda     PromptTxt,y
        beq     :+
        jsr     KERNAL_CHROUT
        iny
        bne     :-

        lda     #$0D			; XXX this is never reached
        jsr     KERNAL_CHROUT

:	lda     #$FF
:	cmp     VICLINE			; wait for raster (why?)
        bne     :-

        ldy     #0
@input:	jsr     KERNAL_CHRIN
        cmp     #13			; RETURN?
        beq     :+
        sta     FileNameBuf,y
        iny
:	sty     FNLEN
        cmp     #13			; repeat until RETURN
        bne     @input
        lda     #'"'			; ?quote marks end of the volume name? XXX
        sta     FileNameBuf,y

        jsr     KERNAL_GETIN		; why?
        lda     #13			; newline
        jsr     KERNAL_CHROUT
        sei
	LoadB	VICCTR1, $0B		; screen off
        lda     FileNameBuf
        cmp     #'*'			; '*' means quit program
        bne     :+
        jmp     (CART_COLDSTART)	; RESET

:	LoadB	FNADR, <FileNameBuf	; call API function
	LoadB	FNADR+1,>FileNameBuf
        jsr     FormatDisk
        jmp     DoFormatLoop


PromptTxt:	.asciiz	"PLEASE ENTER DISK NAME >"

StartupTxt:
		.byte	"DISK FORMAT IS COPYRIGHT TIB.PLC AND NO    PART OF THIS PROGRAM"
		.byte	" MAY BE RESOLD BY   THE USER WITHOUT PERMISION OF TIB.PLC   *"
		.byte	"       = ABORT TO MAIN MENU"
		.byte   $00

; junk bytes follow
        .byte   "0123456789ABCDEF"

FileNameBuf     := $0961                        ; Buffer to store file name
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00


