; da65 V2.19 - Git dcdf7ade0
; Created:    2023-06-02 10:43:53
; Input file: ../../firmware/utils/DISKMON.EXE
; Page:       1


        .setcpu "6502"

CPU_PORT        := $0001
PageCounter     := $0002
BASICPRG        := $002B                        ; Basic program start address ($0801)
PtrBasText      := $007A
STATUSIO        := $0090
FlgLoadVerify   := $0093
MSGFLG          := $009D
ENDADDR         := $00AE                        ; End address for LOAD/SAVE/VERIFY
FNLEN           := $00B7
SECADR          := $00B9
CURDEVICE       := $00BA
FNADR           := $00BB
STARTADDR       := $00C1                        ; Start address for LOAD/SAVE/VERIFY
STARTADDR0      := $00C3                        ; Start address for LODA/SAVE/VEFIFY with secondary address SECADR=0
NDX             := $00C6                        ; Number of characters in keyboard queue
RVS             := $00C7                        ; Print reverse characters (0=no)
STARTUP         := $00F0
NumOfSectors    := $00F7
SectorL         := $00F8
SectorH         := $00F9
TempStore       := $00FA
Pointer         := $00FB
J_00FE          := $00FE
Z_FF            := $00FF
RdDataRamDxxx   := $01A0                        ; direct call to RdDataRamDxxx instead of jump table $8081; read data from 64K RAM (under I/O), after InitStackProg
WrDataRamDxxx   := $01AF                        ; (would that be spare call at jump table $8084?); read data from 64K RAM (under I/O), after InitStackProg
COLOR           := $0286                        ; foreground text color
NmiVector       := $0318
ICKOUT          := $0320
ILOAD           := $0330
ISAVE           := $0332
StartofDir      := $0334                        ; page number where directory buffer starts (need 2 pages for a sector)
EndofDir        := $0335                        ; page number where directory buffer ends(?)
NewICKOUT       := $0336
NewNMI          := $0338
FdcST0          := $033C
FdcST1          := $033D
FdcST2          := $033E
FdcC            := $033F
FdcH            := $0340
FdcR            := $0341
FdcN            := $0342
FdcST3          := $0343
FdcPCN          := $0344
FdcCommand      := $0345
FdcHSEL         := $0346
FdcTrack        := $0347
FdcHead         := $0348
FdcSector       := $0349
FdcNumber       := $034A
FdcEOT          := $034B
FdcGPL          := $034C
FdcDTL          := $034D
FdcTrack2       := $034E
FdcTEMP         := $034F
TempStackPtr    := $0350
ErrorCode       := $0351
FdcFormatData   := $0352
FdcSCLUSTER     := $0356
FdcLCLUSTER     := $0358
FdcCLUSTER      := $035A
FdcCLUSTER_2    := $035C
FdcLENGTH       := $035E
FdcBYTESLEFT    := $0362
FdcNBUF         := $0364
FdcPASS         := $0365
Counter         := $0366
FdcOFFSET       := $0367
FdcHOWMANY      := $0368
DirSector       := $0369
FdcLOADAD       := $036A
FdcFileName     := $036C
FdcFILETEM      := $038A
FdcFILELEN      := $0395
FdcTEMP_1       := $0396
FdcTEMP_2       := $0397
FdcTEMP_3       := $0398
A_03F8          := $03F8
NewILOAD        := $03FC
NewISAVE        := $03FE
VICSCN          := $0400
CART_COLDSTART  := $8000                        ; cartridge cold start vector
SaveReloc       := $8472                        ; direct call to SaveReloc instead of jump table _SaveReloc $8063
FindFAT         := $85A8                        ; direct call to FindFAT instead of jump table _FindFAT $8045
ClearFATs       := $8650                        ; direct call to ClearFATs instead of jump table _ClearFATs $804E
NewLoad         := $86BC                        ; direct call to NewLoad instead of jump table _NewLoad $8009
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
FindBlank       := $8F4F                        ; direct call to FindBlank instead of jump table _NewLoad $8078
FindFile        := $8FEA                        ; direct call to FindFile instead of jump table _FindFile $805A
ShowSize        := $9127                        ; direct call to ShowSize instead of jump table _ShowSize $8066
ShowBytesFree   := $916A                        ; direct call to ShowBytesFree instead of jump table _ShowBytesFree $806C
BN2DEC          := $920E                        ; direct call to BN2DEC instead of jump table _BN2DEC $806F
ShowError       := $926C                        ; direct call to ShowError instead of jump table _ShowError $8069
BasicCold       := $A000
BasicNMI        := $A002
VICCTR1         := $D011                        ; control register 1
VICLINE         := $D012                        ; raster line
VICBOCL         := $D020                        ; border color
VICBAC0         := $D021                        ; background color 0
ColourRAM       := $D800
CIA1DRB         := $DC01
CIA1IRQ         := $DC0D                        ; CIA#1 IRQ register
CIA2IRQ         := $DD0D                        ; CIA#2 NMI register
StatusRegister  := $DE80                        ; floppy controller status register
DataRegister    := $DE81                        ; floppy controller data register
ResetFDC00      := $DF00                        ; write here to reset floppy controller (any write to $DFxx)
ResetFDC        := $DF80                        ; write here to reset floppy controller (any write to $DFxx)
InitScreenKeyb  := $E518
IncrClock22     := $F6BC
SetVectorsIO2   := $FD15
TestRAM2        := $FD50
InitSidCIAIrq2  := $FDA3
InitialiseVIC2  := $FF5B
KERNAL_SETLFS   := $FFBA                        ; Set logical file
KERNAL_SETNAM   := $FFBD                        ; Set file name
KERNAL_OPEN     := $FFC0                        ; Open file
KERNAL_CLOSE    := $FFC3                        ; Close file
KERNAL_CHKIN    := $FFC6                        ; Open channel for input
KERNAL_CLRCHN   := $FFCC                        ; Clear I/O channels
KERNAL_CHRIN    := $FFCF                        ; Get a character from the input channel
KERNAL_CHROUT   := $FFD2                        ; Output a character
KERNAL_LOAD     := $FFD5                        ; Load file
KERNAL_STOP     := $FFE1                        ; Check if key pressed (RUN/STOP)
KERNAL_GETIN    := $FFE4                        ; Get a character
NmiVectorRAM    := $FFFA
        lda     #$01
        sta     COLOR
        sta     $028E
        lda     #$06
        sta     VICBOCL
        lda     #$80
        sta     MSGFLG
        lda     #$37
        sta     CPU_PORT
        lda     #$1B
        sta     VICCTR1
        lda     #$93
        jsr     KERNAL_CHROUT
        cli
        ldy     #$00
