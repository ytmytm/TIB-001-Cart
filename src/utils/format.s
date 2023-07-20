
.include "dd001-jumptable.inc"
.include "dd001-mem.inc"
.include "dd001-sym.inc"
.include "fat12.inc"
.include "geosmac.inc"

NDX             := $00C6                        ; Number of characters in keyboard queue
CART_COLDSTART  := $8000                        ; cartridge cold start vector
KERNAL_CHRIN    := $FFCF                        ; Get a character from the input channel

	.segment "BASICHEADER"

	.word $0801			; load address
	.byte $0c,$08,$d0,$07,$9e,$20,$32,$30,$36,$34,$00,$00,$00,$00,$00	; Basic "SYS 2064"


	.segment "CODE"

	lda	#$C0			; buffer in $C000-$C1FF, but why?
	jsr	SetSpace		; set StartofDir/EndofDir
	LoadB	COLOR, 1		; white text
	LoadB	VICBOCL, 6		; blue border
	LoadB	MSGFLG, $80		; Kernal messages on(?) (direct mode)
	LoadB	CPU_PORT, $37		; ROM+I/O
	LoadB	VICCTR1, $1B		; screen on

        cli
	lda	#<StartupTxt
	ldy	#>StartupTxt
	jsr	PrintString		; print startup message

DoFormatLoop:
	LoadB	NDX, 0			; clear keyboard queue

	lda	#<PromptTxt
	ldy	#>PromptTxt
	jsr	PrintString

	lda     #$FF
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

:	LoadW	FNADR, FileNameBuf
        jsr     FormatDisk		; call API function
        jmp     DoFormatLoop


PromptTxt:	.byte	13,"PLEASE ENTER DISK NAME >",0

StartupTxt:     ;0123456789012345678901234567890123456789
	.byte	$93 ; clear screen
        .byte   "DISK FORMAT IS COPYRIGHT TIB.PLC AND NO", 13
	.byte   "PART OF THIS PROGRAM MAY BE RESOLD BY", 13
	.byte	"THE USER WITHOUT PERMISION OF TIB.PLC", 13
        .byte	"* = ABORT TO MAIN MENU",13,0

FileNameBuf:

