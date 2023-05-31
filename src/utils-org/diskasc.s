; da65 V2.19 - Git dcdf7ade0
; Created:    2023-05-31 23:38:57
; Input file: ../../firmware/utils/DISKASC.EXE
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
Z_FF            := $00FF
RdDataRamDxxx   := $01A0                        ; read data from 64K RAM (under I/O), after InitStackProg
WrDataRamDxxx   := $01AF                        ; read data from 64K RAM (under I/O), after InitStackProg
COLOR           := $0286                        ; foreground text color
StartofDir      := $0334                        ; page number where directory buffer starts (need 2 pages for a sector)
EndofDir        := $0335                        ; page number where directory buffer ends(?)
TapeBuffer      := $033C
CART_COLDSTART  := $8000                        ; cartridge cold start vector
GetNextCluster  := $87A4                        ; direct call to GetNextCluster instead of jump table _GetNextCluster $803C
GetFATs         := $8813                        ; direct call to GetFATs instead of jump table _GetFATs $8054
CalcFirst       := $883A                        ; direct call to CalcFirst instead of jump table _CalcFirst $8051
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
ReadDirectory   := $8E0F                        ; direct call to ReadDirectory instead of jump table _ReadDirectory $8060
FindFile        := $8FEA                        ; direct call to FindFile instead of jump table _FindFile $805A
SaveRloc        := $9127                        ; direct call to SaveRloc instead of jump table _SaveRloc $8066
ShowBytesFree   := $916A                        ; direct call to ShowBytesFree instead of jump table _ShowBytesFree $806C
ShowError       := $926C                        ; direct call to ShowError instead of jump table _ShowError $8069
VICCTR1         := $D011                        ; control register 1
VICLINE         := $D012                        ; raster line
VICBOCL         := $D020                        ; border color
VICBAC0         := $D021                        ; background color 0
CIA2IRQ         := $DD0D                        ; CIA#2 NMI register
StatusRegister  := $DE80                        ; floppy controller status register
DataRegister    := $DE81                        ; floppy controller data register
ResetFDC00      := $DF00                        ; write here to reset floppy controller (any write to $DFxx)
ResetFDC        := $DF80                        ; write here to reset floppy controller (any write to $DFxx)
KERNAL_SETNAM   := $FFBD                        ; Set file name
KERNAL_CHRIN    := $FFCF                        ; Get a character from the input channel
KERNAL_CHROUT   := $FFD2                        ; Output a character
KERNAL_STOP     := $FFE1                        ; Check if key pressed (RUN/STOP)
KERNAL_GETIN    := $FFE4                        ; Get a character
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
        cli
        ldy     #$00
L101F:  lda     StartupTxt,y
        beq     L102B
        jsr     KERNAL_CHROUT
        iny
        jmp     L101F

L102B:  lda     #$0D
        jsr     KERNAL_CHROUT
        ldy     #$00
L1032:  lda     PromptTxt,y
        beq     L1042
        jsr     KERNAL_CHROUT
        iny
        bne     L1032
        lda     #$0D
        jsr     KERNAL_CHROUT
L1042:  lda     #$FF
L1044:  cmp     VICLINE
        bne     L1044
        ldy     #$00
L104B:  jsr     KERNAL_CHRIN
        sta     $1306,y
        cmp     #$0D
        beq     L105F
        iny
        sty     FNLEN
        cmp     #$0D
        bne     L104B
        jsr     KERNAL_GETIN
L105F:  lda     #$0D
        jsr     KERNAL_CHROUT
        sei
        lda     $1306
        cmp     #$24
        bne     L1072
        jsr     L114A
        jmp     L102B

L1072:  cmp     #$2A
        bne     L1080
        lda     $1307
        cmp     #$58
        bne     L1080
        jmp     (CART_COLDSTART)

L1080:  lda     #$0B
        sta     VICCTR1
        lda     #$06
        sta     FNADR
        lda     #$13
        sta     FNADR+1
        jsr     InitStackProg
        jsr     FindFile
        bcs     L10A8
        lda     #$1B
        sta     VICCTR1
        lda     #$0D
        jsr     KERNAL_CHROUT
        lda     TapeBuffer+21
        jsr     ShowError
        jmp     L102B

