
.include "dd001-jumptable.inc"
.include "dd001-mem.inc"
.include "geosmac.inc"

L0073           := $0073
L0079           := $0079
L0080           := $0080
L008A           := $008A

LAF08           := $AF08
LE159           := $E159
LE386           := $E386
LF3D5           := $F3D5
LF642           := $F642

.import Wedge_BUFFER
.import Wedge_tmpDEVNUM
.import Wedge_tmp1
.import Wedge_tmp2
.import Wedge_tmp3

.import NewCkout

.export	DOSWedge_Install

		.segment "wedge"

.define	JumpTable	LoadAndRun-1,LoadAndRun-1,LoadAndRun-1,LoadAndRun-1,LoadAndRun-1,Save-1,DiskCommandStatus-1,DiskCommandStatus-1,DiskCommandStatus-1,SetDeviceNumber-1,Uninstall-1

LCC03:	.hibytes JumpTable
LCC0E:	.lobytes JumpTable

LCC19:  .byte   "%"	; 0 load machine code (address from file)
	.byte	"/"	; 1 load BASIC
        .byte   $AD	; 2 ? C=+L = / (?) also load?
        .byte   "^"	; 3 load and RUN
        .byte   $AE	; 4 ? C=+P = ^ (?) also load & run?

        .byte   "_"	; 5 <- save

	.byte	">"	; 6 ?
        .byte   $B1	; 7 ? CTRL+E?
        .byte   "@"	; 8

	; '@' subcommands
	.byte	"#"	; 9	SetDeviceNumber
	.byte	"Q"	; 10	Uninstall
        .byte   $00	; 11	(end, but '$' is also compared explicitly)

StartupTxt:
	.byte   $0D,$0D
        .byte   "      DOS MANAGER V5.1/071382"
        .byte   $0D,$0D
        .byte   "         BY  BOB FAIRBAIRN"
        .byte   $0D,$0D
        .byte   "(C) 1982 COMMODORE BUSINESS MACHINES"
        .byte   $0D,$00

DOSWedge_Install:
	ldx     #2
:	lda     patchCode,x
        sta     $7C,x
        dex
        bpl     :-
	MoveB	CURDEVICE, Wedge_tmpDEVNUM
        ldx     #0
:	lda     StartupTxt,x
        beq     :+
        jsr     KERNAL_CHROUT
        inx
        bne     :-
:	rts

patchCode:
        jmp     RunPatch

RunPatch:
	sta     $A6
        stx     $A7
        tsx			; check the caller routine
        lda     $0101,x
        cmp     #$E6		; was it $A7E7 ? (interpreter loop?)
        beq     :+
        cmp     #$8C		; or $A48D ? (interpreter loop?)
        bne     PatchReturn

:	lda     $0102,x
        cmp     #$A7
        beq     CheckCommand
        cmp     #$A4
        bne     PatchReturn	; if not $A7E7 nor $A48D don't interfere

CheckCommand: 			; is it one of special command characters?
	lda     $A6
        ldx     #8
:	cmp     LCC19,x
        beq     FoundCommand	; yes
        dex
        bpl     :-		; no, fall through - don't interfere

PatchReturn:			; original code and back to the loop
	lda     $A6
        ldx     $A7
        cmp     #':'
        bcs     :+
        jmp     L0080
:	jmp     L008A

FoundCommand:
	stx     $A5
        sta     Wedge_tmp3
        jsr     LCEA3
        ldx     $A5
	LoadW_	FNADR, Wedge_BUFFER
	MoveB	Wedge_tmpDEVNUM, CURDEVICE
LCD3F:  lda     LCC03,x			; get address from table and run through stack
        pha
        lda     LCC0E,x
        pha
        rts

DiskCommandStatus:
	tya				; check '@' subcommands
        beq     DisplayStatus		; '@' - display status
        ldx     #9
:	lda     LCC19,x
        beq     :+
        cmp     Wedge_BUFFER
        beq     LCD64
        inx
        bpl     :-
:	lda     Wedge_BUFFER
        cmp     #'$'
        bne     SendCommand		; none of subcommands, send what follows as user command
	jmp	DisplayDirectory

