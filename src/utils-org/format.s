; da65 V2.19 - Git dcdf7ade0
; Created:    2023-05-31 11:41:23
; Input file: ../../firmware/utils/FORMAT.EXE
; Page:       1


        .setcpu "6502"

P6510           := $0001                        ; DR onboard I/O port of 6510
MSGFLG          := $009D                        ; Kernal message control (bit 7=show control, bit 6=show error); $80=direct mode, $00=program mode
FNLEN           := $00B7                        ; Length of current filename, set by SETNAM
FNADR           := $00BB                        ; Pointer to current filename, set by SETNAM
NDX             := $00C6                        ; Number of characters in keyboard queue
COLOR           := $0286                        ; foreground text color
StartofDir      := $0334                        ; page number where directory buffer starts (need 2 pages for a sector)
EndofDir        := $0335                        ; page number where directory buffer ends(?)
FileNameBuf     := $0961                        ; Buffer to store file name
CART_COLDSTART  := $8000                        ; cartridge cold start vector
FormatDisk      := $89DB                        ; direct call to FormatDisk instead of jump table _FormatDisk $800F
VICCTR1         := $D011                        ; control register 1
VICLINE         := $D012                        ; raster line
VICBOCL         := $D020                        ; border color
VICBAC0         := $D021                        ; backgrouund color 0
KERNAL_SETNAM   := $FFBD                        ; Set file name
KERNAL_CHRIN    := $FFCF                        ; Get a character from the input channel
KERNAL_CHROUT   := $FFD2                        ; Output a character
KERNAL_GETIN    := $FFE4                        ; Get a character
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
        sta     P6510
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
