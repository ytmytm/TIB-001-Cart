
.include "dd001-jumptable.inc"
.include "dd001-mem.inc"
.include "dd001-sym.inc"
.include "fat12.inc"
.include "geosmac.inc"

CART_COLDSTART  := $8000                        ; cartridge cold start vector
KERNAL_OPEN     := $FFC0                        ; Open file
KERNAL_CLOSE    := $FFC3                        ; Close file
KERNAL_CHKIN    := $FFC6                        ; Open channel for input
KERNAL_CLRCHN   := $FFCC                        ; Clear I/O channels
KERNAL_CHRIN    := $FFCF                        ; Get a character from the input channel
KERNAL_LOAD     := $FFD5                        ; Load file
KERNAL_GETIN    := $FFE4                        ; Get a character

; somewhere above the program code, don't have to be page alligned
DataBuffer = $4000
DataBufferLength = $0400		; 2 sectors = 4 pages

	.segment "BASICHEADER"

	.word $0801			; load address
	.byte $0c,$08,$d0,$07,$9e,$20,$32,$30,$36,$34,$00,$00,$00,$00,$00	; Basic "SYS 2064"


	.segment "CODE"

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
        jmp     :-			; XXX BNE to avoid infinite loop
:

DoMainLoop:
        lda     #13			; new line
        jsr     KERNAL_CHROUT
        ldy     #0
:	lda     PromptTxt,y
        beq     :+
        jsr     KERNAL_CHROUT
        iny
        bne     :-

        lda     #13			; new line
        jsr     KERNAL_CHROUT

:	lda     #$FF
:	cmp     VICLINE			; wait for raster (why?)
        bne     :-

        ldy     #0
@input:	jsr     KERNAL_CHRIN
        sta     FileNameBuf,y
        cmp     #13
        beq     :+
        iny
        bne     @input
:	sty     FNLEN
        cpy     #0			; XXX WHAT IS THAT?!
        beq     DoMainLoop
        lda     #$FF			; XXX HOW COMPLICATED IS IT TO INPUT A STRING?
        sta     FileNameBuf,y
        jsr     KERNAL_GETIN		; why?
        lda     #13			; newline
        jsr     KERNAL_CHROUT
        sei

        lda     FileNameBuf
        cmp     #'$'
        bne     :+
        jsr     DoDirectory		; show directory
        jmp     DoMainLoop

:	cmp     #'*'			; end of program?
        bne     :+
        lda     FileNameBuf+1
        cmp     #'X'
        bne     :+
        jmp     (CART_COLDSTART)	; RESET

:	LoadB	VICCTR1, $0B		; screen off
	LoadB	FNADR, <FileNameBuf
	LoadB	FNADR+1, >FileNameBuf
        jsr     InitStackProg
        jsr     FindFile
        bcs     @found			; error?

	; file not found
	LoadB	VICCTR1, $1B		; screen on
        lda     #13			; new line
        jsr     KERNAL_CHROUT
        lda     ErrorCode
        jsr     ShowError
        jmp     DoMainLoop

@found:	LoadB	FdcLENGTH, 0
        ldy     #FE_OFFS_START_CLUSTER	; start cluster within file entry
        jsr     RdDataRamDxxx
        iny
        sta     FdcCLUSTER
        jsr     RdDataRamDxxx
        iny
        sta     FdcCLUSTER+1
        jsr     RdDataRamDxxx
        iny				; file size LO
        sta     FdcLENGTH+3		; why reverse byte order?
        jsr     RdDataRamDxxx
        iny				; file size HI
        sta     FdcLENGTH+2
        jsr     GetFATs
        jsr     CalcFirst
	MoveB	FdcLENGTH+3, FdcBYTESLEFT	; reverse byte order again
	MoveB	FdcLENGTH+2, FdcBYTESLEFT+1

; read and display data cluster by cluster
ReadFileClusters:
	LoadW	Pointer, DataBuffer
        sei
	LoadB	VICCTR1, $0B		; screen off
        jsr     SetupSector
        jsr     SeekTrack
	LoadB	NumOfSectors, 2		; 2 sectors = whole cluster (use define here?)?
	LoadB	FdcBYTESLEFT+1, 4	; 2 sectors = 4 pages
        jsr     ReadSectors
        jsr     DoDisplayHexData
	AddVB	4, FdcLENGTH		; this part is missing in dispasc.s
        jsr     GetNextCluster
	CmpBI	FdcCLUSTER+1, $0F	; magic value for end of file?
        beq     :+
        jsr     CalcFirst
        jmp     ReadFileClusters
:	jmp     DoMainLoop

	; print data from a single cluster, return on RUN/STOP or CTRL+Z character
DoDisplayHexData:
	LoadB	VICCTR1, $1B		; screen on
	ldy	#<DataBuffer		; it's 0, resets Y counter too
	sty	Pointer
	LoadB	Pointer+1, >DataBuffer	; why reload? ReadSectors changes that?

        ldx     #$0F			; 16 bytes in a row
        stx     L136A
        lda     #$3F			; 64 rows, for 16*64 = 1024 = 1 cluster = 2 sectors
        sta     L136B

@loop:	lda     FdcLENGTH		; start of row: print file offset address
	subv	>DataBuffer
        clc
        adc     Pointer+1
        pha				; hex digit 1, this is repeated code
        and     #$F0
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        tax
        lda     HexDigits,x
        jsr     KERNAL_CHROUT
        pla				; hex digit 2
        and     #$0F
        tax
        lda     HexDigits,x
        jsr     KERNAL_CHROUT
        tya				; hex digit 3
        and     #$F0
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        tax
        lda     HexDigits,x
        jsr     KERNAL_CHROUT
        tya				; hex digit 4
        and     #$0F
        tax
        lda     HexDigits,x
        jsr     KERNAL_CHROUT

        lda     #' '			; separator
        jsr     KERNAL_CHROUT

