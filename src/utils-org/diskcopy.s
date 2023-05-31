; da65 V2.19 - Git dcdf7ade0
; Created:    2023-05-31 13:18:48
; Input file: ../../firmware/utils/DISKCOPY.EXE
; Page:       1


        .setcpu "6502"

P6510           := $0001                        ; DR onboard I/O port of 6510
MSGFLG          := $009D                        ; Kernal message control (bit 7=show control, bit 6=show error); $80=direct mode, $00=program mode
FNLEN           := $00B7                        ; Length of current filename, set by SETNAM
FNADR           := $00BB                        ; Pointer to current filename, set by SETNAM
NDX             := $00C6                        ; Number of characters in keyboard queue
NumOfSectors    := $00F7
SectorL         := $00F8
SectorH         := $00F9
DirPointer      := $00FB
COLOR           := $0286                        ; foreground text color
StartofDir      := $0334                        ; page number where directory buffer starts (need 2 pages for a sector)
EndofDir        := $0335                        ; page number where directory buffer ends(?)
TapeBuffer      := $033C
CART_COLDSTART  := $8000                        ; cartridge cold start vector
WaitRasterLine  := $8851                        ; direct call to WaitRasterLine, not exposed in jump table
ReadSectors     := $885E                        ; direct call to ReadSectors instead of jump table _ReadSectors $801B
SetupSector     := $8899                        ; direct call to SetupSector instead of jump table _SetupSector $8030
Recalibrate     := $88F7                        ; direct call to Recalibrate instead of jump table _Recalibrate $8036
Specify         := $891A                        ; direct call to Specify instead of jump table _Specify $8033
ReadStatus      := $8962                        ; direct call to ReadStatus instead of jump table _ReadStatus $8021
SeekTrack       := $898A                        ; direct call to SeekTrack instead of jump table _SeekTrack $8057
Wait4DataReady  := $89C8                        ; direct call to Wait4DataReady, not exposed in jump table
FormatDisk      := $89DB                        ; direct call to FormatDisk instead of jump table _FormatDisk $800F
WriteSector     := $8BEE                        ; direct call to WriteSector instead of jump table _WriteSector $801E
InitStackProg   := $8D5A                        ; direct call to InitStackProg instead of jump table _InitStackProg $802D
SetWatchdog     := $8D90                        ; direct call to SetWatchdog instead of jump table _SetWatchdog $8018
StopWatchdog    := $8DBD                        ; direct call to StopWatchdog instead of jump table _StopWatchdog $807E
VICCTR1         := $D011                        ; control register 1
VICLINE         := $D012                        ; raster line
VICBOCL         := $D020                        ; border color
VICBAC0         := $D021                        ; backgrouund color 0
StatusRegister  := $DE80                        ; floppy controller status register
DataRegister    := $DE81                        ; floppy controller data register
ResetFDC00      := $DF00                        ; write here to reset floppy controller (any write to $DFxx)
ResetFDC        := $DF80                        ; write here to reset floppy controller (any write to $DFxx)
KERNAL_SETNAM   := $FFBD                        ; Set file name
KERNAL_CHRIN    := $FFCF                        ; Get a character from the input channel
KERNAL_CHROUT   := $FFD2                        ; Output a character
KERNAL_GETIN    := $FFE4                        ; Get a character
        ldx     #$FF
        txs
        lda     ResetFDC00
        lda     #$01
        sta     COLOR
        lda     #$06
        sta     VICBOCL
        lda     #$80
        sta     MSGFLG
        lda     #$37
        sta     P6510
        lda     #$1B
        sta     VICCTR1
        lda     #$93
        jsr     KERNAL_CHROUT
        lda     #$0D
        sta     L0AFC
        lda     #$00
        sta     L0AFA
        sta     L0AFB
        cli
        ldy     #$00
L0832:  lda     StartupTxt,y
        beq     L083E
        jsr     KERNAL_CHROUT
        iny
        jmp     L0832

L083E:  lda     #$0D
        jsr     KERNAL_CHROUT
        jsr     InitStackProg
        lda     #$6D
        sta     L0AFE
CopyLoop:
        cli
        lda     L0AFC
        bne     L0856
        lda     #$24
        sta     L0AFE
