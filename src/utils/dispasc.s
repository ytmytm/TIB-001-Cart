
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


FileNameBuf = $1306

        ldy     #0
@input:	jsr     KERNAL_CHRIN
        sta     FileNameBuf,y
        cmp     #13			; RETURN?
        beq     :+
        iny
	sty     FNLEN
        cmp     #13			; repeat until RETURN
        bne     @input
        jsr     KERNAL_GETIN		; why?
:       lda     #13			; newline
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

DataBuffer = $4000
DataBufferLength = $0400		; 2 sectors = 4 pages

; read and display data cluster by cluster
:	LoadW	Pointer, DataBuffer
        sei
	LoadB	VICCTR1, $0B		; screen off
        jsr     SetupSector
        jsr     SeekTrack
	LoadB	NumOfSectors, 2		; 2 sectors = whole cluster (use define here?)?
	LoadB	FdcBYTESLEFT+1, 4	; 2 sectors = 4 pages
        jsr     ReadSectors
        jsr     L1113
        jsr     GetNextCluster
	CmpBI	FdcCLUSTER+1, $0F	; magic value for end of file?
        beq     :+
        jsr     CalcFirst
        jmp     :-
:	jmp     DoMainLoop

L1113:  LoadB	VICCTR1, $1B		; screen on
	ldy	#<DataBuffer		; it's 0, resets Y counter too
        sty     Pointer
	LoadB	Pointer+1, >DataBuffer	; why reload? ReadSectors changes that?
        ldx     #$1F
        stx     L12FE
        stx     L12FF
L1128:  lda     (Pointer),y
        iny
        bne     L1136
        inc     Pointer+1
        ldx     Pointer+1
        cpx     #>(DataBuffer+DataBufferLength)
        bne     L1136
        rts

L1136:  cmp     #$1A
        beq     L1145
        jsr     KERNAL_CHROUT
        jsr     KERNAL_STOP
        beq     L1145
        jmp     L1128

L1145:  pla
        pla
        jmp     DoMainLoop

DoDirectory:
	jsr     InitStackProg
	LoadB	Z_FF, DD_SECT_ROOT	; start of root dir
        jsr     ReadDirectory
	LoadB	CIA2IRQ, $7F
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

        ldy     #FE_OFFS_NAME		; this part displays volume name
L1182:  sei
        jsr     RdDataRamDxxx
        sta     $FD
        tya
        pha
        lda     $FD
        cmp     #$60			; ascii small letters?
        bcc     L1193
	subv	$20			; convert to petscii
L1193:  jsr     KERNAL_CHROUT
        lda     $FD			; XXX not needed
        pla
        tay
        iny
        cpy     #FE_OFFS_NAME_END
        bne     L1182
        lda     #13			; new line
        jsr     KERNAL_CHROUT
        jmp     L1207

; this part displays files
L11A7:	LoadB	Pointer, 0		; it's the same code as above
	MoveB	StartofDir, Pointer+1

L11B0:  ldy     #FE_OFFS_NAME
        sei
        jsr     RdDataRamDxxx
        cmp     #FE_EMPTY
        beq     L1235
        cmp     #FE_DELETED
        beq     L1207
        ldx     #FE_OFFS_EXT-1		; only the filename part
L11C0:  sei
        jsr     RdDataRamDxxx
        iny
        cmp     #' '			; skip over spaces
        beq     L11DA
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
L11DA:  dex
        bpl     L11C0			; until 8 characters?

        lda     #'.'			; extension dot
        jsr     KERNAL_CHROUT
        ldx     #3-1			; 3 characters
L11E4:  sei
        jsr     RdDataRamDxxx
        iny
        cmp     #' '			; skip over spaces
        beq     L11FC
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
L11FC:  dex
        bpl     L11E4			; until 8 characters?

        jsr     ShowSize		; print out file size in bytes

        lda     #13			; new line
        jsr     KERNAL_CHROUT

L1207:  lda     Pointer			; XXX AddVB+LDA Pointer+1
	addv	FILE_ENTRY_SIZE		; next file entry
        sta     Pointer
        lda     Pointer+1
        adc     #$00
        sta     Pointer+1
        cmp     EndofDir		; last page of Directory (2 pages=1 sector)
        bne     L11B0			; no, keep displaying files

	AddVB	1, Z_FF			; count directory sectors
        cmp     #DD_SECT_ROOT+DD_NUM_ROOTDIR_SECTORS	; all of them?
        bcs     L1235			; yes, end
        sei
        jsr     ReadDirectory		; read next directory sector

	LoadB	VICCTR1, $1B		; screen on
	LoadB	CIA2IRQ, $7F
        jmp     L11A7

L1235:  jsr     ShowBytesFree		; JMP
        rts

StartupTxt:
        .byte   "DISPASC  IS COPYRIGHT TIB.PLC A"
        .byte   "ND NO    PART OF THIS PROGRAM M"
        .byte   "AY BE RESOLD BY   THE USER WITH"
        .byte   "OUT PERMISION OF TIB.PLC   *X  "
        .byte   "     = ABORT TO MAIN MENU"
        .byte   $00

PromptTxt:
        .byte   "PLEASE ENTER PROGRAM NAME >"
        .byte   $00

; junk bytes follow
        .byte   "0123456789ABCDEF"

        .byte   $00,$00,$00
L12FE:  .byte   $00
L12FF:  .byte   $00,$00
