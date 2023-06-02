; da65 V2.19 - Git dcdf7ade0
; Created:    2023-06-02 10:43:52
; Input file: ../../firmware/utils/DISKHEX.EXE
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
ProgramNameBuf  := $1372
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
        sta     ProgramNameBuf,y
        cmp     #$0D
        beq     L1058
        iny
        bne     L104B
L1058:  sty     FNLEN
        cpy     #$00
        beq     L102B
        lda     #$FF
        sta     ProgramNameBuf,y
        jsr     KERNAL_GETIN
        lda     #$0D
        jsr     KERNAL_CHROUT
        sei
        lda     ProgramNameBuf
        cmp     #$24
        bne     L1079
        jsr     L11B6
        jmp     L102B

L1079:  cmp     #$2A
        bne     L1087
        lda     ProgramNameBuf+1
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
        lda     ErrorCode
        jsr     ShowError
        jmp     L102B

L10AF:  lda     #$00
        sta     FdcLENGTH
        ldy     #$1A
        jsr     RdDataRamDxxx
        iny
        sta     FdcCLUSTER
        jsr     RdDataRamDxxx
        iny
        sta     FdcCLUSTER+1
        jsr     RdDataRamDxxx
        iny
        sta     FdcLENGTH+3
        jsr     RdDataRamDxxx
        iny
        sta     FdcLENGTH+2
        jsr     GetFATs
        jsr     CalcFirst
        lda     FdcLENGTH+3
        sta     FdcBYTESLEFT
        lda     FdcLENGTH+2
        sta     FdcBYTESLEFT+1
L10E4:  lda     #$40
        sta     Pointer+1
        lda     #$00
        sta     Pointer
        sei
        lda     #$0B
        sta     VICCTR1
        jsr     SetupSector
        jsr     SeekTrack
        lda     #$02
        sta     NumOfSectors
        lda     #$04
        sta     FdcBYTESLEFT+1
        jsr     ReadSectors
        jsr     L1123
        lda     FdcLENGTH
        clc
        adc     #$04
        sta     FdcLENGTH
        jsr     GetNextCluster
        lda     FdcCLUSTER+1
        cmp     #$0F
        beq     L1120
        jsr     CalcFirst
        jmp     L10E4

L1120:  jmp     L102B

L1123:  lda     #$1B
        sta     VICCTR1
        ldy     #$00
        sty     Pointer
        lda     #$40
        sta     Pointer+1
        ldx     #$0F
        stx     L136A
        lda     #$3F
        sta     L136B
L113A:  lda     FdcLENGTH
        sec
        sbc     #$40
        clc
        adc     Pointer+1
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
L1178:  lda     (Pointer),y
        iny
        bne     L117F
        inc     Pointer+1
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
        lda     ErrorCode
        beq     L11D9
        clc
        rts

L11D9:  lda     #$00
        sta     Pointer
        lda     StartofDir
        sta     Pointer+1
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
        sta     Pointer
        lda     StartofDir
        sta     Pointer+1
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
        jsr     ShowSize
        lda     #$0D
        jsr     KERNAL_CHROUT
L1273:  lda     Pointer
        clc
        adc     #$20
        sta     Pointer
        lda     Pointer+1
        adc     #$00
        sta     Pointer+1
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