L1022:  lda     StartupTxt,y
        beq     L102D
        jsr     KERNAL_CHROUT
        iny
        bne     L1022
L102D:  lda     #$0D
        jsr     KERNAL_CHROUT
L1032:  ldx     #$19
L1034:  lda     $D9,x
        ora     #$80
        sta     $D9,x
        dex
        bpl     L1034
        lda     #$FF
L103F:  cmp     VICLINE
        bne     L103F
        lda     #$3E
        jsr     KERNAL_CHROUT
        ldy     #$00
L104B:  jsr     KERNAL_CHRIN
        sta     L1427,y
        iny
        sty     L141C
        cmp     #$0D
        bne     L104B
        ldy     #$00
L105B:  lda     L1427,y
        iny
        cmp     #$3E
        beq     L105B
        cmp     #$52
        bne     L106A
        jmp     L119C

L106A:  cmp     #$4D
        beq     L10ED
        cmp     #$58
        bne     L1075
        jmp     (CART_COLDSTART)

L1075:  cmp     #$3A
        bne     L107C
        jmp     L1214

L107C:  cmp     #$57
        beq     L10C6
        cmp     #$43
        beq     L10CC
        cmp     #$2B
        beq     L108F
        cmp     #$2D
        beq     L10A8
        jmp     L11F1

