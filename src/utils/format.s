; da65 V2.19 - Git dcdf7ade0
; Created:    2023-06-02 10:30:04
; Input file: ../../firmware/utils/FORMAT.EXE
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
FileNameBuf     := $0961                        ; Buffer to store file name
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
        lda     #$C0
        sta     StartofDir
        lda     #$C2
        sta     EndofDir
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
L0829:  lda     StartupTxt,y
        beq     L0835
        jsr     KERNAL_CHROUT
        iny
        jmp     L0829

L0835:  lda     #$00
        sta     NDX
        lda     #$0D
        jsr     KERNAL_CHROUT
        ldy     #$00
L0840:  lda     PromptTxt,y
        beq     L0850
        jsr     KERNAL_CHROUT
        iny
        bne     L0840
        lda     #$0D
        jsr     KERNAL_CHROUT
L0850:  lda     #$FF
L0852:  cmp     VICLINE
        bne     L0852
        ldy     #$00
L0859:  jsr     KERNAL_CHRIN
        cmp     #$0D
        beq     L0864
        sta     FileNameBuf,y
        iny
L0864:  sty     FNLEN
        cmp     #$0D
        bne     L0859
        lda     #$22
        sta     FileNameBuf,y
        jsr     KERNAL_GETIN
        lda     #$0D
        jsr     KERNAL_CHROUT
        sei
        lda     #$0B
        sta     VICCTR1
        lda     FileNameBuf
        cmp     #$2A
        bne     L0887
        jmp     (CART_COLDSTART)

L0887:  lda     #$61
        sta     FNADR
        lda     #$09
        sta     FNADR+1
        jsr     FormatDisk
        jmp     L0835

PromptTxt:
        .byte   "PLEASE ENTER DISK NAME >"


        .byte   $00
StartupTxt:
        .byte   "DISK FORMAT IS COPYRIGHT TIB.PL"



        .byte   "C AND NO    PART OF THIS PROGRA"



        .byte   "M MAY BE RESOLD BY   THE USER W"



        .byte   "ITHOUT PERMISION OF TIB.PLC   *"



        .byte   "       = ABORT TO MAIN MENU"



        .byte   $00
        .byte   "0123456789ABCDEF"

        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00
