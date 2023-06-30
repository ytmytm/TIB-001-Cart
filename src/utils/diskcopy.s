
.include "dd001-jumptable.inc"
.include "dd001-mem.inc"
.include "dd001-sym.inc"
.include "fat12.inc"
.include "geosmac.inc"

CART_COLDSTART  := $8000                        ; cartridge cold start vector

DataBuffer	= $1400	; somewhere above program code, page alinged
DataBufferLen	= $6C00 ; $1400-$8000 (could be even more $0900-$8000!)

; having a display of number of swaps remaining would be nice
; also visual indication of source (GREEN) and target (RED) as border color

	.segment "BASICHEADER"

	.word $0801			; load address
	.byte $0c,$08,$d0,$07,$9e,$20,$32,$30,$36,$34,$00,$00,$00,$00,$00	; Basic "SYS 2064"


	.segment "CODE"

        ldx     #$FF
        txs
        lda     ResetFDC

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

;XXX copied from ROM

;**  Turn off the screen and Wait for rasterline $1FF
WaitRasterLine:				;				[8851]
	LoadB	VICCTR1, $0b		; screen off
:	CmpBI	VICLINE, $FF
	bne :-
	rts

;**  Wait until the data register is ready
Wait4DataReady:
:	bbrf	7, StatusRegister, :-
	rts

;XXX end of ROM copy

TblBitClear:
        .byte   $FE,$FD,$FB,$F7,$EF,$DF,$BF,$7F
TblBitSet:
        .byte   $01,$02,$04,$08,$10,$20,$40,$80
StartupTxt:     ;0123456789012345678901234567890123456789
	.byte	$93 ; clear screen
        .byte   "DISKCOPY IS COPYRIGHT TIB.PLC AND NO", 13
	.byte   "PART OF THIS PROGRAM MAY BE RESOLD BY", 13
	.byte	"THE USER WITHOUT PERMISION OF TIB.PLC", 13
        .byte   "RUN/STOP = ABORT TO MAIN MENU",13,0

SourceDiskTxt:
        .asciiz	"PLACE SOURCE DISK IN DRIVE PRESS RETURN"

TargetDiskTxt:
        .asciiz	"PLACE DESTINATION DISK IN DRIVE PRESS RETURN"

CompletedTxt:
        .asciiz	"COPY COMPLETE PRESS RETURN"

LocalSectorL:
	.byte	$00
LocalSectorH:
	.byte	$00
CountDiskSwaps:
	.byte	$00
; Y reg storage during keyboard scan
tempY:
	.byte	$00
LocalNumOfSectors:
	.byte	$00