L108F:  lda     L1421
        clc
        adc     #$01
        sta     L1421
        lda     L1422
        adc     #$00
        sta     L1422
        lda     #$0D
        jsr     KERNAL_CHROUT
        jmp     L1032

L10A8:  lda     L1421
        sec
        sbc     #$01
        bcs     L10B3
        jmp     L11F1

L10B3:  sta     L1421
        lda     L1422
        sbc     #$00
        sta     L1422
        lda     #$0D
        jsr     KERNAL_CHROUT
        jmp     L1032

L10C6:  jsr     L12AD
        jmp     L1032

L10CC:  jsr     L130C
        lda     L141D
        beq     L10D7
        jmp     L11F1

L10D7:  jsr     InitStackProg
        sei
        lda     L1421
        sta     FdcCLUSTER
        lda     L1422
        sta     FdcCLUSTER+1
        jsr     CalcFirst
        jmp     L11B2

L10ED:  lda     #$00
        sta     Pointer
        lda     #$40
        sta     Pointer+1
        lda     #$07
        sta     L141F
        ldy     #$00
        lda     #$3F
        sta     FdcNBUF
        lda     #$0D
        jsr     KERNAL_CHROUT
L1106:  lda     #$3E
        jsr     KERNAL_CHROUT
        lda     #$3A
        jsr     KERNAL_CHROUT
        lda     #$30
        jsr     KERNAL_CHROUT
        lda     Pointer+1
        sec
        sbc     #$10
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
L113A:  lda     (Pointer),y
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
        lda     #$20
        jsr     KERNAL_CHROUT
        dec     L141F
        bpl     L113A
        lda     #$07
        sta     L141F
        tya
        sec
        sbc     #$08
        tay
L1169:  lda     (Pointer),y
        iny
        and     #$7F
        cmp     #$30
        bcs     L1174
        lda     #$2E
L1174:  jsr     KERNAL_CHROUT
        dec     L141F
        bpl     L1169
        lda     #$07
        sta     L141F
        lda     #$0D
        jsr     KERNAL_CHROUT
        cpy     #$00
        bne     L118C
        inc     Pointer+1
L118C:  dec     FdcNBUF
        bmi     L1199
        jsr     KERNAL_STOP
        beq     L1199
        jmp     L1106

L1199:  jmp     L1032

L119C:  jsr     L130C
        lda     L141D
        bne     L11F1
        sei
        jsr     InitStackProg
        lda     L1421
        sta     SectorL
        lda     L1422
        sta     SectorH
L11B2:  jsr     SetupSector
        lda     SectorH
        cmp     #$05
        bcc     L11C4
        lda     SectorL
        cmp     #$A0
        bcc     L11C4
        jmp     L11F1

L11C4:  lda     #$00
        sta     Pointer
        lda     #$40
        sta     Pointer+1
        lda     #$01
        sta     NumOfSectors
        asl     a
        sta     FdcBYTESLEFT+1
        lda     #$00
        sta     FdcBYTESLEFT
        jsr     ReadSectors
        lda     #$1B
        sta     VICCTR1
        lda     ErrorCode
        beq     L11E9
        jsr     ShowError
L11E9:  lda     #$0D
        jsr     KERNAL_CHROUT
        jmp     L1032

L11F1:  lda     #$3F
        jsr     KERNAL_CHROUT
        lda     #$0D
        jsr     KERNAL_CHROUT
        jmp     L1032

L11FE:  lda     #$0A
        stx     $5000
        sty     $5001
        jsr     KERNAL_CHROUT
L1209:  lda     #$1D
        jsr     KERNAL_CHROUT
        dex
        bpl     L1209
        jmp     L11F1