L10A8:  lda     #$00
        sta     TapeBuffer+34
        ldy     #$1A
        jsr     RdDataRamDxxx
        iny
        sta     TapeBuffer+30
        jsr     RdDataRamDxxx
        iny
        sta     TapeBuffer+31
        jsr     RdDataRamDxxx
        iny
        sta     TapeBuffer+37
        jsr     RdDataRamDxxx
        iny
        sta     TapeBuffer+36
        jsr     GetFATs
        jsr     CalcFirst
        lda     TapeBuffer+37
        sta     TapeBuffer+38
        lda     TapeBuffer+36
        sta     TapeBuffer+39
L10DD:  lda     #$40
        sta     DirPointer+1
        lda     #$00
        sta     DirPointer
        sei
        lda     #$0B
        sta     VICCTR1
        jsr     SetupSector
        jsr     SeekTrack
        lda     #$02
        sta     NumOfSectors
        lda     #$04
        sta     TapeBuffer+39
        jsr     ReadSectors
        jsr     L1113
        jsr     GetNextCluster
        lda     TapeBuffer+31
        cmp     #$0F
        beq     L1110
        jsr     CalcFirst
        jmp     L10DD

L1110:  jmp     L102B

L1113:  lda     #$1B
        sta     VICCTR1
        ldy     #$00
        sty     DirPointer
        lda     #$40
        sta     DirPointer+1
        ldx     #$1F
        stx     L12FE
        stx     L12FF
L1128:  lda     (DirPointer),y
        iny
        bne     L1136
        inc     DirPointer+1
        ldx     DirPointer+1
        cpx     #$44
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
        jmp     L102B

L114A:  jsr     InitStackProg
        lda     #$07
        sta     Z_FF
        jsr     ReadDirectory
        lda     #$7F
        sta     CIA2IRQ
        jsr     GetFATs
        lda     #$7F
        sta     CIA2IRQ
        lda     #$1B
        sta     VICCTR1
        lda     TapeBuffer+21
        beq     L116D
        clc
        rts

L116D:  lda     #$00
        sta     DirPointer
        lda     StartofDir
        sta     DirPointer+1
        ldy     #$0B
        sei
        jsr     RdDataRamDxxx
        cmp     #$08
        bne     L11A7
        ldy     #$00
L1182:  sei
        jsr     RdDataRamDxxx
        sta     $FD
        tya
        pha
        lda     $FD
        cmp     #$60
        bcc     L1193
        sec
        sbc     #$20
L1193:  jsr     KERNAL_CHROUT
        lda     $FD
        pla
        tay
        iny
        cpy     #$0B
        bne     L1182
        lda     #$0D
        jsr     KERNAL_CHROUT
        jmp     L1207

L11A7:  lda     #$00
        sta     DirPointer
        lda     StartofDir
        sta     DirPointer+1
L11B0:  ldy     #$00
        sei
        jsr     RdDataRamDxxx
        cmp     #$00
        beq     L1235
        cmp     #$E5
        beq     L1207
        ldx     #$07
L11C0:  sei
        jsr     RdDataRamDxxx
        iny
        cmp     #$20
        beq     L11DA
        sta     $FD
        txa
        pha
        tya
        pha
        lda     $FD
        jsr     KERNAL_CHROUT
        lda     $FD
        pla
        tay
        pla
        tax
L11DA:  dex
        bpl     L11C0
        lda     #$2E
        jsr     KERNAL_CHROUT
        ldx     #$02
L11E4:  sei
        jsr     RdDataRamDxxx
        iny
        cmp     #$20
        beq     L11FC
        sta     $FD
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
        bpl     L11E4
        jsr     SaveRloc
        lda     #$0D
        jsr     KERNAL_CHROUT
L1207:  lda     DirPointer
        clc
        adc     #$20
        sta     DirPointer
        lda     DirPointer+1
        adc     #$00
        sta     DirPointer+1
        cmp     EndofDir
        bne     L11B0
        lda     Z_FF
        clc
        adc     #$01
        sta     Z_FF
        cmp     #$0E
        bcs     L1235
        sei
        jsr     ReadDirectory
        lda     #$1B
        sta     VICCTR1
        lda     #$7F
        sta     CIA2IRQ
        jmp     L11A7

L1235:  jsr     ShowBytesFree
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
        .byte   "0123456789ABCDEF"

        .byte   $00,$00,$00
L12FE:  .byte   $00
L12FF:  .byte   $00,$00
