
.include "dd001-romv1.1-direct-jumptable.inc"
.include "dd001-mem.inc"
.include "dd001-sym.inc"
.include "fat12.inc"
.include "geosmac.inc"

COLOR           := $0286                        ; foreground text color
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

ResetFDC00	= $DF00				; can be changed to ResetFDC ($DF80, any address on page)

DataBuffer	= $1400	; somewhere above program code, page alinged
DataBufferLen	= $6C00 ; $1400-$8000 (could be even more $0900-$8000!)

; having a display of number of swaps remaining would be nice
; also visual indication of source (GREEN) and target (RED) as border color

	.segment "CODE"

        ldx     #$FF
        txs
        lda     ResetFDC00

	LoadB	COLOR, 1		; white text
        LoadB	VICBOCL, 6		; blue border
	LoadB	MSGFLG, $80		; Kernal messages on(?) (direct mode)
	LoadB	CPU_PORT, $37		; ROM+I/O
	LoadB	VICCTR1, $1B		; screen on

        lda     #$93			; clear screen
        jsr     KERNAL_CHROUT

	LoadB	CountDiskSwaps, 13		; disk swaps
	LoadB	LocalSectorL, 0		; LoadW LocalSectorL, 0
        sta     LocalSectorH
        cli

        ldy     #0
:	lda     StartupTxt,y
        beq     :+
        jsr     KERNAL_CHROUT
        iny
        jmp     :-			; XXX BNE instead of infinite loop

:	lda     #13			; new line
        jsr     KERNAL_CHROUT
        jsr     InitStackProg

	LoadB	LocalNumOfSectors, >DataBufferLen+1

CopyLoop:
        cli
        lda     CountDiskSwaps			; last run?
        bne     :+
	LoadB	LocalNumOfSectors, $24	; $24 sectors in last run

:	LoadB	VICCTR1, $1B		; screen on
        jsr     InsertSourceDisk
	LoadB	FdcBYTESLEFT, $FF	; LoadW FdcBYTESLEFT, $FFFF
        sta     FdcBYTESLEFT+1
	LoadB	ErrorCode, ERR_OK
        jsr     ReadChunk
        cli
	LoadB	VICCTR1, $1B		; screen on
        jsr     InsertTargetDisk
	LoadB	ErrorCode, ERR_OK
        jsr     WriteChunk

        lda     LocalSectorL
        addv	>DataBufferLen		; this many sectors in one chunk?
        sta     LocalSectorL
        lda     LocalSectorH
        adc     #$00
        sta     LocalSectorH

        dec     CountDiskSwaps
        bpl     CopyLoop

        jsr     CopyCompleted

	LoadB	CountDiskSwaps, 13
	LoadB	LocalNumOfSectors, >DataBufferLen+1
	LoadB	LocalSectorL, 0		; LoadW L0AFA, 0
        sta     LocalSectorH
        jmp     CopyLoop

WriteChunk:
	MoveB	LocalNumOfSectors, NumOfSectors
	MoveB	LocalSectorL, SectorL
	MoveB	LocalSectorH, SectorH

        jsr     SetupSector

	LoadB	ErrorCode, ERR_OK	; zero
        sta     Pointer
	LoadB	Pointer+1, >DataBuffer
        jsr     SeekTrack
        jsr     SetWatchdog
        jsr     WriteSector
        jsr     StopWatchdog
        lda     ErrorCode
        beq     :+
        jsr     Specify			; try again
        jsr     Recalibrate
        jmp     WriteChunk		; there is no break process, this may be infinite loop on error
:	rts

ReadChunk:
	MoveB	LocalSectorL, SectorL
	MoveB	LocalSectorH, SectorH
	MoveB	LocalNumOfSectors, NumOfSectors

        jsr     SetupSector

	LoadB	ErrorCode, ERR_OK	; zero
        sta     Pointer
	LoadB	Pointer+1, >DataBuffer
        jsr     SeekTrack
        jsr     ReadSectors
        jsr     StopWatchdog
        lda     ErrorCode
        beq     :+
        jsr     Specify
        jsr     Recalibrate
        jmp     ReadChunk
:	rts