LCD64:  dec     FNLEN			; found subcommand
	LoadW_	FNADR, Wedge_BUFFER+1	; pass buffer w/o 1st character (subcommand itself)
        jmp     LCD3F			; 'x' has offset to address table, run through stack

SendCommand:
	CmpBI	CURDEVICE, DEVNUM
	bne	@sendiec
	; simulate Ckout, enclose command in quote marks
	ldy	#0
	ldx	#0
	lda	#'"'
	sta	(PtrBasText),y
	iny
:	lda	Wedge_BUFFER,x
	sta	(PtrBasText),y
	iny
	inx
	cpx	FNLEN
	bcc	:-
	lda	#'"'
	sta	(PtrBasText),y
	php
	jsr	NewCkout
	plp
	ldy	#0			; clear the buffer
	tya
	sta	(PtrBasText),y
	jmp	LCE1A			; print new line and return to L0079
	; serial bus code for send command
@sendiec:
	lda     CURDEVICE
	beq	@end
        jsr     KERNAL_LISTEN
        LoadB	SECADR, $60 | 15	; channel 15
        jsr     KERNAL_SECOND
        ldy     #$00
:	lda     Wedge_BUFFER,y
        jsr     KERNAL_CIOUT
        iny
        cpy     FNLEN
        bcc     :-
        jsr     KERNAL_UNLISTEN
@end:   jmp     LCDAF

DisplayStatus:
	CmpBI	CURDEVICE, DEVNUM	; DD-001?
	bne	:+
	lda	ErrorCode
	jsr	ShowError		; status from there
	lda	#$0D
	jsr	KERNAL_CHROUT
	jmp	LCDAF

:	lda     CURDEVICE
	beq	LCDAF
        jsr     KERNAL_TALK
        LoadB	SECADR, $60 | 15	; channel 15
        jsr     KERNAL_TKSA
:	jsr     KERNAL_ACPTR
        cmp     #$0D			; newline
        beq     :+
        jsr     KERNAL_CHROUT
        jmp     :-

:	jsr     KERNAL_CHROUT
        jsr     KERNAL_UNTALK
LCDAF:  jmp     L0079

DisplayDirectory:  			; '@$'
	CmpBI	CURDEVICE, DEVNUM	; DD-001?
	bne 	:+
	jsr	DisplayDir		; yes, use that routine instead
	jmp	LCE1A			; proper exit

:	LoadB	SECADR, $60		; channel 0
        jsr     LF3D5
        lda     CURDEVICE
	beq	LCE17
        jsr     KERNAL_TALK
        lda     SECADR
        jsr     KERNAL_TKSA		; talk on channel 0
	LoadB	STATUSIO, 0
        ldy     #3
LCDC9:  sty     FNLEN
        jsr     KERNAL_ACPTR
        sta     LOADADDR		; line number (file length)
        jsr     KERNAL_ACPTR
        sta     LOADADDR+1		; line number (file length)
        ldy     STATUSIO
        bne     LCE17
        ldy     FNLEN
        dey
        bne     LCDC9
        ldx     LOADADDR
        lda     LOADADDR+1
        jsr     PrintIntegerXA		; print number from A/X (BASIC)
        lda     #' '
        jsr     KERNAL_CHROUT
LCDEA:  jsr     KERNAL_ACPTR
        ldx     STATUSIO
        bne     LCE17
        cmp     #$00
        beq     LCE0D
        jsr     KERNAL_CHROUT
        jsr     KERNAL_STOP		; run/stop?
        beq     LCE17			; yes -> end
        jsr     KERNAL_GETIN
        beq     LCDEA
        cmp     #' '
        bne     LCDEA
:	jsr     KERNAL_GETIN
        beq     :-
        bne     LCDEA
LCE0D:  lda     #$0D			; new line
        jsr     KERNAL_CHROUT
        ldy     #2
        jmp     LCDC9

LCE17:  jsr     LF642
LCE1A:  lda     #$0D			; new line
        jsr     KERNAL_CHROUT
        jmp     L0079