L1214:  lda     #$07
        sta     L141E
        lda     L1427,y
        iny
        cmp     #$30
        bne     L11FE
        lda     L1427,y
        iny
        sec
        sbc     #$30
        cmp     #$02
        bcs     L11FE
        sta     L1422
        tya
        tax
        jsr     L1276
        bcs     L11FE
        lda     L1421
        sta     Pointer
        lda     L1422
        clc
        adc     #$40
        sta     Pointer+1
        ldy     #$00
L1245:  lda     L1427,x
        inx
        cmp     #$20
        beq     L1250
L124D:  jmp     L1032

L1250:  lda     L1427,x
        cmp     #$2E
        beq     L124D
        jsr     L1276
        bcc     L125F
        jmp     L11FE

L125F:  lda     L1421
        sta     (Pointer),y
        iny
        bne     L1269
        inc     Pointer+1
L1269:  dec     L141E
        bpl     L1245
        lda     #$0D
        jsr     KERNAL_CHROUT
        jmp     L1032

L1276:  jsr     L1291
        bcc     L127C
        rts

L127C:  asl     a
        asl     a
        asl     a
        asl     a
        sta     L1421
        jsr     L1291
        bcc     L1289
        rts

L1289:  ora     L1421
        sta     L1421
        clc
        rts

L1291:  lda     L1427,x
        inx
        sec
        sbc     #$30
        bcc     L12AB
        cmp     #$0A
        bcc     L12A9
        cmp     #$11
        bcc     L12AB
        cmp     #$17
        bcs     L12AB
        sec
        sbc     #$07
L12A9:  clc
        rts

L12AB:  sec
        rts

L12AD:  jsr     L130C
        lda     L141D
        beq     L12B8
        jmp     L11F1

L12B8:  sei
        lda     #$0B
        sta     VICCTR1
        jsr     InitStackProg
        lda     L1421
        sta     SectorL
        lda     L1422
        sta     SectorH
        cmp     #$05
        bcc     L12DF
        lda     SectorL
        cmp     #$A0
        bcc     L12DF
        pla
        pla
        lda     #$1B
        sta     VICCTR1
        jmp     L11F1

L12DF:  jsr     SetupSector
        lda     #$01
        sta     NumOfSectors
        lda     #$40
        sta     Pointer+1
        lda     #$00
        sta     Pointer
        jsr     SeekTrack
        jsr     SetWatchdog
        jsr     WriteSector
        jsr     StopWatchdog
        lda     #$1B
        sta     VICCTR1
        lda     ErrorCode
        beq     L1307
        jsr     ShowError
L1307:  lda     #$0D
        jmp     KERNAL_CHROUT

L130C:  ldx     #$00
        stx     L141D
L1311:  lda     L1427,y
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
L1341:  cpy     L141C
        bne     L1311
        cpx     #$00
        beq     L136F
        dex
        lda     #$00
        sta     L1422
        lda     L1423,x
        sta     L1421
        dex
        bmi     L136F
        lda     L1423,x
        asl     a
        asl     a
        asl     a
        asl     a
        ora     L1421
        sta     L1421
        dex
        bmi     L136F
        lda     L1423,x
        sta     L1422
L136F:  rts

L1370:  lda     #$3F
        sta     L141D
        rts

StartupTxt:
        .byte   "DISKMON  IS COPYRIGHT TIB.PLC A"



        .byte   "ND NO    PART OF THIS PROGRAM M"



        .byte   "AY BE RESOLD BY   THE USER WITH"



        .byte   "OUT PERMISION OF TIB.PLC   X   "



        .byte   "     = ABORT TO MAIN MENU"



        .byte   $00
HexDigits:
        .byte   "0123456789ABCDEF"

L141C:  .byte   $00
L141D:  .byte   $00
L141E:  .byte   $00
L141F:  .byte   $00,$00
L1421:  .byte   $00
L1422:  .byte   $00
L1423:  .byte   $00,$00,$00,$00
L1427:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
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
