
.include "dd001-jumptable.inc"
.include "dd001-mem.inc"
.include "geosmac.inc"


KEYD			:= $0277	; keyboard buffer
SHFLAG			:= $028D	; 0=unshift, 1=shift
KEYLOG			:= $028F	; vector that sets conversion table, used to intercept key presses, original value $EB48

NDX				:= $C6		; number of characters in keyboard buffer
SFDX			:= $CB		; which key? $40 = none ; F1/F2=04, F3/F4=05, F5/F6=06, F7/F8=03

LEB48			:= $EB48	; original target of KEYLOG vector

.export	FunctionKeys_Install

		.segment "fkeys"

FunctionKeys_Install:
		LoadW	KEYLOG, HandleKey
		rts

HandleKey:
		lda		MSGFLG
		cmp		#$80		; direct mode?
		beq		:+			; yes

		; fall back to original routine
KeyReturn:
		ldx		#$ff		; keycode invalid
		jmp		LEB48

:		; handle keys
		; detect if it's one of ours
		lda		SFDX			;F1/F2=04, F3/F4=05, F5/F6=06, F7/F8=03
		asl						; 6-8-10-12
		ora		SHFLAG			; F1=8, F2=9, F3=10, F4=11, F5=12, F6=13, F7=6, F8=7
		sta		TempStore
		;
		and		#%11110000
		bne		KeyReturn
		lda		TempStore
		and		#%00001111
		tax
		lda		fkeymap,x		; function key number
		beq		KeyReturn
		tax
		dex
		lda		fkeyoffs,x		; offset to text to be injected into keyboard buffer (all texts must be short so that total is under $ff)
		tax
		ldy		#0
:		lda		fkeytxt,x		; copy some bytes into keyboard buffer
		beq		:+
		sta		KEYD,y
		inx
		iny
		bne		:-
:		sty		NDX				; number of injected bytes

		; wait until key released

		ldx      #$5f
		ldy      #$ff
:		dey
		bne      :-
		dex
		bne      :-

		jmp		KeyReturn

fkeymap:
		.byte	0, 0, 0, 0, 0, 0, 7, 8
		.byte	1, 2, 3, 4, 5, 6, 0, 0

fkeyoffs:
		.byte	fkey1txt-fkeytxt
		.byte	fkey2txt-fkeytxt
		.byte	fkey3txt-fkeytxt
		.byte	fkey4txt-fkeytxt
		.byte	fkey5txt-fkeytxt
		.byte	fkey6txt-fkeytxt
		.byte	fkey7txt-fkeytxt
		.byte	fkey8txt-fkeytxt

fkeytxt:
fkey1txt:
		.byte	"@$"
		.byte	13
		.byte	0
fkey2txt:
		.byte	147
		.byte	"LIST:"
		.byte	13
		.byte	0
fkey3txt:
		.byte	"RUN:"
		.byte	13
		.byte	0
fkey4txt:
		.byte	"^"
		.byte	13
		.byte	0
fkey5txt:
		.byte	"/"
		.byte	13
		.byte	0
fkey6txt:
		.byte	"_"	; leftarrow
		.byte	0
fkey7txt:
		.byte	"@#7"
		.byte 	13
		.byte	0
fkey8txt:
		.byte	"@#8"
		.byte	13
		.byte	0