L0856:  lda     #$1B
        sta     VICCTR1
        jsr     InsertSourceDisk
        lda     #$FF
        sta     TapeBuffer+38
        sta     TapeBuffer+39
        lda     #$00
        sta     TapeBuffer+21
        jsr     ReadChunk
        cli
        lda     #$1B
        sta     VICCTR1
        jsr     InsertTargetDisk
        lda     #$00
        sta     TapeBuffer+21
        jsr     WriteChunk
        lda     L0AFA
        clc
        adc     #$6C
        sta     L0AFA
        lda     L0AFB
        adc     #$00
        sta     L0AFB
        dec     L0AFC
        bpl     CopyLoop
        jsr     CopyCompleted
        lda     #$0D
        sta     L0AFC
        lda     #$6D
        sta     L0AFE
        lda     #$00
        sta     L0AFA
        sta     L0AFB
        jmp     CopyLoop

WriteChunk:
        lda     L0AFE
        sta     NumOfSectors
        lda     L0AFA
        sta     SectorL
        lda     L0AFB
        sta     SectorH
        jsr     SetupSector
        lda     #$00
        sta     TapeBuffer+21
        sta     DirPointer
        lda     #$14
        sta     DirPointer+1
        jsr     SeekTrack
        jsr     SetWatchdog
        jsr     WriteSector
        jsr     StopWatchdog
        lda     TapeBuffer+21
        beq     L08E4
        jsr     Specify
        jsr     Recalibrate
        jmp     WriteChunk

L08E4:  rts

ReadChunk:
        lda     L0AFA
        sta     SectorL
        lda     L0AFB
        sta     SectorH
        lda     L0AFE
        sta     NumOfSectors
        jsr     SetupSector
        lda     #$00
        sta     TapeBuffer+21
        sta     DirPointer
        lda     #$14
        sta     DirPointer+1
        jsr     SeekTrack
        jsr     ReadSectors
        jsr     StopWatchdog
        lda     TapeBuffer+21
        beq     L0919
        jsr     Specify
        jsr     Recalibrate
        jmp     ReadChunk

L0919:  rts

        lda     #$4A
        sta     DataRegister
        jsr     Wait4DataReady
        lda     #$00
        sta     DataRegister
        jsr     Wait4DataReady
        jsr     ReadStatus
        rts

InsertSourceDisk:
        ldy     #$00
L0930:  lda     SourceDiskTxt,y
        beq     L093C
        jsr     KERNAL_CHROUT
        iny
        jmp     L0930

L093C:  lda     #$01
        jsr     KeyboardScan
        bcs     PrintNewLine
        lda     #$7F
        jsr     KeyboardScan
        bcc     L093C
        jmp     (CART_COLDSTART)

PrintNewLine:
        lda     #$0D
        jsr     KERNAL_CHROUT
        jsr     WaitRasterLine
        sei
        rts

InsertTargetDisk:
        ldy     #$00
L0959:  lda     TargetDiskTxt,y
        beq     L0965
        jsr     KERNAL_CHROUT
        iny
        jmp     L0959

L0965:  lda     #$01
        jsr     KeyboardScan
        bcs     PrintNewLine2
        lda     #$7F
        jsr     KeyboardScan
        bcc     L0965
        sei
        jmp     (CART_COLDSTART)

; they could have used PrintNewLine
PrintNewLine2:
        lda     #$0D
        jsr     KERNAL_CHROUT
        jsr     WaitRasterLine
        sei
        rts

CopyCompleted:
        lda     #$1B
        sta     VICCTR1
        ldy     #$00
L0988:  lda     CompletedTxt,y
        beq     L0994
        jsr     KERNAL_CHROUT
        iny
        jmp     L0988

L0994:  lda     #$01
        jsr     KeyboardScan
        bcs     PrintNewLine3
        lda     #$7F
        jsr     KeyboardScan
        bcc     L0994
        sei
        ldx     #$FF
        txs
        jmp     (CART_COLDSTART)

; they could have used PrintNewLine
PrintNewLine3:
        lda     #$0D
        jsr     KERNAL_CHROUT
        jsr     WaitRasterLine
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
        and     $DC01
        bne     L09DF
        lda     #$FF
        sta     $DC00
        lda     $DC01
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
L0AFA:  .byte   $00
L0AFB:  .byte   $00
L0AFC:  .byte   $00
; Y reg storage during keyboard scan
tempY:  .byte   $00
L0AFE:  .byte   $00
        .byte   "0123456789ABCDEF"

        .byte   $00,$00
