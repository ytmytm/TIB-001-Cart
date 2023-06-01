; da65 V2.19 - Git dcdf7ade0
; Created:    2023-06-01 22:55:20
; Input file: ../../firmware/utils/FILECOPY.EXE
; Page:       1


        .setcpu "6502"

P6510           := $0001                        ; DR onboard I/O port of 6510
BASICPRG        := $002B                        ; Basic program start address ($0801)
MSGFLG          := $0090                        ; Kernal I/O status (0=ok, bit 7=device not present, bit 6=end of file
MSGFLG          := $009D                        ; Kernal message control (bit 7=show control, bit 6=show error); $80=direct mode, $00=program mode
ENDADDR         := $00AE                        ; End address for LOAD/SAVE/VERIFY
FNLEN           := $00B7                        ; Length of current filename, set by SETNAM
SECADR          := $00B9                        ; Current secondary address
CURDEVICE       := $00BA                        ; Current device number
FNADR           := $00BB                        ; Pointer to current filename, set by SETNAM
STARTADDR       := $00C1                        ; Start address for LOAD/SAVE/VERIFY
STARTADDR0      := $00C3                        ; Start address for LODA/SAVE/VEFIFY with secondary address SECADR=0
NDX             := $00C6                        ; Number of characters in keyboard queue
RVS             := $00C7                        ; Print reverse characters (0=no)
NumOfSectors    := $00F7
SectorL         := $00F8
SectorH         := $00F9
DirPointer      := $00FB
Z_FD            := $00FD                        ; $FD location, free to use
Z_FF            := $00FF
RdDataRamDxxx   := $01A0                        ; direct call to RdDataRamDxxx instead of jump table $8081; read data from 64K RAM (under I/O), after InitStackProg
WrDataRamDxxx   := $01AF                        ; (would that be spare call at jump table $8084?); read data from 64K RAM (under I/O), after InitStackProg
COLOR           := $0286                        ; foreground text color
StartofDir      := $0334                        ; page number where directory buffer starts (need 2 pages for a sector)
EndofDir        := $0335                        ; page number where directory buffer ends(?)
TapeBuffer      := $033C
L0604           := $0604
L0680           := $0680
FilenameBuffer  := $1089
CART_COLDSTART  := $8000                        ; cartridge cold start vector
J_8472          := $8472                        ; direct call to J_8472 instead of jump table _J_8472 $8063
FindFAT         := $85A8                        ; direct call to FindFAT instead of jump table _FindFAT $8045
ShowError       := $8650                        ; direct call to ClearFATs instead of jump table _ClearFATs $804E
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
SaveRloc        := $9127                        ; direct call to SaveRloc instead of jump table _SaveRloc $8066
ShowBytesFree   := $916A                        ; direct call to ShowBytesFree instead of jump table _ShowBytesFree $806C
BN2DEC          := $920E                        ; direct call to BN2DEC instead of jump table _BN2DEC $806F
ShowError       := $926C                        ; direct call to ShowError instead of jump table _ShowError $8069
LC100           := $C100
LC19E           := $C19E
VICCTR1         := $D011                        ; control register 1
VICLINE         := $D012                        ; raster line
VICBOCL         := $D020                        ; border color
VICBAC0         := $D021                        ; background color 0
CIA1IRQ         := $DC0D                        ; CIA#1 IRQ register
CIA2IRQ         := $DD0D                        ; CIA#2 NMI register
StatusRegister  := $DE80                        ; floppy controller status register
DataRegister    := $DE81                        ; floppy controller data register
ResetFDC00      := $DF00                        ; write here to reset floppy controller (any write to $DFxx)
ResetFDC        := $DF80                        ; write here to reset floppy controller (any write to $DFxx)
LE60A           := $E60A
LED09           := $ED09
LED0C           := $ED0C
LED11           := $ED11
LEDB9           := $EDB9
LEDC7           := $EDC7
LEDDD           := $EDDD
LEDFE           := $EDFE
LEE13           := $EE13
LF291           := $F291
LF32F           := $F32F
LF34A           := $F34A
LF3E6           := $F3E6
LF50A           := $F50A
LF5D2           := $F5D2
LF5E9           := $F5E9
LF5ED           := $F5ED
LF642           := $F642
LF64B           := $F64B
LF6ED           := $F6ED
LF8E0           := $F8E0
LF969           := $F969
LFB8E           := $FB8E
LFCD1           := $FCD1
LFCDB           := $FCDB
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
        lda     #$F6
        sta     StartofDir
        lda     #$F8
        sta     EndofDir
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
        lda     #$08
        sta     L106C
        lda     #$09
        sta     L106D
        lda     #$93
        jsr     KERNAL_CHROUT
        cli
        ldy     #$00
L0833:  lda     StartupTxt,y
        beq     L083F
        jsr     KERNAL_CHROUT
        iny
        jmp     L0833

L083F:  lda     #$00
        sta     NDX
        lda     #$0D
        jsr     KERNAL_CHROUT
        ldy     #$00
L084A:  lda     PromptTxt,y
        beq     L085A
        jsr     KERNAL_CHROUT
        iny
        bne     L084A
        lda     #$0D
        jsr     KERNAL_CHROUT
L085A:  lda     #$FF
L085C:  cmp     VICLINE
        bne     L085C
        ldy     #$00
L0863:  jsr     KERNAL_CHRIN
        sta     FilenameBuffer,y
        cmp     #$0D
        beq     L0874
        iny
        sty     FNLEN
        cmp     #$0D
        bne     L0863
L0874:  jsr     KERNAL_GETIN
        lda     #$0D
        jsr     KERNAL_CHROUT
        lda     L106C
        sta     CURDEVICE
        sei
        lda     #$0B
        sta     VICCTR1
        lda     #$89
        sta     FNADR
        lda     #$10
        sta     FNADR+1
        jsr     InitStackProg
        lda     FilenameBuffer
        cmp     #$24
        beq     L08F1
        cmp     #$2A
        bne     L08A0
        jmp     L0959

L08A0:  lda     #$0F
        sta     $B8
        sta     SECADR
        ldx     #$00
        ldy     #$11
        lda     #$00
        sta     SECADR
        lda     CURDEVICE
        cmp     #$09
        beq     L08F7
        cmp     #$08
        beq     L08C9
        lda     #$1B
        sta     VICCTR1
        lda     #$00
        cli
        jsr     KERNAL_LOAD
        sei
        bcs     L08D3
        jmp     L0909

L08C9:  lda     #$00
        jsr     L0BD1
        bcs     L08D3
        jmp     L0909

L08D3:  lda     #$0B
        sta     TapeBuffer+21
        lda     #$1B
        sta     VICCTR1
        lda     #$0D
        jsr     KERNAL_CHROUT
        lda     TapeBuffer+21
        jsr     ShowError
L08E8:  lda     #$81
        sta     CIA1IRQ
        cli
        jmp     L083F

L08F1:  jsr     L09CB
        jmp     L083F

L08F7:  jsr     NewLoad
        lda     TapeBuffer+21
        bne     L08E8
        lda     TapeBuffer+46
        sta     RVS
        lda     TapeBuffer+47
        sta     NDX
L0909:  lda     NDX
        sta     TapeBuffer+47
        lda     RVS
        sta     TapeBuffer+46
        lda     #$00
        sta     NDX
        sta     RVS
        stx     ENDADDR
        sty     ENDADDR+1
        lda     #$1B
        sta     VICCTR1
        lda     #$81
        sta     CIA1IRQ
        cli
        jsr     L0991
        sei
        jsr     InitStackProg
        lda     TapeBuffer+46
        sta     NDX
        lda     TapeBuffer+47
        sta     RVS
        lda     #$11
        sta     BASICPRG+1
        lda     #$00
        sta     BASICPRG
        lda     L106D
        sta     CURDEVICE
        lda     #$2B
        ldx     ENDADDR
        ldy     ENDADDR+1
        sei
        jsr     L0ABE
        cli
        lda     #$1B
        sta     VICCTR1
        jmp     L083F

L0959:  lda     $108A
        cmp     #$58
        bne     L0963
        jmp     (CART_COLDSTART)

L0963:  sec
        sbc     #$30
        bcs     L0971
L0968:  lda     #$1B
        sta     VICCTR1
        cli
        jmp     L083F

L0971:  cmp     #$0A
        bcs     L0968
        sta     L106C
        lda     $108B
        cmp     #$2C
        bne     L0968
        lda     $108C
        sec
        sbc     #$30
        bcc     L0968
        cmp     #$0A
        bcs     L0968
        sta     L106D
        jmp     L0968

L0991:  lda     #$0D
        jsr     KERNAL_CHROUT
        ldy     #$00
L0998:  lda     PromptNewTxt,y
        beq     L09A8
        jsr     KERNAL_CHROUT
        iny
        bne     L0998
        lda     #$0D
        jsr     KERNAL_CHROUT
L09A8:  lda     #$FF
L09AA:  cmp     VICLINE
        bne     L09AA
        ldy     #$00
L09B1:  jsr     KERNAL_CHRIN
        sta     FilenameBuffer,y
        cmp     #$0D
        beq     L09C2
        iny
        sty     FNLEN
        cmp     #$0D
        bne     L09B1
L09C2:  jsr     KERNAL_GETIN
        lda     #$0D
        jsr     KERNAL_CHROUT
        rts

L09CB:  sei
        lda     #$07
        sta     Z_FF
        jsr     ReadDirectory
        lda     TapeBuffer+21
        bne     L09E0
        lda     #$7F
        sta     CIA2IRQ
        jsr     GetFATs
L09E0:  jsr     StopWatchdog
        lda     #$1B
        sta     VICCTR1
        lda     TapeBuffer+21
        beq     L09F2
        jsr     ShowError
        clc
        rts

L09F2:  lda     #$00
        sta     DirPointer
        lda     StartofDir
        sta     DirPointer+1
        ldy     #$0B
        sei
        jsr     RdDataRamDxxx
        cmp     #$08
        bne     L0A2C
        ldy     #$00
L0A07:  sei
        jsr     RdDataRamDxxx
        sta     Z_FD
        tya
        pha
        lda     Z_FD
        cmp     #$60
        bcc     L0A18
        sec
        sbc     #$20
L0A18:  jsr     KERNAL_CHROUT
        lda     Z_FD
        pla
        tay
        iny
        cpy     #$0B
        bne     L0A07
        lda     #$0D
        jsr     KERNAL_CHROUT
        jmp     L0A8C

L0A2C:  lda     #$00
        sta     DirPointer
        lda     StartofDir
        sta     DirPointer+1
L0A35:  ldy     #$00
        sei
        jsr     RdDataRamDxxx
        cmp     #$00
        beq     L0ABA
        cmp     #$E5
        beq     L0A8C
        ldx     #$07
L0A45:  sei
        jsr     RdDataRamDxxx
        iny
        cmp     #$20
        beq     L0A5F
        sta     Z_FD
        txa
        pha
        tya
        pha
        lda     Z_FD
        jsr     KERNAL_CHROUT
        lda     Z_FD
        pla
        tay
        pla
        tax
L0A5F:  dex
        bpl     L0A45
        lda     #$2E
        jsr     KERNAL_CHROUT
        ldx     #$02
L0A69:  sei
        jsr     RdDataRamDxxx
        iny
        cmp     #$20
        beq     L0A81
        sta     Z_FD
        txa
        pha
        tya
        pha
        lda     Z_FD
        jsr     KERNAL_CHROUT
        pla
        tay
        pla
        tax
L0A81:  dex
        bpl     L0A69
        jsr     SaveRloc
        lda     #$0D
        jsr     KERNAL_CHROUT
L0A8C:  lda     DirPointer
        clc
        adc     #$20
        sta     DirPointer
        lda     DirPointer+1
        adc     #$00
        sta     DirPointer+1
        cmp     EndofDir
        bne     L0A35
        lda     Z_FF
        clc
        adc     #$01
        sta     Z_FF
        cmp     #$0E
        bcs     L0ABA
        sei
        jsr     ReadDirectory
        lda     #$1B
        sta     VICCTR1
        lda     #$7F
        sta     CIA2IRQ
        jmp     L0A2C

L0ABA:  jsr     ShowBytesFree
        rts

L0ABE:  stx     ENDADDR
        sty     ENDADDR+1
        tax
        lda     $00,x
        sta     STARTADDR
        lda     P6510,x
        sta     STARTADDR+1
        lda     NDX
        sta     $AC
        lda     RVS
        sta     $AD
        sei
        stx     TapeBuffer+43
        lda     CURDEVICE
        cmp     #$09
        beq     L0AF4
        cmp     #$08
        beq     L0AF1
        cli
        jsr     LF5ED
        sei
        lda     #$F6
        sta     StartofDir
        lda     #$F8
        sta     EndofDir
        rts

L0AF1:  jmp     L0F04

L0AF4:  lda     ENDADDR
        sec
        sbc     $00,x
        sta     TapeBuffer+37
        lda     ENDADDR+1
        sbc     P6510,x
        sta     TapeBuffer+36
        sta     TapeBuffer+40
        bcs     L0B13
        lda     #$0D
        jsr     ShowError
        lda     #$1B
        sta     VICCTR1
        rts

L0B13:  lsr     TapeBuffer+40
        lsr     TapeBuffer+40
        inc     TapeBuffer+40
        lda     TapeBuffer+40
        sta     TapeBuffer+44
        jsr     InitStackProg
        lda     TapeBuffer+7
        and     #$40
        beq     L0B34
        lda     #$01
        sta     TapeBuffer+21
        jmp     ShowError

L0B34:  jsr     GetFATs
        jsr     FindFile
        bcc     L0B61
        lda     TapeBuffer+21
        beq     L0B4A
        jsr     ShowError
        lda     #$1B
        sta     VICCTR1
        rts

L0B4A:  lda     #$7F
        sta     CIA2IRQ
        lda     DirPointer
        pha
        lda     DirPointer+1
        pha
        jsr     ShowError
        pla
        sta     DirPointer+1
        pla
        sta     DirPointer
        jmp     L0B72

L0B61:  jsr     FindBlank
        lda     TapeBuffer+21
        beq     L0B72
        jsr     ShowError
        lda     #$1B
        sta     VICCTR1
        rts

L0B72:  lda     #$7F
        sta     CIA2IRQ
        lda     DirPointer+1
        pha
        lda     DirPointer
        pha
        ldx     #$00
        jsr     FindFAT
        pla
        sta     DirPointer
        pla
        sta     DirPointer+1
        ldy     #$16
        lda     #$79
        jsr     WrDataRamDxxx
        iny
        lda     #$0C
        jsr     WrDataRamDxxx
        iny
        lda     #$05
        jsr     WrDataRamDxxx
        iny
        lda     #$17
        jsr     WrDataRamDxxx
        iny
        lda     TapeBuffer+30
        jsr     WrDataRamDxxx
        iny
        lda     TapeBuffer+31
        jsr     WrDataRamDxxx
        iny
        lda     TapeBuffer+37
        jsr     WrDataRamDxxx
        iny
        lda     TapeBuffer+36
        jsr     WrDataRamDxxx
        iny
        ldx     TapeBuffer+43
        lda     RVS
        ldy     #$10
        jsr     WrDataRamDxxx
        iny
        lda     NDX
        jsr     WrDataRamDxxx
        jmp     J_8472

L0BD1:  stx     STARTADDR0
        sty     STARTADDR0+1
        sta     $93
        lda     #$7F
        sta     CIA1IRQ
        lda     CIA1IRQ
        ldy     #$00
        sty     $02A1
        sty     $D015
        lda     (FNADR),y
        cmp     #$24
        bne     L0BF0
        jmp     L0BF8

L0BF0:  jsr     DriveCodeEND_
        lda     #$1B
        sta     VICCTR1
L0BF8:  rts

        lda     #$01
        ldx     #$08
        ldy     #$00
        sty     $02A1
        sty     $98
        sty     $94
        sty     $D015
        jsr     KERNAL_SETLFS
        lda     #$02
        ldx     #$9F
        ldy     #$0C
        jsr     KERNAL_SETNAM
        jsr     KERNAL_OPEN
        lda     MSGFLG
        and     #$80
        bne     L0BF8
        ldx     #$01
        jsr     KERNAL_CHKIN
        jsr     KERNAL_CHRIN
        lda     MSGFLG
        and     #$40
        bne     L0BF8
        jsr     KERNAL_CHRIN
        lda     MSGFLG
        and     #$40
        bne     L0BF8
L0C35:  jsr     KERNAL_CHRIN
        sta     TapeBuffer+90
        jsr     KERNAL_CHRIN
        ora     TapeBuffer+90
        beq     L0C94
        jsr     KERNAL_CHRIN
        sta     TapeBuffer+91
        jsr     KERNAL_CHRIN
        sta     TapeBuffer+92
        jsr     BN2DEC
        ldy     #$04
        ldx     #$00
        stx     TapeBuffer+19
L0C59:  lda     TapeBuffer+40,y
        bit     TapeBuffer+19
        bmi     L0C6C
        cpy     #$00
        beq     L0C6C
        cmp     #$30
        beq     L0C6C
        dec     TapeBuffer+19
L0C6C:  inx
        dey
        bpl     L0C59
        ldx     #$08
L0C72:  jsr     KERNAL_CHRIN
        cmp     #$42
        beq     L0C7D
        cmp     #$22
        bne     L0C72
L0C7D:  inx
L0C7E:  jsr     KERNAL_CHRIN
        beq     L0C86
        inx
        bne     L0C7E
L0C86:  cmp     #$14
        beq     L0C94
L0C8A:  beq     L0C35
        cmp     #$0D
        beq     L0C94
        iny
        jmp     L0C8A

L0C94:  lda     #$01
        jsr     KERNAL_CLOSE
        jsr     KERNAL_CLRCHN
        lda     #$0D
        rts

CBMDirectoryName:
        .byte   "$0"
; 1541 turbo code
DriveCode_:
        lda     #$03
        sta     $31
L0CA5:  jsr     LF50A
L0CA8:  bvc     L0CA8
        clv
        lda     $1C01
        sta     $0300,y
        iny
        bne     L0CA8
        ldy     #$BA
L0CB6:  bvc     L0CB6
        clv
        lda     $1C01
        sta     $0100,y
        iny
        bne     L0CB6
        jsr     LF8E0
        lda     $38
        cmp     $47
        beq     L0CCE
        jmp     L0604

L0CCE:  jsr     LF5E9
        cmp     $3A
        beq     L0CD8
        jmp     L0604

L0CD8:  lda     $0300
        beq     L0D07
        ldx     #$00
L0CDF:  lda     $0300,x
        jsr     L0680
        inx
        bne     L0CDF
        lda     $0300
        cmp     $0C
        bne     L0CFB
        lda     $0301
        sta     $0D
        lda     $0300
        sta     $0C
        bne     L0CA5
L0CFB:  sta     $0C
        lda     $0301
        sta     $0D
        lda     #$01
        jmp     LF969

L0D07:  ldx     #$00
        inc     $0301
L0D0C:  lda     $0300,x
        jsr     L0680
        inx
        cpx     $0301
        bne     L0D0C
        lda     #$7F
        jmp     LF969

        asl     a
        php
        .byte   $02
        brk
        sta     $85
        stx     $82
        tax
L0D26:  bit     $1800
        bpl     L0D26
        ldy     #$10
        sty     $1800
        and     #$03
        tay
        lda     $067C,y
L0D36:  bit     $1800
        bmi     L0D36
        sta     $1800
        txa
        lsr     a
        lsr     a
        tax
        and     #$03
        tay
        lda     $067C,y
        sta     $1800
        txa
        lsr     a
        lsr     a
        tax
        and     #$03
        tay
        lda     $067C,y
        sta     $1800
        txa
        lsr     a
        lsr     a
        tax
        and     #$03
        tay
        lda     $067C,y
        sta     $1800
        ldx     $82
        rts

        jsr     LC100
        lda     $18
        ldx     $19
        sta     $0C
        stx     $0D
        sta     $0300
        stx     $0301
L0D79:  lda     #$E0
        sta     $03
L0D7D:  lda     $03
        bmi     L0D7D
        cmp     #$02
        bcc     L0D79
        cmp     #$7F
        beq     L0D8C
        jmp     LE60A

L0D8C:  jmp     LC19E

; 1541 turbo code end
DriveCodeEND_:
        jsr     LF32F
        ldx     SECADR
        stx     $02
        lda     #$60
        sta     SECADR
        jsr     LF34A
        lda     CURDEVICE
        jsr     LED09
        lda     SECADR
        jsr     LEDC7
        jsr     LEE13
        lda     CURDEVICE
        jsr     LF291
        lda     MSGFLG
        lsr     a
        lsr     a
        bcc     L0DBE
        rts

DOSCommand:
        .byte   "M-WM-E"
        .byte   $C7
        .byte   $06
L0DBE:  jsr     LF5D2
        lda     #$A1
        sta     $03
        lda     #$0C
        sta     $04
        lda     #$00
        sta     $05
        lda     #$06
        sta     $06
L0DD1:  lda     CURDEVICE
        jsr     LED0C
        lda     #$6F
        jsr     LEDB9
        ldy     #$00
L0DDD:  lda     DOSCommand,y
        jsr     LEDDD
        iny
        cpy     #$03
        bne     L0DDD
        lda     $05
        jsr     LEDDD
        lda     $06
        jsr     LEDDD
        lda     #$20
        jsr     LEDDD
        ldy     #$00
L0DF9:  lda     ($03),y
        jsr     LEDDD
        iny
        cpy     #$20
        bcc     L0DF9
        jsr     LEDFE
        clc
        lda     $03
        adc     #$20
        sta     $03
        bcc     L0E11
        inc     $04
L0E11:  clc
        lda     $05
        adc     #$20
        sta     $05
        bcc     L0E1C
        inc     $06
L0E1C:  ldx     $06
        cpx     #$07
        bcc     L0DD1
        lda     CURDEVICE
        jsr     LED0C
        lda     #$6F
        jsr     LEDB9
        ldy     #$03
L0E2E:  lda     DOSCommand,y
        jsr     LEDDD
        iny
        cpy     #$08
        bne     L0E2E
        jsr     LEDFE
        lda     VICCTR1
        sta     TapeBuffer+90
        lda     #$0B
        sta     VICCTR1
        sei
        ldy     #$00
        ldx     #$04
L0E4C:  jsr     L0EB2
        beq     L0E6C
        jsr     L0EB2
        cpx     #$02
        beq     L0E5B
        jsr     L0E97
L0E5B:  jsr     L0EB2
        jsr     L0EF6
        bne     L0E65
        inc     ENDADDR+1
L0E65:  inx
        bne     L0E5B
        ldx     #$02
        bne     L0E4C
L0E6C:  jsr     L0EB2
        cpx     #$02
        beq     L0E78
        pha
        jsr     L0E97
        pla
L0E78:  tax
        dex
        dex
L0E7B:  jsr     L0EB2
        jsr     L0EF6
        bne     L0E85
        inc     ENDADDR+1
L0E85:  dex
        bne     L0E7B
        tya
        clc
        adc     ENDADDR
        sta     ENDADDR
        tax
        lda     ENDADDR+1
        adc     #$00
        sta     ENDADDR+1
        tay
        rts

L0E97:  jsr     L0EB2
        sta     ENDADDR
        sta     NDX
        jsr     L0EB2
        sta     ENDADDR+1
        sta     RVS
        lda     $02
        bne     L0EB1
        lda     STARTADDR0
        sta     ENDADDR
        lda     STARTADDR0+1
        sta     ENDADDR+1
L0EB1:  rts

L0EB2:  lda     #$0B
        sta     $DD00
        lda     #$03
L0EB9:  bit     $DD00
        bpl     L0EB9
        sta     $DD00
        dec     VICBOCL
        lda     $02A6
        beq     L0EC9
L0EC9:  beq     L0ECB
L0ECB:  nop
        lda     $DD00
        asl     a
        ror     $A4
        asl     a
        ror     $A4
        lda     $DD00
        asl     a
        ror     $A4
        asl     a
        ror     $A4
        lda     $DD00
        asl     a
        ror     $A4
        asl     a
        ror     $A4
        lda     $DD00
        asl     a
        ror     $A4
        asl     a
        ror     $A4
        inc     VICBOCL
        lda     $A4
        rts

L0EF6:  pha
        lda     #$30
        sta     P6510
        pla
        sta     (ENDADDR),y
        lda     #$37
        sta     P6510
        iny
        rts

L0F04:  lda     #$7F
        sta     CIA1IRQ
        lda     CIA1IRQ
        lda     VICCTR1
        sta     TapeBuffer+90
        and     #$6F
        sta     VICCTR1
        lda     #$61
        sta     SECADR
        ldy     FNLEN
        bne     L0F20
        rts

L0F20:  lda     #$00
        sta     MSGFLG
        lda     CURDEVICE
        ora     #$20
        jsr     LED11
        jsr     LF3E6
        lda     CURDEVICE
        ora     #$20
        jsr     LED11
        lda     SECADR
        jsr     LEDB9
        ldy     #$00
        lda     $AC
        ora     $AD
        bne     L0F45
        jsr     LFB8E
L0F45:  lda     $AC
        jsr     LEDDD
        lda     $AD
        jsr     LEDDD
        lda     $AC
        ora     $AD
        beq     L0F58
        jsr     LFB8E
L0F58:  jsr     LFCD1
        bcs     L0F85
        inc     VICBOCL
        php
        sei
        ldx     #$30
        stx     P6510
        lda     ($AC),y
        ldx     #$37
        stx     P6510
        plp
        dec     VICBOCL
        jsr     LEDDD
        jsr     LF6ED
        bne     L0F80
        jsr     LF642
        lda     #$00
        sec
        bcs     L0F9C
L0F80:  jsr     LFCDB
        bne     L0F58
L0F85:  lda     TapeBuffer+90
        sta     VICCTR1
        jsr     LEDFE
        bit     SECADR
        bmi     L0F9C
        lda     CURDEVICE
        ora     #$20
        jsr     LED11
        jsr     LF64B
L0F9C:  lda     #$81
        sta     CIA1IRQ
        rts

PromptTxt:
        .byte   "PLEASE ENTER PROGRAM NAME >"



        .byte   $00
PromptNewTxt:
        .byte   "PLEASE ENTER NEW NAME >"


        .byte   $00
StartupTxt:
        .byte   "FILECOPY IS COPYRIGHT TIB.PLC A"



        .byte   "ND NO    PART OF THIS PROGRAM M"



        .byte   "AY BE RESOLD BY   THE USER WITH"



        .byte   "OUT PERMISION OF TIB.PLC   *X  "



        .byte   "     = ABORT TO MAIN MENU"



        .byte   $00
L106C:  .byte   $00
L106D:  .byte   $00
        .byte   "0123456789ABCDEF"

        .byte   $00,$00,$00