; handle / and % data load
; no need to check for DD-001 DEVNUM, it goes through vector
LoadAndRun:
	ldx     $2B
        ldy     $2C
        lda     Wedge_tmp3
        cmp     #'%'			; if '%' load into load adress from file
        bne     :+
        lda     #1			; secondary address to take load address from file
        .byte   $2C
:	lda     #0			; secondary address to load into BASIC
        sta     SECADR
        lda     #0			; LOAD, not VERIFY
        jsr     KERNAL_LOAD
        bcs     @end			; error?
        lda     Wedge_tmp3
        cmp     #'%'			; was it machine code load?
        beq     @end
	MoveW	$AE, $2D		; no - adjust BASIC
        jsr     $A659			; reset execute pointer and do CLR
        jsr     $A533			; re-link
        lda     Wedge_tmp3
        cmp     #$AD			; normal load (the other character)?
        beq     @end
        cmp     #'/'			; normal load?
        bne     @run
@end:	jmp     LE386			; BASIC warmstart, print error message, return to loop

@run:	lda     #0
        jsr     KERNAL_SETMSG		; disable all KERNAL messages
        jsr     $A68E			; set current character pointer to start of basic - 1
        jmp     $A7AE			; run

; uninstall wedge
Uninstall:				; @Q
	ldx     #2
:	lda     $E3AB,x
        sta     $7C,x
        dex
        bpl     :-
        jmp     LE386

; no need to check for DD-001 DEVNUM, it goes through vector
Save:
	jsr     LE159			; Kernal perform SAVE (jumps through vector through KERNAL_SAVE)
        jmp     DisplayStatus

; set device number
SetDeviceNumber:			; @#<number>
	ldy     FNLEN
        lda     Wedge_BUFFER,y
        and     #$0F
        sta     Wedge_tmpDEVNUM
        dey
        beq     :++			; one digit
        lda     Wedge_BUFFER,y
        and     #$0F
        tay				; tens?
        beq     :++			; no
        lda     Wedge_tmpDEVNUM
        clc
:	adc     #10
        dey
        bne     :-
        sta     Wedge_tmpDEVNUM
:	jmp     L0079

; read input string into Wedge_BUFFER and ... do something?
LCEA3:  ldy     #0
        jsr     L0073
        tax
        bne     LCEAE
        jmp     LCF3A

LCEAE:  LoadB	$7C, $60		; RTS opcode
	PushW	$7A
        txa
LCEB9:  cmp     #'"'
        beq     LCEDB
        jsr     L0073
        bne     LCEB9
	PopW	$7A
        jsr     L0079
        ldx     #0
        cmp     #'"'
        beq     LCEDF
        ldx     #2
        cpx     $7B
        bne     LCF33
        ldx     #0
        beq     LCEE4

LCEDB:  pla
        pla
        ldx     #0
LCEDF:  jsr     L0073
        beq     LCF3A
LCEE4:  cmp     #'"'
        beq     LCF3A
        cmp     #'='
        beq     LCEF0
        cmp     #':'
        bne     LCEF2
LCEF0:  ldx     #$FF
LCEF2:  cmp     #'['
        beq     LCF00
LCEF6:  sta     Wedge_BUFFER,y
        sta     Wedge_tmp2
        inx
        iny
        bpl     LCEDF
LCF00:  jsr     L0073
        beq     LCF33
        sta     Wedge_tmp1
        jsr     L0073
        beq     LCF33
        cmp     #']'
        bne     LCF33
        cpx     #$10
        bcs     LCF33
        lda     Wedge_tmp2
        cmp     #'*'
        bne     LCF21
        dey
        dex
        lda     #'?'
        .byte   $2C
LCF21:  lda     #' '
LCF23:  cpx     #$0F
        bcs     LCF2E
        sta     Wedge_BUFFER,y
        iny
        inx
        bpl     LCF23
LCF2E:  lda     Wedge_tmp1
        bne     LCEF6
LCF33:  ldx     #$4C		; jmp opcode
        stx     $7C
        jmp     LAF08

LCF3A:  sty     FNLEN
        ldx     #$4C		; jmp opcode
        stx     $7C
        jsr     L0079
        beq     :++
:	jsr     L0073
        bne     :-
:	rts

