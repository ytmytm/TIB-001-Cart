; da65 V2.19 - Git dcdf7ade0
; Created:    2023-05-31 23:45:47
; Input file: ../../firmware/utils/DISKHEX.EXE
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
        sta     $1372,y
        cmp     #$0D
        beq     L1058
        iny
        bne     L104B
L1058:  sty     FNLEN
        cpy     #$00
        beq     L102B
        lda     #$FF
        sta     $1372,y
        jsr     KERNAL_GETIN
        lda     #$0D
        jsr     KERNAL_CHROUT
        sei
        lda     $1372
        cmp     #$24
        bne     L1079
        jsr     L11B6
        jmp     L102B

L1079:  cmp     #$2A
        bne     L1087
        lda     $1373
        cmp     #$58
        bne     L1087
        jmp     (CART_COLDSTART)

L1087:  lda     #$0B
        sta     VICCTR1
        lda     #$72
        sta     FNADR
        lda     #$13
        sta     FNADR+1
        jsr     InitStackProg
        jsr     FindFile
        bcs     L10AF
        lda     #$1B
        sta     VICCTR1
        lda     #$0D
        jsr     KERNAL_CHROUT
        lda     TapeBuffer+21
        jsr     ShowError
        jmp     L102B

L10AF:  lda     #$00
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
L10E4:  lda     #$40
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
        jsr     L1123
        lda     TapeBuffer+34
        clc
        adc     #$04
        sta     TapeBuffer+34
        jsr     GetNextCluster
        lda     TapeBuffer+31
        cmp     #$0F
        beq     L1120
        jsr     CalcFirst
        jmp     L10E4

L1120:  jmp     L102B

L1123:  lda     #$1B
        sta     VICCTR1
        ldy     #$00
        sty     DirPointer
        lda     #$40
        sta     DirPointer+1
        ldx     #$0F
        stx     L136A
        lda     #$3F
        sta     L136B
L113A:  lda     TapeBuffer+34
        sec
        sbc     #$40
        clc
        adc     DirPointer+1
        pha
        and     #$F0
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        tax
        lda     HexDigits,x
        jsr     KERNAL_CHROUT
        pla
        and     #$0F
        tax
        lda     HexDigits,x
        jsr     KERNAL_CHROUT
        tya
        and     #$F0
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        tax
        lda     HexDigits,x
        jsr     KERNAL_CHROUT
        tya
        and     #$0F
        tax
        lda     HexDigits,x
        jsr     KERNAL_CHROUT
        lda     #$20
        jsr     KERNAL_CHROUT
L1178:  lda     (DirPointer),y
        iny
        bne     L117F
        inc     DirPointer+1
L117F:  pha
        and     #$F0
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        tax
        lda     HexDigits,x
        jsr     KERNAL_CHROUT
        pla
        and     #$0F
        tax
        lda     HexDigits,x
        jsr     KERNAL_CHROUT
        dec     L136A
        bpl     L1178
        jsr     KERNAL_STOP
        beq     L11B1
        lda     #$0F
        sta     L136A
        lda     #$0D
        jsr     KERNAL_CHROUT
        dec     L136B
        bpl     L113A
        rts

L11B1:  pla
        pla
        jmp     L102B

L11B6:  jsr     InitStackProg
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
        beq     L11D9
        clc
        rts

L11D9:  lda     #$00
        sta     DirPointer
        lda     StartofDir
        sta     DirPointer+1
        ldy     #$0B
        sei
        jsr     RdDataRamDxxx
        cmp     #$08
        bne     L1213
        ldy     #$00
L11EE:  sei
        jsr     RdDataRamDxxx
        sta     $FD
        tya
        pha
        lda     $FD
        cmp     #$60
        bcc     L11FF
        sec
        sbc     #$20
L11FF:  jsr     KERNAL_CHROUT
        lda     $FD
        pla
        tay
        iny
        cpy     #$0B
        bne     L11EE
        lda     #$0D
        jsr     KERNAL_CHROUT
        jmp     L1273

L1213:  lda     #$00
        sta     DirPointer
        lda     StartofDir
        sta     DirPointer+1
L121C:  ldy     #$00
        sei
        jsr     RdDataRamDxxx
        cmp     #$00
        beq     L12A1
        cmp     #$E5
        beq     L1273
        ldx     #$07
L122C:  sei
        jsr     RdDataRamDxxx
        iny
        cmp     #$20
        beq     L1246
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
L1246:  dex
        bpl     L122C
        lda     #$2E
        jsr     KERNAL_CHROUT
        ldx     #$02
L1250:  sei
        jsr     RdDataRamDxxx
        iny
        cmp     #$20
        beq     L1268
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
L1268:  dex
        bpl     L1250
        jsr     SaveRloc
        lda     #$0D
        jsr     KERNAL_CHROUT
L1273:  lda     DirPointer
        clc
        adc     #$20
        sta     DirPointer
        lda     DirPointer+1
        adc     #$00
        sta     DirPointer+1
        cmp     EndofDir
        bne     L121C
        lda     Z_FF
        clc
        adc     #$01
        sta     Z_FF
        cmp     #$0E
        bcs     L12A1
        sei
        jsr     ReadDirectory
        lda     #$1B
        sta     VICCTR1
        lda     #$7F
        sta     CIA2IRQ
        jmp     L1213

L12A1:  jsr     ShowBytesFree
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

        .byte   $00,$00,$00
L136A:  .byte   $00
L136B:  .byte   $00,$00,$00,$00,$00,$00