@rowloop:
	lda     (Pointer),y
        iny
        bne     :+
        inc     Pointer+1		; next page
:	pha				; hex digit 1
        and     #$F0
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        tax
        lda     HexDigits,x
        jsr     KERNAL_CHROUT
        pla				; hex digit 2
        and     #$0F
        tax
        lda     HexDigits,x
        jsr     KERNAL_CHROUT

        dec     L136A			; next byte
        bpl     @rowloop

        jsr     KERNAL_STOP		; check for RUN/STOP
        beq     @end			; yes -> finish

        lda     #$0F			; 16 bytes in a row
        sta     L136A
        lda     #13			; new line
        jsr     KERNAL_CHROUT
        dec     L136B			; next line, 64*16 = $0400 = 1 cluster
        bpl     @loop
        rts

@end:	pla				; XXX BUG, why 2 bytes on stack?
        pla
        jmp     DoMainLoop

	; XXX DisplayDir from ROM does exactly that
DoDirectory:
	jsr     InitStackProg
	LoadB	Z_FF, DD_SECT_ROOT	; start of root dir
        jsr     ReadDirectory
	LoadB	CIA2IRQ, $7F		; StopWatchdog?
        jsr     GetFATs
	LoadB	CIA2IRQ, $7F
	LoadB	VICCTR1, $1B		; screen on
        lda     ErrorCode
        beq     @noerr
        clc
        rts

@noerr:
	LoadB	Pointer, 0		; setup Pointer to StartofDir page (under I/O)
	MoveB	StartofDir, Pointer+1
        ldy     #FE_OFFS_ATTR
        sei
        jsr     RdDataRamDxxx
        cmp     #FE_ATTR_VOLUME_ID
        bne     L11A7

; this part displays volume name, 8 characters without extension
        ldy     #FE_OFFS_NAME
:	sei
        jsr     RdDataRamDxxx
        sta     $FD
        tya
        pha
        lda     $FD
        cmp     #$60			; ascii small letters?
        bcc     :+
	subv	$20			; convert to petscii
:	jsr     KERNAL_CHROUT
        lda     $FD			; XXX not needed
        pla
        tay
        iny
        cpy     #FE_OFFS_NAME_END
        bne     :--
        lda     #13			; new line
        jsr     KERNAL_CHROUT
        jmp     L1207

; this part displays file entries
L11A7:	LoadB	Pointer, 0		; it's the same code as above, only without ASCII conversion
	MoveB	StartofDir, Pointer+1

L11B0:  ldy     #FE_OFFS_NAME
        sei
        jsr     RdDataRamDxxx
        cmp     #FE_EMPTY
        beq     L1235			; end of directory
        cmp     #FE_DELETED
        beq     L1207			; skip over this entry

	; print file name
        ldx     #FE_OFFS_EXT-1		; only the filename part
:	sei
        jsr     RdDataRamDxxx
        iny
        cmp     #' '			; skip over spaces
        beq     :+
        sta     $FD			; this storing/restoring is not needed for KERNAL_CHROUT
        txa
        pha
        tya
        pha
        lda     $FD
        jsr     KERNAL_CHROUT
        lda     $FD			; XXX not needed
        pla
        tay
        pla
        tax
:	dex
        bpl     :--			; until 8 characters?
	; print dot
        lda     #'.'			; extension dot
        jsr     KERNAL_CHROUT
	; print extension
        ldx     #3-1			; 3 characters
:	sei
        jsr     RdDataRamDxxx
        iny
        cmp     #' '			; skip over spaces
        beq     :+
        sta     $FD			; this storing/restoring is not needed for KERNAL_CHROUT
        txa
        pha
        tya
        pha
        lda     $FD
        jsr     KERNAL_CHROUT
        pla
        tay
        pla
        tax
:	dex
        bpl	:--			; until 3 characters?

        jsr     ShowSize		; print out file size in bytes

        lda     #13			; new line
        jsr     KERNAL_CHROUT

L1207:  lda     Pointer			; XXX AddVB+LDA Pointer+1
	addv	FILE_ENTRY_SIZE		; next file entry
        sta     Pointer
        lda     Pointer+1
        adc     #$00
        sta     Pointer+1
        cmp     EndofDir		; last page of Directory (2 pages=1 sector)?
        bne     L11B0			; no, keep displaying files

	AddVB	1, Z_FF			; count directory sectors
        cmp     #DD_SECT_ROOT+DD_NUM_ROOTDIR_SECTORS	; all of them?
        bcs     L1235			; yes, end
        sei
        jsr     ReadDirectory		; read next directory sector

	LoadB	VICCTR1, $1B		; screen on
	LoadB	CIA2IRQ, $7F		; StopWatchdog
	jmp     L11A7

L1235:	jsr     ShowBytesFree		; JMP
        rts

StartupTxt:
        .byte   "DISPHEX  IS COPYRIGHT TIB.PLC A"
        .byte   "ND NO    PART OF THIS PROGRAM M"
        .byte   "AY BE RESOLD BY   THE USER WITH"
        .byte   "OUT PERMISION OF TIB.PLC   *X  "
        .byte   "     = ABORT TO MAIN MENU"
        .byte   $00

PromptTxt:
        .byte   "PLEASE ENTER PROGRAM NAME >"
        .byte   $00

HexDigits:
        .byte   "0123456789ABCDEF"

;junk bytes follow
        .byte   $00,$00,$00
L136A:  .byte   $00
L136B:  .byte   $00,$00,$00,$00,$00,$00

; it's somewhere here
FileNameBuf = $1372