; XXX unused code
        lda     #$4A
        sta     DataRegister
        jsr     Wait4DataReady
        lda     #$00
        sta     DataRegister
        jsr     Wait4DataReady
        jsr     ReadStatus
        rts

InsertSourceDisk:
        ldy     #0
:	lda     SourceDiskTxt,y
        beq     :+
        jsr     KERNAL_CHROUT
        iny
        jmp     :-

:	lda     #$01			; any key not from first column?
        jsr     KeyboardScan
        bcs     PrintNewLine
        lda     #$7F			; RUN/STOP?
        jsr     KeyboardScan
        bcc     :-
        jmp     (CART_COLDSTART)

PrintNewLine:
        lda     #13			; new line
        jsr     KERNAL_CHROUT
        jsr     WaitRasterLine		; why?
        sei
        rts

InsertTargetDisk:
        ldy     #0
:	lda     TargetDiskTxt,y
        beq     :+
        jsr     KERNAL_CHROUT
        iny
        jmp     :-

:	lda     #$01			; any key not from first column?
        jsr     KeyboardScan
        bcs     PrintNewLine2
        lda     #$7F			; RUN/STOP?
        jsr     KeyboardScan
        bcc     :-
        sei
        jmp     (CART_COLDSTART)

; they could have used PrintNewLine
PrintNewLine2:
        lda     #13			; new line
        jsr     KERNAL_CHROUT
        jsr     WaitRasterLine		; why?
        sei
        rts

CopyCompleted:
	LoadB	VICCTR1, $1B		; screen on
        ldy     #$00
:	lda     CompletedTxt,y
        beq     :+
        jsr     KERNAL_CHROUT
        iny
        jmp     :-

:	lda     #$01			; any key not from first column?
        jsr     KeyboardScan
        bcs     PrintNewLine3
        lda     #$7F			; RUN/STOP?
        jsr     KeyboardScan
        bcc     :-
        sei
        ldx     #$FF			; this appears only here, COLDSTART must do it anyway
        txs
        jmp     (CART_COLDSTART)

; they could have used PrintNewLine
PrintNewLine3:
        lda     #13			; new line
        jsr     KERNAL_CHROUT
        jsr     WaitRasterLine		; why?
        sei
        rts

KeyboardScan:
        sty     tempY
        pha
        lsr     a
        lsr     a
        lsr     a
        tay
        lda     TblBitClear,y
        sta     $DC00
        pla
        and     #$07
        tay
        lda     TblBitSet,y
        and     CIA1DRB
        bne     L09DF
        lda     #$FF
        sta     $DC00
        lda     CIA1DRB
        and     TblBitSet,y
        beq     L09DF
        sec
        ldy     tempY
        rts

L09DF:  clc
        ldy     tempY
        rts

TblBitClear:
        .byte   $FE,$FD,$FB,$F7,$EF,$DF,$BF,$7F
TblBitSet:
        .byte   $01,$02,$04,$08,$10,$20,$40,$80
StartupTxt:
        .byte   "DISKCOPY IS COPYRIGHT TIB.PLC A"
        .byte   "ND NO    PART OF THIS PROGRAM M"
        .byte   "AY BE RESOLD BY   THE USER WITH"
        .byte   "OUT PERMISION OF TIB.PLC   RUN/"
        .byte   "STOP = ABORT TO MAIN MENU"
        .byte   $00

SourceDiskTxt:
        .byte   "PLACE SOURCE DISK IN DRIVE PRES"
        .byte   "S RETURN"
        .byte   $00

TargetDiskTxt:
        .byte   "PLACE DESTINATION DISK IN DRIVE"
        .byte   " PRESS RETURN"
        .byte   $00

CompletedTxt:
        .byte   "COPY COMPLETE PRESS RETURN"
        .byte   $00

LocalSectorL:  .byte   $00
LocalSectorH:  .byte   $00
CountDiskSwaps:  .byte   $00
; Y reg storage during keyboard scan
tempY:  .byte   $00
LocalNumOfSectors:  .byte   $00

; unused junk bytes
        .byte   "0123456789ABCDEF"
        .byte   $00,$00

