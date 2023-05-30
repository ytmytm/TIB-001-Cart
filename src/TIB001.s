;
;	Disassembly of the ROM of the TIB-001 FDC cartridge
;

; - a lot of loading DirPointer with (0, StartofDir), move that to a subroutine
; - check status register consistently BIT+BPL instead of LDA+AND#$80+BNE

; My notes/ideas regarding this disassembly
; - only a 3,5" 720 KB DD FDD can be used, not a 5.25" 360 KB one
; - only ONE drive can be used
; - a directory sector is stored in the RAM under the $Dxxx area
; - probably a bug, look for "; BUG"
; - Some RS232 variables are used, meaning: we cannot use RS 232 anymore
; - bad: I/O port of 6510 is manipulated but not restored with original value
; - bad: video control register is manipulated using and not restored
; - look for ??? for some questions I had
; - inconsistent use of Carry for reporting an error
; - the disk has a FAT table but so far I don't think it has the 12 bits FAT
;   structure as used by IBM (compatible)s. 
; - in general: the programming could have been done more efficient


; Remarks:
; - The data sheet speaks of "cylinders", nowadays the word "track" is favored.

P6510		= $01	; DR onboard I/O port of 6510
PageCounter	= $02
PtrBasText	= $7A	; pointer to momentary byte in BASIC line
StatusIO	= $90	; Status of KERNAL after action
FlgLoadVerify	= $93	; 0 = LOAD, 1 = VERIFY
MSGFLG		= $9D	; flag: $80 = direct mode, 0 = program mode
EndAddrBuf	= $AE	; vector, word - end of cassette / end of program
LengthFileName	= $B7	; length of filename
SecondAddress	= $B9	; actual secondary address
DeviceNumber	= $BA	; actual device number
AddrFileName	= $BB	; pointer to string with filename

; The used RS232 variabels:
NumOfSectors	= $F7	; number of sectors to read or write
SectorL		= $F8	; --- number of the sector that is wanted
SectorH		= $F9	; -/
TempStore	= $FA

DirPointer	= $FB	; vector, word
Z_FD		= $FD
J_00FE		= $FE	; vector, unused
Z_FF		= $FF
StackPage	= $0100
NmiVector	= $0318	; pointer to NMI-interrupt ($FE47)
ICKOUT		= $0320	; pointer to KERNAL CHKOUT routine
ILOAD		= $0330	; pointer to KERNAL LOAD routine
ISAVE		= $0332	; pointer to KERNAL SAVE routine

; $0334-$033B = original free area = 8 bytes
StartofDir	= $0334
EndofDir	= $0335
NewICKOUT	= $0336
NewNMI		= $0338


;Fdc		= $034	; 

TapeBuffer	= $033C	; cassette buffer
FdcST0		= $033C ; Status Regiser 0
FdcST1		= $033D ; Status Regiser 1
FdcST2		= $033E ; Status Regiser 2
FdcC		= $033F ; Cylinder
FdcH		= $0340 ; Head
FdcR		= $0341 ; Record = sector
FdcN		= $0342 ; Number of data bytes written into a sector
FdcST3		= $0343 ; Status Regiser 3
FdcPCN		= $0344	; present cylinder = track
FdcCommand	= $0345 ; 
FdcHSEL		= $0346	; head, shifted twice, needed for FDC commands
FdcTrack	= $0347	; 
FdcHead		= $0348	; 
FdcSector	= $0349	; 
FdcNumber	= $034A	; bytes/sector during format, 2 = 512 b/s
FdcEOT		= $034B	; end of track

FdcTrack2	= $034E	; = FdcTrack and $FE  ???

TempStackPtr	= $0350	; temporary storage for the stack pointer

FdcFormatData	= $0352	; block of data used by the format command

NumDirSectors	= $0364	; number of directory sectors
				; also used deteming number of free bytes
Counter		= $0366

DirSector	= $0369	; momentary directory sector
FdcFileName	= $036C	; temp storage for file name

ErrorCode	= $0351	; $0B = file not found
			; $10 = first part of name greater than 8 chars
			; $11 = no file name

NewILOAD	= $03FC
NewISAVE	= $03FE
VICSCN		= $0400	; screenmemory


BasicCold	= $A000
BasicNMI	= $A002
VICCTR1		= $D011	; controlregister 1
VICLINE		= $D012	; line to generate IRQ

ColourRAM	= $D800	; color RAM area for screen

CIA1DRB		= $DC01	; data register port B (scan for RUN/STOP)

CIA2BASE	= $DD00
CIA2TI1L	= CIA2BASE+4	; low byte timer 1
CIA2TI1H	= CIA2BASE+5	; high byte timer 1
CIA2TI2L	= CIA2BASE+6	; low byte timer 2
CIA2TI2H	= CIA2BASE+7	; high byte timer 2
CIA2IRQ		= CIA2BASE+$0D	; IRQ-register
CIA2CRA		= CIA2BASE+$0E	; controlregister 1
CIA2CRB		= CIA2BASE+$0F	; controlregister 2


; Registers for the GM82C765B
;  Note: No other address lines than A0 are used so in fact any address in its 
;        page could be used.
;        The GM82C765B is used in programmed I/O mode, thus no DMA is used.
StatusRegister	= $DE80	; bit, if bit = (H) then ...
				;  0  =  FDD0 is busy
				;  1  =  FDD1 is busy
				;  2  =  FDD2 is busy
				;  3  =  FDD3 is busy
				;  4  =  read/write command in progress
				;  5  =  execution mode (non-DMA mode)
				;  6  =  data direcion, 765 => CPU
				;  7  =  data register = ready

.feature c_comments
/*
Status Register 0

 b0,1   US  Unit Select (driveno during interrupt)
 b2     HD  Head Address (head during interrupt)
 b3     NR  Not Ready (drive not ready or non-existing 2nd head selected)
 b4     EC  Equipment Check (drive failure or recalibrate failed (retry))
 b5     SE  Seek End (Set if seek-command completed)
 b6,7   IC  Interrupt Code (0=OK, 1=aborted:readfail/OK if EN, 2=unknown cmd
            or senseint with no int occured, 3=aborted:disc removed etc.)

Status Register 1

 b0     MA  Missing Address Mark (Sector_ID or DAM not found)
 b1     NW  Not Writeable (tried to write/format disc with wprot_tab=on)
 b2     ND  No Data (Sector_ID not found, CRC fail in ID_field)
 b3,6   0   Not used
 b4     OR  Over Run (CPU too slow in execution-phase (ca. 26us/Byte))
 b5     DE  Data Error (CRC-fail in ID- or Data-Field)
 b7     EN  End of Track (set past most read/write commands) (see IC)

Status Register 2

 b0     MD  Missing Address Mark in Data Field (DAM not found)
 b1     BC  Bad Cylinder (read/programmed track-ID different and read-ID = FF)
 b2     SN  Scan Not Satisfied (no fitting sector found)
 b3     SH  Scan Equal Hit (equal)
 b4     WC  Wrong Cylinder (read/programmed track-ID different) (see b1)
 b5     DD  Data Error in Data Field (CRC-fail in data-field)
 b6     CM  Control Mark (read/scan command found sector with deleted DAM)
 b7     0   Not Used

Status Register 3

 b0,1   US  Unit Select (pin 28,29 of FDC)
 b2     HD  Head Address (pin 27 of FDC)
 b3     TS  Two Side (0=yes, 1=no (!))
 b4     T0  Track 0 (on track 0 we are)
 b5     RY  Ready (drive ready signal)
 b6     WP  Write Protected (write protected)
 b7     FT  Fault (if supported: 1=Drive failure)
*/

DataRegister	= $DE81
ResetFDC	= $DF80


InitScreenKeyb	= $E518
IncrClock22	= $F6BC
SetVectorsIO2	= $FD15
TestRAM2	= $FD50
InitSidCIAIrq2	= $FDA3
InitialiseVIC2	= $FF5B
OutByteChan	= $FFD2
ScanStopKey	= $FFE1

D_FFFA		= $FFFA
D_FFFB		= $FFFB

; GEOS macros for readability and shorter code
.include "geosmac.inc"
; FAT12 constants
.include "fat12.inc"

; linker will update that
.import __STACK0101_LAST__

			.segment "rom8000"

			.assert *=$8000, error, "cartridge ROM must start at $8000"

			.word CartInit				;				[8087]
			.word CartNMI				;				[8DE7]
 
			.assert *=$8004, error, "cartridge signature CBM80 must be at $8004"
			.byte $C3, $C2, $CD, $38, $30		; CBM80, cartridge signature

; ???  WHERE IS THIS JUMP TABLE USED  ???
; 1st possebility: the idea was there to use it but it never happened
; 2nd possebility: it is used by external programs

; 8009
			.assert *=$8009, error, "jump table must be at $8009"
_NewLoad:		jmp	NewLoad			; [8009] -> [86BC]
_NewSave:		jmp	NewSave			; [800C] -> [838A]
_FormatDisk:		jmp	FormatDisk		; [800F] -> [89DB]
_DisplayDir:		jmp	DisplayDir		; [8012] -> [8E67]
_ReadSector:		jmp	ReadSector		; [8015] -> [8C78]
_SetWatchdog:		jmp	SetWatchdog		; [8018] -> [8D90]
_ReadSectors:		jmp	ReadSectors		; [801B] -> [885E]
_WriteSector:		jmp	WriteSector		; [801E] -> [8BEE]
_ReadStatus:		jmp	ReadStatus		; [8021] -> [8962]
_Scratch:		jmp	Scratch			; [8024] -> [8355]
_Rename:		jmp	Rename			; [8027] -> [81C0]
_FormatTrack:		jmp	FormatTrack		; [802A] -> [8B93]
_InitStackProg:		jmp	InitStackProg		; [802D] -> [8D5A]
_SetupSector:		jmp	SetupSector		; [8030] -> [8899]
_Specify:		jmp	Specify			; [8033] -> [891A]
_Recalibrate:		jmp	Recalibrate		; [8036] -> [88F7]
_SetSoace:		jmp	SetSoace		; [8039] -> [834B]
_GetNextCluster:	jmp	GetNextCluster		; [803C] -> [87A4]
_Enfile:		jmp	Enfile			; [803F] -> [8684]
_MarkFAT:		jmp	MarkFAT			; [8042] -> [8534]
_FindFAT:		jmp	FindFAT			; [8045] -> [85A8]
_FindNextFAT:		jmp	FindNextFAT		; [8048] -> [85B2]
_WriteFATs:		jmp	WriteFATs		; [804B] -> [860C]
_ClearFATs:		jmp	ClearFATs		; [804E] -> [8650]
_CalcFirst:		jmp	CalcFirst		; [8051] -> [883A]
_GetFATs:		jmp	GetFATs			; [8054] -> [8813]
_SeekTrack:		jmp	SeekTrack		; [8057] -> [898A]
_FindFile:		jmp	FindFile		; [805A] -> [8FEA]
_WriteDirectory:	jmp	WriteDirectory		; [805D] -> [850F]
_ReadDirectory:		jmp	ReadDirectory		; [8060] -> [8E0F]
_J_8472:		jmp	J_8472			; [8063] -> [8472]
_SaveRloc:		jmp	SaveRloc		; [8066] -> [9127]
_ShowError:		jmp	ShowError		; [8069] -> [926C]
_ShowBytesFree:		jmp	ShowBytesFree		; [806C] -> [916A]
_BN2DEC:		jmp	BN2DEC			; [806F] -> [920E]
_StripSP:		jmp	StripSP			; [8072] -> [90A7]
_Search:		jmp	Search			; [8075] -> [9011]
_FindBlank:		jmp	FindBlank		; [8078] -> [8F4F]
_PadOut:		jmp	PadOut			; [807B] -> [90CE]
_StopWatchdog:		jmp	StopWatchdog		; [807E] -> [8DBD]
_RdDataRamDxxx:		jmp	RdDataRamDxxx		; [8081] -> [01A0]
__Spare:		jmp	$FFFF			; [8084] -> [FFFF]

; error and message codes, constants for ErrorCode, same as Msg00-11
; messages without comment mark are not used internally in ROM
ERR_OK 				= 0 ;
ERR_DISK_WRITE_PROTECT 		= 1 ;
ERR_DISK_UNUSABLE 		= 2
ERR_DISK_NOT_FORMATTED 		= 3
ERR_FILE_IS_CORRUPT 		= 4
ERR_FORMATING_DISK 		= 5
ERR_RENAMING_FILE 		= 6
ERR_SCRATCHING_FILE 		= 7
ERR_DURING_WRITE 		= 8
ERR_DURING_READ 		= 9
ERR_DISK_MAY_BE_DAMAGED 	= 10 ;
ERR_FILE_NOT_FOUND 		= 11 ;
ERR_NO_FILE_EXTENSION_SPECIFIED	= 12
ERR_FILE_TOO_LARGE 		= 13 ;
ERR_NO_MORE_DIRECTORY_SPACE 	= 14 ;
ERR_DISK_UNRELIABLE 		= 15 ;
ERR_NAME_TOO_LONG 		= 16 ; name longer than 8 characters
ERR_NO_NAME_SPECIFIED 		= 17 ;


; Here starts the initialisation of the cartridge
CartInit:				;				[8087]
	ldx	#$FF
	txs				; set the stack pointer

	sei				; XXX code should start with sei
	cld

	jsr	InitC64			;				[80F2]

@tryagain:
	jsr	LoadBootExe		; loading went OK?		[9294]
	bcc	@bootLoadDone		; yes, ->			[80AE]
@checkerr:
	CmpBI	ErrorCode, ERR_FILE_NOT_FOUND ; file not found?
	beq	@done			; yes, ->			[80A8]

	LoadB	VICCTR1, $1B		; screen on
	jsr	TryAgain		; show message			[8124]
	beq	@done			; RUN/STOP pressed?		[80A8]
	jmp	@tryagain		;				[808F]

; File "BOOT.EXE" not found, return control to BASIC
@done:	jsr	InitC64			;				[80F2]
	jmp	(BasicCold)		;				[A000]

; Error found
@bootLoadDone:
	lda	ErrorCode		; error found?			[0351]
	bne	@checkerr		;				[8094]
; no error, run BOOT.EXE from its load address ($1000)
	jmp	(EndAddrBuf)		;				[00AE]


;**  Initialize the C64 - part 2
;    Note: not used anywhere else AFAIK, so why not one routine?
InitC64_2:				;				[80B6]
	LoadB	StartofDir, $D0		; ??? page number?
	LoadB	EndofDir, $D2		; ??? page number?

; Replace some routines by new ones
NewRoutines:				;				[80C0]
	lda	ResetFDC		; reset the FDC			[DF80]

; Use the NMI routine of the cartridge as first routine for the C64
	lda	#<CartNMI
	sta	NmiVector		;				[0318]
	sta	D_FFFA			;				[FFFA]

	lda	#>CartNMI
	sta	NmiVector+1		;				[0319]
	sta	D_FFFB			;				[FFFB]

; Set the new LOAD, SAVE and CKOUT routines for the C64

	LoadW_	ILOAD, NewLoad
	LoadW_	ISAVE, NewSave
	LoadW_	ICKOUT, NewCkout

	rts


;**  Initialize the C64 - part 1
InitC64:				;				[80F2]
	jsr	InitSidCIAIrq2		;				[FDA3]
	jsr	TestRAM2		;				[FD50]
	jsr	SetVectorsIO2		;				[FD15]
	jsr	InitialiseVIC2		;				[FF5B]

; Copy the original vectors of the LOAD and SAVE routine to another place
	ldx	#3
:	lda	ILOAD,X			;				[0330]
	sta	NewILOAD,X		;				[03FC]
	dex
	bpl	:-

; Copy the ICKOUT vector to another place
	MoveW_	ICKOUT, NewICKOUT	; [0320,1] -> [0336,7]

; Copy the NMI vector to another place
	MoveW_	NmiVector, NewNMI	; [0318,9] -> [0338,9]

	jmp	InitC64_2		; part 2			[80B6]


;**  File "BOOT.EXE" has been found
TryAgain:				;				[8124]

; Clear the screen
	ldy	#0
:	lda	#$20
	sta	VICSCN,Y		;				[0400]
	sta	VICSCN+$0100,Y		;				[0500]
	sta	VICSCN+$0200,Y		;				[0600]
	sta	VICSCN+$0300,Y		;				[0700]
	lda	#1			; set color to WHITE but it should be in the next loop
	sta	ColourRAM,Y		;				[D800]
	dey
	bne	:-

; Display two lines of text
	ldy	#0			; XXX Y is zero here already
:	lda	Text1,Y			; '@' =	zero?			[8172]
	beq	:+			; yes, -> stop displaying	[814F]
	sta	VICSCN+40,Y		;				[0428]
	lda	Text2,Y			;				[8199]
	sta	VICSCN+80,Y		;				[0450]
	iny
	bne	:-
:

	LoadB	VICCTR1, $1B		; screen on

	; long delay that can be interrupted with RUN/STOP
	ldx	#$64
	lda	#$FF
:	cmp	VICLINE			;				[D012]
	bne	:-
:	cmp	VICLINE			;				[D012]
	beq	:-

	CmpBI	CIA1DRB, $7F		; RUN/STOP key pressed?
	beq	@end			; yes, -> exit Z=1		[8171]

	dex				; wait longer?
	bne	:--			; yes, ->			[8158]

	LoadB	VICCTR1, $0B		; screen off, exit Z=0
@end:	rts

 
Text1:					;				[8172]
;.tp 'PLEASE LEAVE UNTIL C64 + DRIVE SYNC UP@'
.byte $10, $0C, $05, $01, $13, $05, $20, $0C, $05, $01, $16, $05, $20, $15, $0E, $14, $09, $0C, $20, $03, $36, $34, $20, $2B, $20, $04, $12, $09, $16, $05, $20, $13, $19, $0E, $03, $20, $15, $10, $00
Text2:					;				[8199]
;.tp ' OR PRESS RUN/STOP IF NO DISC PRESENT @'
.byte $20, $0F, $12, $20, $10, $12, $05, $13, $13, $20, $12, $15, $0E, $2F, $13, $14, $0F, $10, $20, $09, $06, $20, $0E, $0F, $20, $04, $09, $13, $03, $20, $10, $12, $05, $13, $05, $0E, $14, $20, $00

;**  Rename a file 
Rename:					;				[81C0]
	jsr	InitStackProg		;				[8D5A]
	jsr	WaitRasterLine		;				[8851]

	jsr	FindFile		; file found?			[8FEA]
	bcs	:+			; yes, -> 
	rts

:	ldy	LengthFileName		;				[B7]
; ??? what is going on here ???
	lda	(AddrFileName),Y	;				[BB]
	lda	#0
	lda	#0			; ??? again?
	clc

	cpy	TapeBuffer+89		;				[0395]
	bne	:+			;				[81DF]

	lda	#ERR_FILE_NOT_FOUND
	jmp	ShowError		;				[926C]

:	ldx	#0
	iny

:	lda	(AddrFileName),Y	;				[BB]
	iny
	sta	FdcFileName,X		;				[036C]
	sta	TapeBuffer+78,X		;				[038A]
	inx
	cpx	#$0B
	bne	:-

	ldy	#0
	lda	#'.'
:	cmp	FdcFileName,Y		;				[036C]
	beq	@found_dot
	iny
	cpy	#$08
	bne	:-			;				[81F4]

	ldy	#0
:	lda	FdcFileName,Y		;				[036C]
	iny
	cmp	#$22
	bne	:-			;				[8200]

	cpy	#$0A
	bcs	@err_longname
	dey

:	lda	#$20
	sta	FdcFileName,Y		;				[036C]
	iny
	cpy	#$0B
	bne	:-			; XXX should jump to the next instruction, A is $20
	jmp	@cont			; XXX beq will work here

@err_longname:
	LoadB	ErrorCode, ERR_NAME_TOO_LONG
	rts

@found_dot:
	tya
	pha

	ldx	#$08
:	iny
	lda	TapeBuffer+78,Y		;				[038A]
	sta	FdcFileName,X		;				[036C]
	inx
	cpx	#$0B
	bne	:-

	pla
	tay

	lda	#$20
:	sta	FdcFileName,Y		;				[036C]
	iny
	cpy	#$08
	bne	:-			;				[8234]

@cont:	jsr	WaitRasterLine		;				[8851]

	PushB	DirPointer
	PushB	DirPointer+1
	PushB	DirSector

	jsr	Search			;				[9011]

	PopB	DirSector
	bcs	@err

	jsr	WaitRasterLine		;				[8851]

	LoadB	DirPointer, 0
	MoveB	StartofDir, DirPointer+1

	LoadB	NumOfSectors, 1
	MoveB	DirSector, SectorL

	jsr	SetWatchdog		;				[8D90]
	jsr	SetupSector		;				[8899]
	jsr	SeekTrack		;				[898A]
	jsr	ReadSectors		;				[885E]
	jsr	SetWatchdog		;				[8D90]

	PopB	DirPointer+1
	PopB	DirPointer

	ldy	#0
:	lda	FdcFileName,Y		;				[036C]
	jsr	WrDataRamDxxx		;				[01AF]
	iny
	cpy	#$0B
	bne	:-

	jsr	WaitRasterLine		;				[8851]
	jsr	WriteDirectory		;				[850F]

	clc
	rts

@err:	sec				; XXX C=1 already here
	pla
	pla
	rts


;**  New routine for opening a channel for output
; XXX seems unused/unfinished (unless used only from tools somehow)
NewCkout:				;				[8295]
	pha

	CmpBI	DeviceNumber, 9		; our DD drive? (XXX)
	beq	__NewCkout		; yes, ->			[82A1]

	pla
	jmp	(TapeBuffer+188)	; = ($03F8)			[03F8]
; ??? where is this vector filled ???
; I would expect (NewICKOUT) = ($0336)

; Not used
S_82A0:
	rti
 
__NewCkout:
	sei
	tya
	pha

	txa
	pha

	ldy	#0
	lda	(PtrBasText),Y		;				[7A]
	cmp	#'"'			; quote found?
	bne	@end
	iny

; Save current Y
	tya
	pha

; Check if the string between the quotes is not too long
:	lda	(PtrBasText),Y		;				[7A]
	iny
	cpy	#$21			; 33 or more characters?
	bcs	@toolong		; yes, -> exit			[82D8]
	cmp	#'"'			; quote found?
	bne	:-

; Restore original Y
	pla
	tay

	lda	(PtrBasText),Y		;				[7A]
; Handle as SCRATCH
	cmp	#'S'			; 'S' ?
	bne	:+
	lda	PtrBasText		;				[7A]
	addv	3
	sta	AddrFileName		;				[BB]
	MoveB	PtrBasText+1, AddrFileName+1
	jsr	GetlengthFName		;				[8336]
	jsr	Scratch			;				[8355]
	jmp	@end

@toolong:
	pla
	sec
	jmp	@end

; Handle as RENAME
:	cmp	#'R'			; 'R' ?
	bne	:+

	lda	PtrBasText		;				[7A]
	addv	3
	sta	AddrFileName		;				[BB]
	MoveB	PtrBasText+1, AddrFileName+1
	jsr	RenameFilePrep
	jsr	Rename			;				[81C0]
	jmp	@end

; Handle as NEW = format disk
:	cmp	#'N'			; 'N' ?
	bne	@end

	lda	PtrBasText		;				[7A]
	addv	3
	sta	AddrFileName		;				[BB]
	MoveB	PtrBasText+1, AddrFileName+1
	jsr	FormatDisk		;				[89DB]

@end:	php
	lda	ErrorCode		;				[0351]
	jsr	ShowError		;				[926C]
	LoadB	VICCTR1, $1B		; screen on
	plp

	pla
	tax
	pla
	tay
	pla
	rts

RenameFilePrep:
; what does it do?
	ldy	#0
:	lda	(AddrFileName),Y	;				[BB]
	cmp	#'='
	beq	:+			;				[8325]
	iny
	bne	:-
:	tya
	sty	LengthFileName		; XXX destroyed immediately by GetlengthFName
	tya
	pha
	jsr	GetlengthFName		;				[8336]
	MoveB	LengthFileName, TapeBuffer+89
	PopB	LengthFileName
	rts


;**  Get the length of the file name between the quotes
GetlengthFName:				;				[8336]
	ldy	#1
; Look for a quote
:	lda	(PtrBasText),Y		;				[7A]
	cmp	#'"'			; quote found?
	beq	:+			; yes, ->			[8341]
	iny
	bne	:-

:	tya
	iny
	sty	LengthFileName		;				[B7]
	clc
	adc	PtrBasText		;				[7A]
	sta	PtrBasText		;				[7A]
	rts

; 'Soace'?
SetSoace:				;				[834B]
	sta	StartofDir		;				[0334]
	addv	2
	sta	EndofDir		;				[0335]
	rts


;**  Scratch a file
Scratch:				;				[8355]
	jsr	InitStackProg		;				[8D5A]
	jsr	FindFile		; file found?			[8FEA]
	bcs	@found			; yes

	LoadB	ErrorCode, ERR_FILE_NOT_FOUND
	rts

@found:	ldy	#0
	lda	#$E5			; means: file has been deleted
	jsr	WrDataRamDxxx		;				[01AF]
; Note: MS-DOS saves the first character

	PushB	DirPointer
	PushB	DirPointer+1

	jsr	WaitRasterLine		;				[8851]
	jsr	WriteDirectory		;				[850F]
	jsr	GetFATs			;				[8813]
	jsr	WaitRasterLine		;				[8851]

	PopB	DirPointer+1
	PopB	DirPointer

	jsr	ClearFATs		;				[8650]
	jsr	WriteFATs		;				[860C]

	clc
	rts


;**  Routine that replaces original SAVE routine of C64
NewSave:				;				[838A]
	sei
	stx	TapeBuffer+43		;				[0367]

	CmpBI	DeviceNumber, 9		; XXX device
	beq	__NewSave

	jmp	(NewISAVE)		;				[03FE]

__NewSave:
	lda	EndAddrBuf		;				[AE]
	sec
	sbc	$00,X			; minus start address LB
	sta	TapeBuffer+37		;				[0361]

	lda	EndAddrBuf+1		;				[AF]
	sbc	$01,X			; minus start address HB
	sta	TapeBuffer+36		;				[0360]
	sta	NumDirSectors		;				[0364]
; TapeBuffer+37 / TapeBuffer+36 now contains the length of the file

; End address > start address?
	bcs	@cont			; yes, -> OK			[83B6]

; File too large
	lda	#ERR_FILE_TOO_LARGE
	jsr	ShowError		;				[926C]
	LoadB	VICCTR1, $1b		; screen on
	rts

; continue with save file
@cont:	lsr	NumDirSectors		;				[0364]
	lsr	NumDirSectors		;				[0364]
	inc	NumDirSectors		;				[0364]

	MoveB	NumDirSectors, TapeBuffer+44

	jsr	InitStackProg		;				[8D5A]

	lda	FdcST3			;				[0343]
	and	#$40			; XXX optimize bit+bcs
	beq	@cont2
	LoadB	ErrorCode, ERR_DISK_WRITE_PROTECT
	jmp	ShowError		;				[926C]

@cont2:	jsr	GetFATs			;				[8813]
	jsr	FindFile		;				[8FEA]
	bcs	@overwrite

	CmpBI	ErrorCode, ERR_FILE_NOT_FOUND
	beq	@newfile

	lda	ErrorCode		;				[0351]
	jsr	ShowError		;				[926C]

	LoadB	VICCTR1, $1b		; screen on (jump here every time and save few bytes) XXX
	rts

@overwrite:
	jsr	StopWatchdog		;				[8DBD]
	PushB	DirPointer
	PushB	DirPointer+1
	jsr	ClearFATs		;				[8650]
	PopB	DirPointer+1
	PopB	DirPointer
	jmp	@dosave			;				[8418]

@newfile:
	jsr	FindBlank		;				[8F4F]

	lda	ErrorCode		; error found?			[0351]
	beq	@dosave			;				[8418]

	jsr	ShowError		;				[926C]
	LoadB	VICCTR1, $1B		; screen on
	rts

@dosave:
	jsr	StopWatchdog		;				[8DBD]

	PushB	DirPointer+1
	PushB	DirPointer

	ldx	#0
	jsr	FindFAT			;				[85A8]

	PopB	DirPointer
	PopB	DirPointer+1

	ldy	#$16
	lda	#$79
	jsr	WrDataRamDxxx		;				[01AF]

	iny
	lda	#$0C
	jsr	WrDataRamDxxx		;				[01AF]

	iny
	lda	#5
	jsr	WrDataRamDxxx		;				[01AF]

	iny
	lda	#$17
	jsr	WrDataRamDxxx		;				[01AF]

	iny
	lda	TapeBuffer+30		;				[035A]
	jsr	WrDataRamDxxx		;				[01AF]

	iny
	lda	TapeBuffer+31		;				[035B]
	jsr	WrDataRamDxxx		;				[01AF]

	iny
	lda	TapeBuffer+37		;				[0361]
	jsr	WrDataRamDxxx		;				[01AF]

	iny

	lda	TapeBuffer+36		;				[0360]
	jsr	WrDataRamDxxx		;				[01AF]

	iny

	ldx	TapeBuffer+43		;				[0367]
	lda	$01,X			;				[01]

	ldy	#$10
	jsr	WrDataRamDxxx		;				[01AF]

	iny
	lda	$00,X			;				[00]
	jsr	WrDataRamDxxx		;				[01AF]

; jumptable has this function, why? what is it?
J_8472:					;				[8472]
	LoadB	TapeBuffer+41, 1
	MoveB	TapeBuffer+44, NumDirSectors

J_847D:					;				[847D]
	jsr	SeekTrack		;				[898A]

	LoadB	ErrorCode, ERR_OK

	jsr	WaitRasterLine		;				[8851]

	ldx	TapeBuffer+43		;				[0367]
	lda	$00,X			;				[00]
	sta	DirPointer		;				[FB]

	lda	$01,X			;				[01]
	sta	DirPointer+1		;				[FC]
J_8493:					;				[8493]
	jsr	CalcFirst		;				[883A]

	MoveW_	TapeBuffer+30, TapeBuffer+28

	jsr	SetupSector		;				[8899]
	jsr	Delay41ms		;				[89D0]
	jsr	SeekTrack		;				[898A]

	LoadB	NumOfSectors, 2

	jsr	SetWatchdog		;				[8D90]
	jsr	WriteSector		;				[8BEE]
	jsr	StopWatchdog		;				[8DBD]

	lda	ErrorCode		; error found?			[0351]
	bne	A_8506			;				[8506]

	dec	NumDirSectors		;				[0364]
	beq	A_84E5			;				[84E5]

	PushB	DirPointer
	PushB	DirPointer+1

	ldx	#1
	jsr	FindNextFAT		;				[85B2]
	bcs	:+			; no more FATs?

	pla
	pla
	LoadB	ErrorCode, ERR_FILE_TOO_LARGE
	jmp	J_84F1			;				[84F1]

:	jsr	MarkFAT			;				[8534]
	PopB	DirPointer+1
	PopB	DirPointer
	jmp	J_8493			;				[8493]

A_84E5:					;				[84E5]
	jsr	Enfile			;				[8684]
	jsr	WaitRasterLine		;				[8851]
	jsr	WriteFATs		;				[860C]
	jsr	WriteDirectory		;				[850F]
J_84F1:					;				[84F1]
	jsr	StopWatchdog		;				[8DBD]

	lda	ErrorCode		;				[0351]
	jsr	ShowError		;				[926C]

	LoadB	VICCTR1, $1B		; screen on

	cli
	LoadB	StatusIO, 0
	clc
	rts

A_8506:					;				[8506]
	jsr	Specify			;				[891A]
	jsr	Recalibrate		;				[88F7]
	jmp	J_847D			;				[847D]

WriteDirectory:				;				[850F]

	LoadB	NumOfSectors, 1

	MoveB	StartofDir, DirPointer+1
	LoadB	DirPointer, 0

	MoveB	DirSector, SectorL
	LoadB	SectorH, 0

	jsr	SetupSector		;				[8899]
	jsr	SeekTrack		;				[898A]
	jsr	SetWatchdog		;				[8D90]
	jsr	WriteSector		;				[8BEE]

	jmp	StopWatchdog		;				[8DBD]

MarkFAT:
	MoveB	TapeBuffer+29, TempStore

	lda	TapeBuffer+28		;				[0358]
	lsr	TapeBuffer+29		;				[0359]
	ror	TapeBuffer+28		;				[0358]
	pha

	and	#$FE
	clc
	adc	TapeBuffer+28		;				[0358]
	sta	TapeBuffer+28		;				[0358]

	lda	TempStore		;				[FA]
	adc	TapeBuffer+29		;				[0359]
	sta	TapeBuffer+29		;				[0359]

	MoveB	TapeBuffer+28, DirPointer

	lda	TapeBuffer+29		;				[0359]
	adc	EndofDir		;				[0335]
	sta	DirPointer+1		;				[FC]

	pla
	and	#1
	bne	:+

	ldy	#0
	lda	TapeBuffer+26		;				[0356]
	jsr	WrDataRamDxxx		;				[01AF]

	iny
	jsr	RdDataRamDxxx		;				[01A0]

	and	#$F0
	ora	TapeBuffer+27		;				[0357]
	jsr	WrDataRamDxxx		; XXX JMP <-> JSR+RTS (unless this TXS stuff matters?)
	rts

:	ldy	#1
	jsr	RdDataRamDxxx		;				[01A0]

	and	#$0F
	sta	TempStore		;				[FA]

	lda	TapeBuffer+26		;				[0356]
	asl	A
	asl	A
	asl	A
	asl	A
	ora	TempStore		;				[FA]
	jsr	WrDataRamDxxx		;				[01AF]

	iny
	lda	TapeBuffer+26		;				[0356]
	lsr	TapeBuffer+27		;				[0357]
	ror	A
	lsr	TapeBuffer+27		;				[0357]
	ror	A
	lsr	TapeBuffer+27		;				[0357]
	ror	A
	lsr	TapeBuffer+27		;				[0357]
	ror	A
	jsr	WrDataRamDxxx		;				[01AF]
	rts

FindFAT:				;				[85A8]
	LoadB	TapeBuffer+26, 2
	LoadB	TapeBuffer+27, 0

FindNextFAT:				;				[85B2]
	MoveW_	TapeBuffer+26, TapeBuffer+30

	jsr	GetNextCluster		;				[87A4]

	lda	TapeBuffer+30		;				[035A]
	ora	TapeBuffer+31		;				[035B]
	beq	:+

	AddVB	1, TapeBuffer+26	; XXX this is IncW candidate but needs LDA TapeBuffer+27 at the end
	lda	TapeBuffer+27		;				[0357]
	adc	#0
	sta	TapeBuffer+27		;				[0357]

	cmp	#2
	bne	FindNextFAT		;				[85B2]

	CmpBI	TapeBuffer+26, $CA
	bne	FindNextFAT		;				[85B2]

	clc
	rts

:	MoveW_	TapeBuffer+26, TapeBuffer+30
	dex
	bmi	:+			;				[860A]

	AddVB	1, TapeBuffer+26	; XXX this is IncW candidate but needs LDA TapeBuffer+27 at the end
	lda	TapeBuffer+27		;				[0357]
	adc	#0
	sta	TapeBuffer+27		;				[0357]
	jmp	FindNextFAT		;				[85B2]

:	sec
	rts

WriteFATs:				;				[860C]
	LoadB	NumOfSectors, 3

	MoveB	EndofDir, DirPointer+1
	LoadB	DirPointer, 0

	LoadB	SectorL, 1
	LoadB	SectorH, 0

	jsr	SetupSector		;				[8899]
	jsr	SeekTrack		;				[898A]
	jsr	SetWatchdog		;				[8D90]
	jsr	WriteSector		;				[8BEE]
	jsr	StopWatchdog		;				[8DBD]

	MoveB	EndofDir, DirPointer+1
	LoadB	DirPointer, 0

	LoadB	NumOfSectors, 3

	LoadB	SectorL, 4

	jsr	SetupSector		;				[8899]
	jsr	SeekTrack		;				[898A]
	jsr	SetWatchdog		;				[8D90]
	jsr	WriteSector		;				[8BEE]

	jmp	StopWatchdog		;				[8DBD]

ClearFATs:				;				[8650]
	ldy	#$1A
	jsr	RdDataRamDxxx		;				[01A0]

	sta	TapeBuffer+30		;				[035A]
	sta	TapeBuffer+28		;				[0358]

	iny
	jsr	RdDataRamDxxx		;				[01A0]

	sta	TapeBuffer+31		;				[035B]
	sta	TapeBuffer+29		;				[0359]

	LoadW_	TapeBuffer+26, 0

:	jsr	GetNextCluster		;				[87A4]
	jsr	MarkFAT			;				[8534]

	MoveB	TapeBuffer+30, TapeBuffer+28
	MoveB	TapeBuffer+31, TapeBuffer+29
	cmp	#$0F			; TapeBuffer+31,+29
	bne	:-
	rts

Enfile:					;				[8684]
	MoveW_	TapeBuffer+30, TapeBuffer+28
	LoadW_	TapeBuffer+26, $0FFF	; ??? FAT magic?
	jmp	MarkFAT			;				[8534]


;**  Load the File BOOT.EXE ino memory - part 2
;    Note: not used anywhere else AFAIK, so why not one routine?
LoadBootExe2:				;				[869D]
	sei

	stx	EndAddrBuf		;				[AE]
	sty	EndAddrBuf+1		;				[AF]

	LoadB	SecondAddress, $FF

	jsr	InitStackProg		;				[8D5A]

	jsr	FindFile		; File found?			[8FEA]
	bcc	:+			; no, ->			[86B4]
	PushB	VICCTR1
	bcs	__LoadFileFound		; always ->			[86EB]

:	sec
	LoadB	SecondAddress, 0
	sta	FlgLoadVerify		;				[93]
	rts


; New LOAD routine
; in:	X/Y = Load address 
;       A   = LOAD (0)  or   VERIFY (1) 
NewLoad:				;				[86BC]
	sei

	stx	EndAddrBuf		;				[AE]
	sty	EndAddrBuf+1		;				[AF]

	pha

	CmpBI	DeviceNumber, 9		; XXX device number
	beq	__NewLoad

	pla
	jmp	(NewILOAD)		;				[03FC]

__NewLoad:
	pla
; ??? is VERIFY ignored ???

	PushB	VICCTR1

	jsr	InitStackProg		;				[8D5A]
	jsr	FindFile		;				[8FEA]
	bcs	__LoadFileFound

	pla
	and	#$7F			; XXX why?
	sta	VICCTR1			;				[D011]

	lda	ErrorCode		;				[0351]
	jsr	ShowError		;				[926C]

	LoadB	VICCTR1, $1B		; screen on
	rts


; File found
__LoadFileFound:
	ldy	#$10			; load address?
	jsr	RdDataRamDxxx		;				[01A0]
	iny
	sta	TapeBuffer+47		;				[036B]
	jsr	RdDataRamDxxx		;				[01A0]
	iny				; XXX not needed
	sta	TapeBuffer+46		;				[036A]

	ldy	#$1A			; first cluster?
	jsr	RdDataRamDxxx		;				[01A0]
	iny
	sta	TapeBuffer+30		;				[035A]
	jsr	RdDataRamDxxx		;				[01A0]
	iny
	sta	TapeBuffer+31		;				[035B]

	jsr	RdDataRamDxxx		; length?			[01A0]
	iny
	sta	TapeBuffer+37		;				[0361]
	jsr	RdDataRamDxxx		;				[01A0]
	iny
	sta	TapeBuffer+36		;				[0360]
	jsr	RdDataRamDxxx		;				[01A0]
	iny
	sta	TapeBuffer+35		;				[035F]
	jsr	RdDataRamDxxx		;				[01A0]
	iny				; XXX not needed, GetFATs calls SetupSector and destros Y
	sta	TapeBuffer+34		;				[035E]

	jsr	GetFATs			;				[8813]
	jsr	CalcFirst		;				[883A]

	MoveB	TapeBuffer+37, TapeBuffer+38
	MoveB	TapeBuffer+36, TapeBuffer+39

	lda	SecondAddress		; load address from user?
	beq	:+			; yes(?)

	MoveW_	TapeBuffer+46, EndAddrBuf ; no, from directory
:	MoveW_	EndAddrBuf, DirPointer

@loop:
	LoadB	NumOfSectors, 2

	jsr	SetupSector		;				[8899]
	jsr	SeekTrack		;				[898A]

	LoadB	NumOfSectors, 2

	jsr	ReadSectors		;				[885E]

	PushB	DirPointer
	PushB	DirPointer+1

	jsr	GetNextCluster		;				[87A4]

	PopB	DirPointer+1
	PopB	DirPointer

	CmpBI	TapeBuffer+31, $0F	; magic FAT value for end of file?
	beq	@done

	jsr	CalcFirst		;				[883A]
	jmp	@loop

@done:	lda	EndAddrBuf		;				[AE]
	clc
	adc	TapeBuffer+37		;				[0361]
	tax

	lda	EndAddrBuf+1		;				[AF]
	adc	TapeBuffer+36		;				[0360]
	tay

	cli

	LoadB	StatusIO, 0

	pla
	and	#$7F			; XXX why?
	sta	VICCTR1			;				[D011]

	txa
	pha
	tya
	pha

	lda	ErrorCode		;				[0351]
	jsr	ShowError		;				[926C]

	pla
	tay
	pla
	tax
	clc
	rts

GetNextCluster:				;				[87A4]
	MoveB	TapeBuffer+31, TapeBuffer+33

	lda	TapeBuffer+30		;				[035A]
	and	#$FE
	sta	TapeBuffer+32		;				[035C]

	lsr	TapeBuffer+33		;				[035D]
	ror	TapeBuffer+32		;				[035C]
	clc
	adc	TapeBuffer+32		;				[035C]
	sta	DirPointer		;				[FB]

	lda	TapeBuffer+33		;				[035D]
	and	#$0F
	adc	EndofDir		;				[0335]
	clc
	adc	TapeBuffer+31		;				[035B]
	sta	DirPointer+1		;				[FC]

	lda	TapeBuffer+30		;				[035A]
	and	#1
	bne	:+

	ldy	#0
	jsr	RdDataRamDxxx		;				[01A0]
	iny
	sta	TapeBuffer+30		;				[035A]
	jsr	RdDataRamDxxx		;				[01A0]
	and	#$0F
	sta	TapeBuffer+31		;				[035B]
	rts

:	ldy	#1
	lda	#0
	sta	TapeBuffer+31		;				[035B]

	jsr	RdDataRamDxxx		;				[01A0]

	iny
	and	#$F0
	lsr	A
	lsr	A
	lsr	A
	lsr	A
	sta	TapeBuffer+30		;				[035A]

	jsr	RdDataRamDxxx		;				[01A0]

	asl	A
	rol	TapeBuffer+31		;				[035B]
	asl	A
	rol	TapeBuffer+31		;				[035B]
	asl	A
	rol	TapeBuffer+31		;				[035B]
	asl	A
	rol	TapeBuffer+31		;				[035B]
	ora	TapeBuffer+30		;				[035A]
	sta	TapeBuffer+30		;				[035A]

	rts


; Load 3 sectors of the FAT table into RAM under the I/O from $D200 on
GetFATs:				;				[8813]
	LoadB	DirPointer, 0
	MoveB	EndofDir, DirPointer+1

	LoadB	SectorL, 1
	LoadB	SectorH, 0

	jsr	SetupSector		;				[8899]

	LoadB	TapeBuffer+38, 0

	LoadB	NumOfSectors, 3
	asl	A			; A := 6
	sta	TapeBuffer+39		;				[0363]

	jsr	ReadSectors		;				[885E]
	jmp	StopWatchdog		;				[8DBD]


CalcFirst:				;				[883A]
	MoveB	TapeBuffer+31, SectorH

	lda	TapeBuffer+30		;				[035A]
	asl	A
	rol	SectorH			;				[F9]
	clc
	adc	#$0A
	sta	SectorL			;				[F8]

	lda	SectorH			;				[F9]
	adc	#0
	sta	SectorH			;				[F9]

	rts


;**  Wait for rasterline $1FF
WaitRasterLine:				;				[8851]
	LoadB	VICCTR1, $0b		; screen off
:	CmpBI	VICLINE, $FF
	bne :-
	rts

;**  Read multiple sectors
; IMHO it reads 9 sectors = a complete track of one side
ReadSectors:				;				[885E]

	LoadB	Counter, 0

@loop:	LoadB	ErrorCode, ERR_OK	; also 0 XXX

	jsr	WaitRasterLine		;				[8851]
	jsr	SetWatchdog		;				[8D90]
	jsr	ReadSector		;				[8C78]

	CmpBI	Counter, 9		; read whole track?
	bne	:+

	LoadB	ErrorCode, ERR_DISK_MAY_BE_DAMAGED
	bne	@end			; always ->

:	inc	Counter			;				[0366]
	lda	ErrorCode		; error found?			[0351]
	bne	@err			; yes, -> 			[888A]
@end:					;				[8887]
	jmp	StopWatchdog		;				[8DBD]

@err:	jsr	Delay41ms		;				[89D0]
	jsr	Specify			;				[891A]
	jsr	Recalibrate		;				[88F7]
	jsr	SeekTrack		;				[898A]
	jmp	@loop


;**  Setup the data needed for the FDC
SetupSector:				;				[8899]
	CmpBI	SectorH, >1440
	bcc	:+
	CmpBI	SectorL, <1440
	bcs	@end			; exit but don't report any error?
; FYI: 5*256 + 160 = 1440 = number of sectors on 3.5" 720 KB disk
; BUG: if (SectorH > 5) and SectorL < 160) then routine continues as well

; Convert sector to track
:	ldx	#0			; tracks
	ldy	#0			; XXX Y not used here

:	lda	SectorL			;				[F8]
	subv	9
	sta	SectorL			;				[F8]
	inx
	bcs	:-			; if SectorL > 8 then repeat	[88A9]

	lda	SectorH			;				[F9]
	sbc	#0
	sta	SectorH			;				[F9]
	bcs	:-			; if SectorH > 0 then repeat	[88A9]

	dex
; Correct last subtraction
	AddVB	10, SectorL		; one extra because FDC counts 1..9
	sta	FdcSector		;				[0349]
	inc	SectorH			;				[F9]
	sta	FdcEOT			;				[034B]

	txa
	and	#1
	sta	FdcHead			;				[0348]

	asl	A
	asl	A
	sta	FdcHSEL			;				[0346]

	txa
	lsr	A
	sta	FdcTrack		;				[0347]

	and	#$FE
	sta	FdcTrack2		;				[034E]
@end:	rts


; ??? not used anywhere AFAIK
E_88E1:					;				[88E1]
	lsr	A
	sta	FdcTrack		;				[0347]
	pla
	and	#1
	sta	FdcHead			;				[0348]
	asl	A
	asl	A
	sta	FdcHSEL			;				[0346]
	stx	FdcSector		;				[0349]
	stx	FdcEOT			;				[034B]
	rts


;**  Recalibrate the drive
Recalibrate:				;				[88F7]
	jsr	Wait4FdcReady		;				[89C0]

	LoadB	DataRegister, 7		; ???
	jsr	Wait4DataReady		;				[89C8]

	LoadB	DataRegister, 0		; drive 0

:	jsr	SenseIrqStatus		;				[894A]
	lda	FdcST0			;				[033C]
	and	#%00100000		; command completed?
	beq	:-			; no, ->			[8907]
	lda	FdcPCN			; track = 0?			[0344]
	bne	:-			; no, -> wait			[8907]

	jsr	SenseDrvStatus		; XXX jmp and remove next rts	[8933]
	rts


;**  Set some values, head moves to track 0
Specify:				;				[891A]
	jsr	Wait4FdcReady		;				[89C0]

	LoadB	DataRegister, 3		; ???
	jsr	Wait4DataReady		;				[89C8]

	LoadB	DataRegister, $EF	; step rate time, E = 2 ms.
					; head unload time, F = 240 ms.
	jsr	Wait4DataReady		;				[89C8]

	LoadB	DataRegister, $01	; head load time, 0 = 2 ms.
					; 1 = set "no DMA mode"
	rts


;**  Sense the status of the drive
SenseDrvStatus:				;				[8933]
	LoadB	DataRegister, $04	; ???
	jsr	Wait4DataReady		;				[89C8]

	LoadB 	DataRegister, 0		; select drive 0
					; head select = 0
	jsr	Wait4DataReady		;				[89C8]

	MoveB	DataRegister, FdcST3
	rts


;**  Sense the status of the interrupt
SenseIrqStatus:				;				[894A]
	LoadB	DataRegister, $08	; ???
	jsr	Wait4DataReady		;				[89C8]

	MoveB	DataRegister, FdcST0	; read ST0
	jsr	Wait4DataReady		;				[89C8]

	MoveB	DataRegister, FdcPCN	; present cyliner		[0344]
	rts


;**  Read seven bytes from the results after a command
ReadStatus:				;				[8962]
	ldy	#0
	ldx	#0			; try counter

:	lda	StatusRegister		; XXX bbsf 5			[DE80]
	and	#%00100000
	bne	:-
	dex				; 256 tries done?
	beq	@err			; yes, -> error			[8988]

	lda	StatusRegister		;				[DE80]
	and	#$C0
	cmp	#$C0			; FDC ready?
	bne	:-			; no, -> wait			[8966]

	lda	DataRegister		;				[DE81]
	sta	FdcST0,Y		;				[033C]

	ldx	#0			; reset try counter
	iny
	cpy	#7			; seven bytes read?
	bne	:-			; no, -> more			[8966]

	clc				; no error
	rts

@err:	sec				; error
	rts


;**  Seek a track
SeekTrack:				;				[898A]
	LoadB	DataRegister, $0F	; ???
	jsr	Wait4DataReady		;				[89C8]

	MoveB	FdcHSEL, DataRegister
	jsr	Wait4DataReady		;				[89C8]

	MoveB	FdcTrack, DataRegister
	jsr	Wait4DataReady		;				[89C8]

:	jsr	SenseIrqStatus		;				[894A]
	lda	FdcST0			;				[033C]
	lda	FdcST0			; why twice ???			[033C]
	and	#%00100000		; command completed? XXX bbcf 5
	beq	:-			; no, -> wait			[89A4]
	CmpB	FdcPCN, FdcTrack	; same track as present track?
	beq	@end			; yes, -> exit			[89BF]

	jsr	Recalibrate		;				[88F7]
	jmp	SeekTrack		;				[898A]

@end:	rts


;**  Wait until the FDC is ready
Wait4FdcReady:				;				[89C0]
:	lda	StatusRegister		;				[DE80]
	and	#%00011111		; FDC is busy?
	bne	:-			; yes, -> wait			[89C0]
	rts


;**  Wait until the data register is ready
Wait4DataReady:				;				[89C8]
:	lda	StatusRegister		;				[DE80]
	and	#%10000000		; FDC ready? XXX bbcf 7
	beq	:-			; no, -> wait			[89C8]
	rts


;**  Delay, roughly for 41 ms.
Delay41ms:				;				[89D0]
	ldx	#$C8
	ldy	#$28
:	dex
	bne	:-
	dey
	bne	:-
	rts


FormatDisk:				;				[89DB]
	sei
	jsr	WaitRasterLine		; this could be done later

	ldy	#0
:	lda	(AddrFileName),Y	;				[BB]
	cmp	#$22
	beq	:+
	sta	FdcFileName,Y		;				[036C]
	iny
	cpy	#$0B
	bne	:-
	sec
	rts

:	cpy	#$0B
	beq	:+

	lda	#$20
	sta	FdcFileName,Y		;				[036C]
	iny
	bne	:-

:	jsr	GetlengthFName		;				[8336]
	jsr	InitStackProg		;				[8D5A]

	lda	FdcST3			;				[0343]
	and	#%01000000		; XXX bit / bbrf 6
	beq	:+			;				[8A0F]

	lda	#ERR_DISK_WRITE_PROTECT
	jmp	ShowError		;				[926C]

:	ldx	#15
	jsr	ClearDirectory

	LoadB	FdcTrack2, 0
	LoadB	Counter, 1

FormatDiskLoop:
	LoadB	ErrorCode, ERR_OK	; XXX also 0

	lda	FdcTrack2		;				[034E]
	lsr	A
	sta	FdcTrack		;				[0347]

	lda	FdcTrack2		;				[034E]
	and	#1
	sta	FdcHead			;				[0348]

	asl	A
	asl	A
	sta	FdcHSEL			;				[0346]

	LoadB	FdcNumber, 2
	LoadB	FdcSector, 1

	jsr	SeekTrack		;				[898A]
	jsr	FormatTrack		;				[8B93]

	lda	ErrorCode		; error found?			[0351]
	beq	@cont
@err:	jmp	@tryagain

@cont:	jsr	SetWatchdog		;				[8D90]
	jsr	P_8B49			;				[8B49]
	bcs	@err			;				[8A4C]

	lda	ErrorCode		; error found?			[0351]
	beq	@cont2			;				[8A5F]
	jmp	@tryagain

@cont2:	jsr	StopWatchdog		;				[8DBD]

	inc	FdcTrack2		;				[034E]
	LoadB	Counter, 1

	CmpBI	FdcTrack, 80		; 80 - last track?
	bne	FormatDiskLoop

	LoadB	DirPointer, 0
	MoveB	StartofDir, DirPointer+1

	ldy	#0			; FAT12 identifier+BIOS Parameter Block?
:	lda	D_943E,Y		;				[943E]
	jsr	WrDataRamDxxx		;				[01AF]
	iny
	cpy	#$20
	bne	:-

	MoveB	EndofDir, DirPointer+1

	lda	#$F9			; $FFF9 - FAT#1 magic?
	ldy	#0
	jsr	WrDataRamDxxx		;				[01AF]
	iny
	lda	#$FF
	jsr	WrDataRamDxxx		;				[01AF]
	iny
	lda	#$FF
	jsr	WrDataRamDxxx		;				[01AF]

	LoadB	DirPointer+1, $D8	; page $D800 in RAM?

	lda	#$F9			; $FFF9 - FAT#2 magic?
	ldy	#0
	jsr	WrDataRamDxxx		;				[01AF]
	iny
	lda	#$FF
	jsr	WrDataRamDxxx		;				[01AF]
	iny
	lda	#$FF
	jsr	WrDataRamDxxx		;				[01AF]

	LoadB	NumOfSectors, 8
	LoadB	SectorL, 0
	LoadB	SectorH, 0		; XXX optimization

	jsr	SetupSector		;				[8899]
	jsr	SeekTrack		;				[898A]
	jsr	SetWatchdog		;				[8D90]

	MoveB	StartofDir, DirPointer+1

	jsr	WriteSector		;				[8BEE]
	jsr	StopWatchdog		;				[8DBD]

	ldx	#1
	jsr	ClearDirectory

	MoveB	StartofDir, DirPointer+1

	ldx	#0
	ldy	#0
:	lda	FdcFileName,X		; volume label?			[036C]
	inx
	jsr	WrDataRamDxxx		;				[01AF]
	iny
	cpy	#$0B
	bne	:-
	lda	#$08			; volume label attribute?
	jsr	WrDataRamDxxx		;				[01AF]

	LoadB	SectorL, 7
	jsr	SetupSector		;				[8899]
	LoadB	NumOfSectors, 1
	jsr	SetWatchdog		;				[8D90]
	jsr	WriteSector		;				[8BEE]
	jsr	StopWatchdog		;				[8DBD]

	LoadB	VICCTR1, $1B		; screen on
	clc
	rts

@tryagain:
	dec	Counter			;				[0366]
	bpl	@enderr

	LoadB	ErrorCode, ERR_DISK_UNRELIABLE
	jsr	ShowError		;				[926C]

	LoadB	VICCTR1, $1B		; screen on (optimization, see above XXX)
	clc
	rts

@enderr:
	jsr	StopWatchdog		;				[8DBD]
	jsr	Specify			;				[891A]
	jsr	Recalibrate		;				[88F7]
	jmp	FormatDiskLoop

ClearDirectory:
; clear directory under $D000, X has count of pages
	LoadB	DirPointer, 0
	MoveB	StartofDir, DirPointer+1

	lda	#0
	ldy	#0			; XXX tay
:	jsr	WrDataRamDxxx		;				[01AF]
	iny
	bne	:-
	inc	DirPointer+1		;				[FC]
	dex
	bpl	:-
	rts

P_8B49:					;				[8B49]
	tsx
	stx	TempStackPtr		; XXX why? watchdog?		[0350]

	LoadB	ErrorCode, ERR_OK
	LoadB	FdcCommand, $66		; ???
	LoadB	FdcEOT, 9
	LoadB	FdcSector, 1

	ldy	#0
:	lda	StatusRegister		; XXX optimize bit+bpl		[DE80]
	and	#$80
	beq	:-
	lda	FdcCommand,Y		;				[0345]
	sta	DataRegister		;				[DE81]
	iny
	cpy	#9
	bne	:-

	ldx	#15			; retries
	ldy	#0
:	bit	StatusRegister		; FDC ready? XXX bbcf 7		[DE80]
	bpl	:-			; no, -> wait			[8B79]

	CmpBI	DataRegister, 0		; XXX LDA DataRegister + BEQ is enough
	beq	:+			;				[8B8A]

	LoadB	ErrorCode, ERR_DISK_WRITE_PROTECT
:	iny
	bne	:--
	dex
	bpl	:--
	jmp	ReadStatus		;				[8962]


;**  Format a track
FormatTrack:				;				[8B93]
	LoadB	FdcFormatData, $4D	; ???

	MoveB	FdcHSEL, FdcFormatData+1
	MoveB	FdcNumber, FdcFormatData+2
	LoadB	FdcFormatData+3, 9	; sectors / track
	LoadB	FdcFormatData+4, $54	; gap length
	LoadB	FdcFormatData+5, 0

	ldy	#0
:	bit	StatusRegister		; FDC ready?			[DE80]
	bpl	:-
	lda	FdcFormatData,Y		;				[0352]
	sta	DataRegister		;				[DE81]
	iny
	cpy	#6			; 6 bytes written?
	bne	:-

;* Supply the data field for each sector, see data sheet for details
	LoadB	FdcSector, 1

	ldx	#8			; 9 sectors
@loop:	ldy	#0
; Supply TCHRN information
:	lda	FdcTrack,Y		;				[0347]
:	bit	StatusRegister		; FDC ready?			[DE80]
	bpl	:-			; no, -> wait			[8BD1]
	sta	DataRegister		;				[DE81]
	iny
	cpy	#$04			; supplied neede 5 bytes?
	bne	:--
	inc	FdcSector		; next sector			[0349]
	dex				; nine sectors done?
	bpl	@loop			; no, -> more			[8BCC]

A_8BE4:					;				[8BE4]
:	lda	StatusRegister		;				[DE80]
	and	#%00100000		; execution finished?
	bne	:-
	jmp	ReadStatus		;				[8962]


;**  Write one or more sector to the disk
WriteSector:				;				[8BEE]
	ldy	#0
	LoadB	FdcCommand, $65		; code for "write sector"

:	lda	StatusRegister		;				[DE80]
	and	#$80			; FDC ready? ; XXX BPL like above
	beq	:-
	lda	FdcCommand,Y		;				[0345]
	sta	DataRegister		;				[DE81]
	iny
	cpy	#9			; nine sectors done?
	bne	:-

	LoadB	PageCounter, 1

	ldy	#0
	jsr	WriteData		;				[0179]

	lda	ErrorCode		; error found?			[0351]
	bne	@err

	jsr	ReadStatus		; error found?			[8962]
	bcs	@retry

	lda	FdcST1			;				[033D]
	and	#$F8
	cmp	#$80			; error found?
	beq	@next			; no, ->			[8C39]

; Error found, but we try again. But: HOW MAY TRIES ???
@retry:	dec	DirPointer+1		;				[FC]
	dec	DirPointer+1		;				[FC]

	jsr	Specify			;				[891A]
	jsr	Recalibrate		;				[88F7]
	jsr	SeekTrack		;				[898A]
	jsr	SetWatchdog		;				[8D90]

	jmp	WriteSector		;				[8BEE]

; Error found
@err:	jmp	StopWatchdog		;				[8DBD]

@next:	jsr	SetWatchdog		;				[8D90]

	inc	FdcEOT			;				[034B]
	inc	FdcSector		;				[0349]

	dec	NumOfSectors		; all sectors written?		[F7]
	beq	@end			; yes, -> exit			[8C75]

	CmpBI	FdcEOT, 9+1		; complete track written?
	beq	@nexttrack		; yes, -> next track		[8C50]

	jmp	WriteSector		;				[8BEE]

; Go to the next track
@nexttrack:
	LoadB	FdcEOT, 1
	sta	FdcSector		;				[0349]

; Go to the other head
	lda	FdcHead			;				[0348]
	eor	#1
	sta	FdcHead			;				[0348]

	asl	A
	asl	A
	sta	FdcHSEL			;				[0346]

	cmp	#4			; head 1?
	beq	@cont			; yes, -> continue		[8C72]

; Head 0 -> head 1 means: next track
	inc	FdcTrack		;				[0347]
	jsr	SeekTrack		;				[898A]

	jsr	SetWatchdog		;				[8D90]
@cont:	jmp	WriteSector		;				[8BEE]

@end:	jmp	StopWatchdog		;				[8DBD]


;**  Read a sector
ReadSector:				;				[8C78]
	ldy	#0
	sty	L_0119+1		;				[011A]

	LoadB	FdcCommand, $66		; "Read sector" command
; Write the needed bytes into the FDC
:	lda	StatusRegister		;				[DE80]
	and	#$80			; FDC busy? XXX BPL like above
	beq	:-
	lda	FdcCommand,Y		;				[0345]
	sta	DataRegister		;				[DE81]
	iny
	cpy	#9			; nine bytes written?
	bne	:-

	CmpBI	TapeBuffer+39, 2
	bcs	@sector			;				[8CB7]

	and	#1
	beq	@part			;				[8CB1]

	MoveB	TapeBuffer+38, L_0165+1	; number of bytes to read after	first 256 bytes

	ldy	#0			; start with reading 256 bytes

	LoadB	NumOfSectors, 1

	jsr	RdBytesSector		;				[0139]
	jmp	@cont

; part of page
@part:	MoveB	TapeBuffer+38, L_0119+1
; whole sector
@sector:
	LoadB	PageCounter, 1		; read two pages, whole sector
	ldy	#0
	jsr	ReadPagesFlop		;				[0102]

@cont:	lda	ErrorCode		; error found?			[0351]
	bne	@end			; yes, -> 			[8CE9]

	jsr	ReadStatus		;				[8962]
	bcs	@retry

	lda	FdcST1			;				[033D]
	and	#$F8
	cmp	#$80
	beq	@next

@retry:	dec	DirPointer+1		;				[FC]
	dec	DirPointer+1		;				[FC]
	jsr	StopWatchdog		;				[8DBD]
	jsr	Specify			;				[891A]
	jsr	Recalibrate		;				[88F7]
	jsr	SeekTrack		;				[898A]
	jsr	SetWatchdog		;				[8D90]

	jmp	ReadSector		;				[8C78]

@end:	rts

@next:	jsr	SetWatchdog		;				[8D90]
	inc	FdcEOT			;				[034B]
	inc	FdcSector		;				[0349]
	CmpBI	TapeBuffer+39, 2	;				[0363]
	bcc	A_8D36			;				[8D36]

	subv	2
	sta	TapeBuffer+39		;				[0363]
	dec	NumOfSectors		;				[F7]
	beq	A_8D36			;				[8D36]

	CmpBI	FdcEOT, $0A		; ???
	beq	A_8D0E			;				[8D0E]

	jmp	ReadSector		;				[8C78]

A_8D0E:					;				[8D0E]
	jsr	StopWatchdog		;				[8DBD]

	LoadB	FdcEOT, 1
	sta	FdcSector		;				[0349]

	lda	FdcHead			;				[0348]
	eor	#1
	sta	FdcHead			;				[0348]

	asl	A
	asl	A
	sta	FdcHSEL			;				[0346]

	cmp	#$04
	beq	A_8D33			;				[8D33]

	inc	FdcTrack		;				[0347]
	jsr	SeekTrack		;				[898A]
	jsr	SetWatchdog		;				[8D90]
A_8D33:					;				[8D33]
	jmp	ReadSector		;				[8C78]

A_8D36:					;				[8D36]
	rts

; unused
E_8D37:					;				[8D37]
	ldx	#2
; unused
A_8D39:					;				[8D39]
:	lda	Wait4FdcReady		;				[89C0]
	and	#1
	bne	:-
	rts

; unused, hex digit printing directly to top of screen
E_8D41:					;				[8D41]
	pha
	and	#$0F
	tay
	lda	D_8D80,Y		;				[8D80]
	sta	VICSCN+1,X		;				[0401]
	pla
	pha
	lsr	A
	lsr	A
	lsr	A
	lsr	A
	tay
	lda	D_8D80,Y		;				[8D80]
	sta	VICSCN,X		;				[0400]
	pla
	rts


;**  Initialize the program that should run in the stack page
InitStackProg:				;				[8D5A]
; Preset the "Read data" command,
	ldx	#8
:	lda	CmdReadData,X		;				[8D77]
	sta	FdcCommand,X		;				[0345]
	dex
	bpl	:-

; Actual copy
	ldx	#<(__STACK0101_LAST__-2)
:	lda	StackProgram,X		;				[9462]
	sta	StackPage1,X		;				[0101]
	dex
	bne	:-

	jsr	Specify			;				[891A]
	jsr	Recalibrate		; JMP instead of JSR+RTS?	[88F7]
	rts


;**  Bytes need for the command "Read data"  IMHO
; XXX check datasheet
CmdReadData:				;				[8D77]
.byte $66, $00, $02, $00, $01, $02, $01, $1B, $FF 

; XXX unused, part of unused hex-printing routine
D_8D80:					;				[8D80]
; '0123456789ABCDEF' in screencodes
.byte "0123456789"
.byte $01, $02, $03, $04, $05, $06 ; 

;**  Set the timer of CIA2 to generate an IRQ when FDC has to wait too long
SetWatchdog:				;				[8D90]

	LoadB	CIA2CRA, 0		; stop timer A
	sta	CIA2CRB

	LoadB	CIA2TI1H, 8
	LoadB	CIA2TI2H, 2

	LoadB	CIA2TI1L, 0
	sta	CIA2TI2L

	LoadB	CIA2CRB, $51		; start the timer, count underflow of timer A
	LoadB	CIA2CRA, $91		; start the timer for 50 Hz

	LoadB	CIA2IRQ, $82		; enable interrupt (NMI) for timer B underflow

	lda	CIA2IRQ			; clear interrupt flag register, acknowledge any pending interrupts
	rts

;**  Disable timer IRQ, stop the timer
StopWatchdog:				;				[8DBD]
	LoadB	CIA2IRQ, $7F
	LoadB	CIA2CRA, 0
	sta	CIA2CRB
	rts

J_8DCB:					;				[8DCB]
	pha
	txa
	pha
	tya
	pha

	jsr	IncrClock22		;				[F6BC]
	jsr	ScanStopKey		;				[FFE1]
	beq	:+

	pla
	tay
	pla
	tax
	pla
	rti

:	jsr	InitSidCIAIrq2		;				[FDA3]
	jsr	InitScreenKeyb		;				[E518]
	jmp	(BasicNMI)		;				[A002]


; Oficially here starts the NMI routine of the cartridge. Now the weird fact:
; the NMI input of the expansion port is not connected. But during the 
; initialisation of the C64 the routine is set as first NMI routine for the it.
; XXX NMI is called from watchdog timer (CIA2)
CartNMI:				;				[8DE7]
	pha
	PushB	P6510
	LoadB	P6510, $37

	lda	CIA2IRQ			; XXX what is bit 7 and 1?
	bpl	:+
	and	#%00000010
	beq	:+

	inc	ErrorCode		; XXX ??? why			[0351]
	ldx	TempStackPtr		; XXX ??? why 			[0350]
	txs

	lda	ResetFDC		; reset the FDC			[DF80]

	jmp	StopWatchdog		;				[8DBD]

:	jsr	NewRoutines		;				[80C0]

	PopB	P6510
	pla
	jmp	J_8DCB			;				[8DCB]



ReadDirectory:				;				[8E0F]
	LoadB	NumOfSectors, 1
	LoadB	Counter, 0
J_8E18:					;				[8E18]
	MoveB	Z_FF, SectorL

	ldx	#0
	stx	SectorH			; XXX optimize			[F9]

	LoadB	DirPointer, 0
	MoveB	StartofDir, DirPointer+1

	jsr	SetupSector		;				[8899]

	LoadB	ErrorCode, ERR_OK

	jsr	SeekTrack		;				[898A]
	jsr	SetWatchdog		;				[8D90]
	jsr	WaitRasterLine		;				[8851]

	LoadB	TapeBuffer+39, 2
	LoadB	TapeBuffer+38, 0

	jsr	ReadSector		;				[8C78]

	CmpBI	Counter, 9		; whole track?
	bne	@nottrack		;				[8E55]

	LoadB	ErrorCode, ERR_DISK_MAY_BE_DAMAGED
	bne	@end			; always! (XXX 2 bytes for BNE but 1 for RTS already)

@nottrack:
	inc	Counter			;				[0366]
	lda	ErrorCode		; error found?			[0351]
	bne	@err			;				[8E5E]
@end:	rts

@err:	jsr	Specify			;				[891A]
	jsr	Recalibrate		;				[88F7]
	jmp	J_8E18			;				[8E18]


;**  Load and display the directory
DisplayDir:				;				[8E67]
	LoadB	Z_FF, 7

	jsr	ReadDirectory		;				[8E0F]
	jsr	StopWatchdog		;				[8DBD]
	jsr	GetFATs			;				[8813]

	LoadB	VICCTR1, $1B		; screen on

	lda	ErrorCode		; error found?			[0351]
	beq	:+
	clc
	rts


; ??? what has been loaded exactly at this point ???
:	LoadB	DirPointer, 0
	MoveB	StartofDir, DirPointer+1

	ldy	#$0B

	sei

	jsr	RdDataRamDxxx		;				[01A0]

	cmp	#$08
	bne	J_8EBA			;				[8EBA]

	ldy	#0
A_8E95:					;				[8E95]
	sei
	jsr	RdDataRamDxxx		;				[01A0]

	sta	Z_FD			;				[FD]

	tya
	pha

; Convert to upper case, if needed
	CmpBI	Z_FD, $60		; < 'a' ?
	bcc	:+			; yes, ->			[8EA6]
	subv	$20
:	jsr	OutByteChan		;				[FFD2]

	lda	Z_FD			;				[FD]
; ??? why ???, see next instruction

	pla
	tay

	iny
	cpy	#$0B
	bne	A_8E95			;				[8E95]

	lda	#13			; new line
	jsr	OutByteChan		;				[FFD2]

	jmp	J_8F1A			;				[8F1A]

J_8EBA:					;				[8EBA]
	LoadB	DirPointer, 0
	MoveB	StartofDir, DirPointer+1
A_8EC3:					;				[8EC3]
	ldy	#0
	sei
	jsr	RdDataRamDxxx		;				[01A0]

	cmp	#0
	beq	A_8F46			;				[8F46]

	cmp	#$E5
	beq	J_8F1A			;				[8F1A]

	ldx	#$07
A_8ED3:					;				[8ED3]
	sei
	jsr	RdDataRamDxxx		;				[01A0]

	iny
	cmp	#$20
	beq	A_8EED			;				[8EED]

	sta	Z_FD			;				[FD]

	txa
	pha

	tya
	pha

	lda	Z_FD			;				[FD]
	jsr	OutByteChan		;				[FFD2]

	lda	Z_FD			;				[FD]
	pla
	tay
	pla
	tax
A_8EED:					;				[8EED]
	dex
	bpl	A_8ED3			;				[8ED3]

	lda	#$2E
	jsr	OutByteChan		;				[FFD2]

	ldx	#2
A_8EF7:					;				[8EF7]
	sei
	jsr	RdDataRamDxxx		;				[01A0]

	iny
	cmp	#$20
	beq	A_8F0F			;				[8F0F]

	sta	Z_FD			;				[FD]

	txa
	pha

	tya
	pha

	lda	Z_FD			;				[FD]
	jsr	OutByteChan		;				[FFD2]

	pla
	tay
	pla
	tax
A_8F0F:					;				[8F0F]
	dex
	bpl	A_8EF7			;				[8EF7]

	jsr	SaveRloc		;				[9127]

	lda	#$0D
	jsr	OutByteChan		;				[FFD2]
J_8F1A:					;				[8F1A]
	lda	DirPointer		; XXX? AddVB $20, DirPointer + LDA DirPointer+1?
	addv	$20			; next directory entry
	sta	DirPointer		;				[FB]

	lda	DirPointer+1		;				[FC]
	adc	#0
	sta	DirPointer+1		;				[FC]

	cmp	EndofDir		;				[0335]
	bne	A_8EC3			;				[8EC3]

	AddVB	1, Z_FF
	cmp	#$0E
	bcs	A_8F46			;				[8F46]

	sei
	jsr	ReadDirectory		;				[8E0F]

	LoadB	VICCTR1, $1B		; screen on

	jsr	StopWatchdog		;				[8DBD]

	jmp	J_8EBA			;				[8EBA]

A_8F46:					;				[8F46]
	jsr	ShowBytesFree		;				[916A]

	pla
	pla
	pla
	pla
	pla
	rts


FindBlank:				;				[8F4F]
	LoadB	NumDirSectors, 7
	LoadB	SectorL, 7		; XXX optimization, directory starts at sector 7
	sta	DirSector
	LoadB	SectorH, 0

	jsr	SetupSector		;				[8899]
A_8F62:					;				[8F62]
	LoadB	DirPointer, 0
	MoveB	StartofDir, DirPointer+1

	LoadB	NumOfSectors, 1
	asl	A			; A:=2 -> $0200 in TapeBuffer+38,9
	sta	TapeBuffer+39		;				[0363]
	LoadB	TapeBuffer+38, 0

	jsr	ReadSectors		;				[885E]
	lda	ErrorCode		; error found?			[0351]
	beq	@noerr			;				[8F82]

	clc
	rts

@noerr:	LoadB	DirPointer, 0
	MoveB	StartofDir, DirPointer+1
A_8F8B:					;				[8F8B]
	ldx	#0
	ldy	#0
:	jsr	RdDataRamDxxx		;				[01A0]
	iny
	cmp	#0
	beq	A_8FD3			;				[8FD3]
	cmp	#$E5
	beq	A_8FD3			;				[8FD3]
	cmp	FdcFileName,X		;				[036C]
	bne	A_8FA7			;				[8FA7]
	inx
	cpx	#$0A
	bne	:-

	sec
	rts

A_8FA7:					;				[8FA7]
	lda	DirPointer		; next directory entry, use AddVW $20, DirPointer + CmpB DirPointer, EndofDir (also above) XXX
	addv	$20
	sta	DirPointer		;				[FB]

	lda	DirPointer+1		;				[FC]
	adc	#0
	sta	DirPointer+1		;				[FC]

	cmp	EndofDir		;				[0335]
	bne	A_8F8B			;				[8F8B]

	lda	DirSector		;				[0369]
	addv	1
	sta	SectorL			;				[F8]
	sta	DirSector		;				[0369]

	jsr	SetupSector		;				[8899]

	dec	NumDirSectors		;				[0364]
	bpl	A_8F62			;				[8F62]

	LoadB	ErrorCode, ERR_NO_MORE_DIRECTORY_SPACE

	clc
	rts

A_8FD3:					;				[8FD3]
	ldy	#$1F
	lda	#0
:	jsr	WrDataRamDxxx		;				[01AF]
	dey
	bpl	:-

	ldy	#$0A
:	lda	FdcFileName,Y		;				[036C]
	jsr	WrDataRamDxxx		;				[01AF]
	dey
	bpl	:-
	clc
	rts


;**  Check the file name
FindFile:				;				[8FEA]
	lda	LengthFileName		; file name present?		[B7]
	bne	@cont

	LoadB	ErrorCode, ERR_NO_NAME_SPECIFIED
	clc				; error found
	rts

@cont:	LoadB	ErrorCode, ERR_OK

	jsr	StripSP			;				[90A7]
	jsr	PadOut			;				[90CE]
	lda	ErrorCode		; error found?			[0351]
	beq	@cont2

	clc
	rts

@cont2:	CmpBI	FdcFileName, '$'	; directory wanted?
	bne	Search			;				[9011]

	jmp	DisplayDir		;				[8E67]


;**  Search for a file
Search:					;				[9011]
	LoadB	NumDirSectors, 6

	LoadB	SectorL, 7		; directory starts at sector 7
	sta	DirSector		;				[0369]
	LoadB	SectorH, 0

	jsr	SetupSector		;				[8899]
A_9024:
	LoadB	DirPointer, 0
	MoveB	StartofDir, DirPointer+1 ; normally $D0

	LoadB	NumOfSectors, 1
	asl	A			; A:=2 -> $0200 in TapeBuffer+38,9
	sta	TapeBuffer+39		;				[0363]
	LoadB	TapeBuffer+38, 0

	jsr	ReadSectors		;				[885E]

	lda	ErrorCode		; error found?			[0351]
	beq	A_9044			; no, -> continue		[9044]

	clc
	rts


; Read the directory under the $Dxxx area
A_9044:					;				[9044]
	LoadB	DirPointer, 0
	MoveB	StartofDir, DirPointer+1 ; normally $D0
; note: (DirPointer) most probably points to $D000

	ldy	#0
A_904F:					;				[904F]
	ldx	#0
	jsr	RdDataRamDxxx		;				[01A0]

	cmp	#0
	beq	A_90A0			;				[90A0]
A_9058:					;				[9058]
	jsr	RdDataRamDxxx		;				[01A0]

	iny

	cmp	#0			; end of the name in RAM found?
	beq	A_9079			; yes, ->			[9079]

	cmp	#$E5			; ???
	beq	A_9079			;				[9079]

	cmp	FdcFileName,X		; same as wanted name?		[036C]
	beq	A_9072			; yes, ->			[9072]

	lda	FdcFileName,X		;				[036C]
	cmp	#'*'			; wild card
	beq	A_9077			; yes, -> name found		[9077]
	bne	A_9079			; always ->			[9079]

A_9072:					;				[9072]
	inx
	cpx	#11			; eleven characters checked?
	bne	A_9058			; no, -> more			[9058]

; Name has been found
A_9077:					;				[9077]
	sec
	rts

A_9079:					;				[9079]
	ldy	#0

	lda	DirPointer		; next dir entry, XXX AddVB $20, DirPointer + CmpB DirPointer+1, EndofDir
	addv	$20
	sta	DirPointer		;				[FB]

	lda	DirPointer+1		;				[FC]
	adc	#0
	sta	DirPointer+1		;				[FC]

	cmp	EndofDir		; end of directory sector?	[0335]
	bne	A_904F			; no, -> more			[904F]

; Go to the next directory sector
	lda	DirSector		;				[0369]
	addv	1
	sta	SectorL			;				[F8]
	sta	DirSector		;				[0369]

	jsr	SetupSector		;				[8899]

	dec	NumDirSectors		; searched all dir sectors?	[0364]
	bpl	A_9024			; no, -> next one		[9024]
A_90A0:	
	LoadB	ErrorCode, ERR_FILE_NOT_FOUND

	clc
	rts


;**  Copy the file name to two places
StripSP:				;				[90A7]
; note: StripSP is the name according the manual but what does it mean then?
	ldy	#0
	ldx	#0

; Copy the given file name to a temporary storage
A_90AB:					;				[90AB]
	lda	(AddrFileName),Y	;				[BB]
	iny
	cmp	#' '

	bne	A_90B4			; no, ->			[90B4]
; not needed IMHO
	beq	A_90B8			; always -> skip copying	[90B8]

A_90B4:					;				[90B4]
	sta	FdcFileName,X		;				[036C]

	inx
A_90B8:					;				[90B8]
	cpy	LengthFileName		; whole name copied?		[B7]
	bne	A_90AB			; no, -> next character		[90AB]

	lda	#0
	sta	FdcFileName,X		; zero end the name		[036C]

; And copy it again
	ldy	LengthFileName		;				[B7]
; note: why? Y already had this length

A_90C3:					;				[90C3]
	lda	FdcFileName,Y		;				[036C]
	beq	A_90CD			;				[90CD]

	sta	(AddrFileName),Y	;				[BB]

	dey
	bne	A_90C3			;				[90C3]
A_90CD:					;				[90CD]
	rts


PadOut:					;				[90CE]
	ldy	#0
A_90D0:					;				[90D0]
	lda	(AddrFileName),Y	;				[BB]
	cmp	#'.'			; dot?
	beq	A_9107			; yes, -> 			[9107]

	iny
	cpy	LengthFileName		; end of the name?		[B7]
	bne	A_90D0			; no, -> next character		[90D0]

; Check if name start with '$' = directory wanted
	ldy	#0
	lda	#'$'
	cmp	(AddrFileName),Y	; yes?				[BB]
	bne	A_90E7			; no, ->			[90E7]

	sta	FdcFileName		;				[036C]

	rts

; Find the end of the name
A_90E7:					;				[90E7]
	ldy	#0
A_90E9:					;				[90E9]
	lda	FdcFileName,Y		;				[036C]
	iny
	cmp	#0			; end of the name found?
	bne	A_90E9			; no, -> next character		[90E9]

	cpy	#10			; tenth character or more?
	bcs	A_9101			; yes, -> error			[9101]

; Fill up with spaces
	dey
A_90F6:					;				[90F6]
	lda	#' '
	sta	FdcFileName,Y		;				[036C]

	iny
	cpy	#11			; ten chars done?
	bne	A_90F6			; no, -> more			[90F6]

	rts


A_9101:					;				[9101]
	LoadB	ErrorCode, ERR_NAME_TOO_LONG
	rts

; Dot found, copy extension
A_9107:					;				[9107]
	tya
	pha				; save Y

	ldx	#8
:	iny
	lda	(AddrFileName),Y	;				[BB]
	sta	FdcFileName,X		;				[036C]
	inx
	cpx	#11
	bne	:-

	pla
	tay				; restore Y
	cpy	#8
	beq	:++

; Fill up with spaces
	lda	#' '
:	sta	FdcFileName,Y		;				[036C]
	iny
	cpy	#8
	bne	:-
:	rts


SaveRloc:				;				[9127]
	lda	#$20
	jsr	OutByteChan		;				[FFD2]

	lda	#$20
	jsr	OutByteChan		;				[FFD2]

	ldy	#$1C
	ldx	#0
	sei
	jsr	RdDataRamDxxx		;				[01A0]

	iny
	sta	TapeBuffer+34		;				[035E]

	jsr	RdDataRamDxxx		;				[01A0]

	iny
	sta	TapeBuffer+35		;				[035F]

	LoadB	TapeBuffer+36, 0

	jsr	BN2DEC			;				[920E]

	ldy	#$04
	lda	#'0'
:	cmp	NumDirSectors,Y		;				[0364]
	bne	:+			;				[915C]
	dey
	bpl	:-			;				[9150]
	jsr	OutByteChan		; JMP instead of JSR+RTS	[FFD2]
	rts

:	tya
	pha
	lda	NumDirSectors,Y		;				[0364]
	jsr	OutByteChan		;				[FFD2]
	pla
	tay
	dey
	bpl	:-			;				[915C]
	rts


ShowBytesFree:				;				[916A]
	sei

	LoadW_	TapeBuffer+34, 0
	sta	TapeBuffer+36		;				[0360]

	LoadB	TapeBuffer+26, 2
	LoadB	TapeBuffer+27, 0
A_9180:					;				[9180]
	MoveW_	TapeBuffer+26, TapeBuffer+30

	jsr	GetNextCluster		;				[87A4]

	lda	TapeBuffer+30		;				[035A]
	ora	TapeBuffer+31		;				[035B]
	bne	A_919F			;				[919F]

	inc	TapeBuffer+35		;				[035F]
	bne	A_919F			;				[919F]

	inc	TapeBuffer+36		;				[0360]
A_919F:					;				[919F]
	lda	TapeBuffer+26		;				[0356]
	addv	1
	sta	TapeBuffer+26		;				[0356]

	lda	TapeBuffer+27		;				[0357]
	adc	#0
	sta	TapeBuffer+27		;				[0357]

	cmp	#2
	bne	A_9180			;				[9180]

	CmpBI	TapeBuffer+26, $CB
	bne	A_9180			;				[9180]

	asl	TapeBuffer+35		;				[035F]
	rol	TapeBuffer+36		;				[0360]
	asl	TapeBuffer+35		;				[035F]
	rol	TapeBuffer+36		;				[0360]
	jsr	BN2DEC			;				[920E]

	ldy	#0
A_91CC:					;				[91CC]
	tya				; XXX no need to preserve Y
	pha

	lda	TotalBytesFreeTxt,Y
	beq	A_91DD			;				[91DD]

	jsr	OutByteChan		;				[FFD2]

	pla
	tay
	iny
	bne	A_91CC			;				[91CC]

	beq	A_91DE			;				[91DE]
A_91DD:					;				[91DD]
	pla
A_91DE:					;				[91DE]
	ldy	#5
	lda	#'0'
:	cmp	NumDirSectors,Y		;				[0364]
	bne	:+
	dey
	bpl	:-
	jsr	OutByteChan		; JMP instead of JSR+RTS XXX	[FFD2]
	rts

:	tya
	pha
	lda	NumDirSectors,Y		;				[0364]
	jsr	OutByteChan		;				[FFD2]
	pla
	tay
	dey
	bpl	:-
	rts

 
TotalBytesFreeTxt:
.asciiz "TOTAL BYTES FREE "


BN2DEC:					;				[920E]
	ldy	#5			; start with 100000
@loop:	ldx	#0
:	lda	TapeBuffer+34		;				[035E]
	sec
	sbc	D_925A,Y		;				[925A]
	sta	TapeBuffer+34		;				[035E]

	lda	TapeBuffer+35		;				[035F]
	sbc	D_9260,Y		;				[9260]
	sta	TapeBuffer+35		;				[035F]

	lda	TapeBuffer+36		;				[0360]
	sbc	D_9266,Y		;				[9266]
	bcc	:+

	sta	TapeBuffer+36		;				[0360]
	inx
	bne	:-

; Oops, we subtracted to much. add it again
:	lda	TapeBuffer+34		;				[035E]
	clc
	adc	D_925A,Y		;				[925A]
	sta	TapeBuffer+34		;				[035E]

	lda	TapeBuffer+35		;				[035F]
	adc	D_9260,Y		;				[9260]
	sta	TapeBuffer+35		;				[035F]

	txa
	addv	'0'
	sta	NumDirSectors,Y		;				[0364]

	dey				; next multiple of ten?
	bne	@loop			; yes, ->			[9210]

	lda	TapeBuffer+34		;				[035E]
	addv	'0'
	sta	NumDirSectors,Y		;				[0364]
	rts


;** The hexadecimal values of 0, 10, 100, 1000, 10000 and 100000 in three bytes
D_925A:					;				[925A]
.byte $00, $0A, $64, $E8, $10, $A0
D_9260:					;				[9260]
.byte $00, $00, $00, $03, $27, $86
D_9266:					;				[9266]
.byte $00, $00, $00, $00, $00, $01


;**  Show an error message
ShowError:				;				[926C]
	ldx	MSGFLG			; direct mode?			[9D]
	bmi	:+			; yes, -> display error		[9271]
	rts

:	tax
	lda	TblErrorMsgL,X		;				[92DC]
	sta	DirPointer		;				[FB]
	lda	TblErrorMsgH,X		;				[92EE]
	sta	DirPointer+1		;				[FC]

	ldy	#0
	jsr	StopWatchdog		;				[8DBD]

:	lda	(DirPointer),Y		; end of message?		[FB]
	beq	@end			; yes, -> exit			[9292]
	tya
	pha
; Note: saving Y is not needed, OUTBYTECHAN does save Y
	lda	(DirPointer),Y		;				[FB]
	jsr	OutByteChan		;				[FFD2]
	pla
	tay
	iny
	jmp	:-

@end:	clc
	rts


;**  Load the File BOOT.EXE ino memory - part 1
LoadBootExe:				;				[9294]
	LoadW_	AddrFileName, BootExe
	LoadB	LengthFileName, 8

; Load address: $0801
	ldx	#<$0801
	ldy	#>$0801
	jmp	LoadBootExe2		;				[869D]


; unused, FAT volume label? but format doesn't reference it 
S_92A7:
.asciiz "T.I.B.  VOL"

; unused, ROM doesn't print this message
S_92B3:					;				[92B3]
;'T.I.B PLC DISK DRIVER INSTALLED@' in screencodes
.byte $14, $2E, $09, $2E, $02, $20, $10, $0C, $03, $20, $04, $09, $13, $0B, $20, $04, $12, $09, $16, $05, $12, $20, $09, $0E, $13, $14, $01, $0C, $0C, $05, $04, $00
 
BootExe:
.asciiz "BOOT.EXE"

.define TblErrorMsg	Msg00, Msg01, Msg02, Msg03, Msg04, Msg05, Msg06, Msg07, Msg08, Msg09, Msg0A, Msg0B, Msg0C, Msg0D, Msg0E, Msg0F, Msg10, Msg11 

TblErrorMsgL:				;				[92DC]
.lobytes TblErrorMsg

TblErrorMsgH:				;				[92EE]
.hibytes TblErrorMsg
 
Msg00:
.asciiz "OK"
Msg01:
.asciiz "DISK IS WRITE PROTECTED"
Msg02:
.asciiz "DISK IS UNUSABLE"
Msg03:
.asciiz "DISK IS NOT FORMATTED"
Msg04:
.asciiz "FILE IS CORRUPT"
Msg05:
.asciiz "FORMATING DISK"
Msg06:
.asciiz "RENAMING FILE"
Msg07:
.asciiz "SCRATCHING FILE"
Msg08:
.asciiz "ERROR DURING WRITE"
Msg09:
.asciiz "ERROR DURING READ"
Msg0A:
.asciiz "DISK MAY BE DAMAGED"
Msg0B:
.asciiz "FILE NOT FOUND"
Msg0C:
.asciiz "NO FILE EXT SPECIFIED"
Msg0D:
.asciiz "FILE TO LARGE"
Msg0E:
.asciiz "NO MORE DIRECTORY SPACE"
Msg0F:
.asciiz "DISK FOUND TO BE UNRELIABLE"
Msg10:
.asciiz "NAME TO LONG" ; XXX typo!
Msg11:
.asciiz "NO NAME SPECIFIED"
 
D_943E:					;				[943E]
; volume label? BIOS Parameter Block? (see FormatDisk)
.byte $EB, $28, $90, $43, $36, $34, $20, $50	; .(.C64 P  $943E
.byte $4E, $43, $49, $00, $02, $02, $01, $00	; NCI.....  $9446
.byte $02, $70, $00, $A0, $05, $F9, $03, $00	; .p......  $944E
.byte $09, $00, $02, $00, $00, $00, $00, $00	; ........  $9456

; unused
.byte $00, $00, $00, $00			; ....  $945E

;**  Program that is meant to run in the Stack
StackProgram:				;				[9462]
.segment "romstack"

StackPage1:				;				[0101]
.byte $00					; .  $0101
 

;**  Read a number of pages (= 256 bytes) form the floppy
; in:	256-Y bytes are read 
; Note: only used at one place and for just two pages
ReadPagesFlop:				;				[0102]
	tsx
	stx	TempStackPtr		;				[0350]
ReadPagesFlopLoop:
	ldx	#$30			; 64K RAM config		[30]
ReadPagesFlopNextByte:
:	bit	StatusRegister		; FDC ready?			[DE80]
	bpl	:-

	lda	DataRegister		; read byte			[DE81]
	stx	P6510			; 64K RAM config
	sta	(DirPointer),Y		; save byte			[FB]
	LoadB	P6510, $37		; I/O+ROM config (XXX should rather restore config from entry point)
	iny

; "#0" in the next line can be changed by the program
L_0119:					;				[0119]
	cpy	#0			; finished with reading?
	bne	ReadPagesFlopNextByte	; no, -> next byte		[0108]

	inc	DirPointer+1		;				[FC]
	dec	PageCounter		; more pages to be read?	[02]
	bpl	ReadPagesFlopLoop	; yes, ->			[0106]

	cpy	#0			; whole sector read?
	beq	@end			; yes, -> exit			[0138]
	inc	PageCounter		;				[02]

; Read the rest of the sector, FDC expects this
:	bit	StatusRegister		; FDC ready?			[DE80]
	bpl	:-			; no, -> wait			[0129]
	lda	DataRegister		; dummy read			[DE81]
	iny				; finished reading?
	bne	:-			; no, -> next byte		[0129]
	dec	PageCounter		; more pages to be read?	[02]
	bpl	:-			; yes, ->			[0129]
@end:	rts


;**  Read a number of bytes from the momentary sector
; in:	256-Y bytes are read 
; Note: RdBytesSector is only called at one place and Y = 0 there
RdBytesSector:				;				[0139]
	tsx
	stx	TempStackPtr		;				[0350]

	ldx	#$30			; 64K RAM config
:	bit	StatusRegister		; FDC ready?			[DE80]
	bpl	:-			; no, -> wait			[013F]
	lda	DataRegister		; read byte			[DE81]
	stx	P6510			; 64K RAM config
	sta	(DirPointer),Y		; store byte			[FB]
	LoadB	P6510, $37		; I/O+ROM config (XXX should rather restore config from entry point)
	iny				; finished reading?
	bne	:-			; no, -> next byte		[013F]
; Next page in RAM
	inc	DirPointer+1		;				[FC]

; Read next number of bytes. See L_0165.
RdBytesSectorByte:
:	bit	StatusRegister		; FDC ready?			[DE80]
	bpl	:-			; no, -> wait			[0154]

	lda	DataRegister		; read byte			[DE81]
	stx	P6510			; 64K RAM config		[01]
	sta	(DirPointer),Y		; store byte			[FB]
	LoadB	P6510, $37		; I/O+ROM config (XXX should rather restore config from entry point)
	iny

; "#0" in the next line can be changed by the program
L_0165:					;				[0165]
	cpy	#0			; finished with reading?
	bne	RdBytesSectorByte	; no, -> next byte		[0154]
	cpy	#0			; whole sector read? XXX? always BEQ here?
	beq	@end			; yes, -> exit			[0178]

; Read the rest of the sector, FDC expects this
:	bit	StatusRegister		; FDC ready?			[DE80]
	bpl	:-			; no, -> wait			[016D]

	lda	DataRegister		; dummy read			[DE81]
	iny				; finished reading?
	bne	:-			; no, -> next byte		[016D]
@end:	rts


;**  Write 512 bytes of data to the disk
WriteData:				;				[0179]
	tsx				; save the SP in case there is an error
	stx	TempStackPtr		;				[0350]

:	ldx	#$30			; 64 KB of RAM visible
	stx	P6510			;				[01]
	lda	(DirPointer),Y		; read byte from RAM under I/O	[FB]
	ldx	#$37
	stx	P6510			; I/O+ROM
:	bit	StatusRegister		; FDC ready?			[DE80]
	bpl	:-			; no, -> wait			[0187]
	sta	DataRegister		;				[DE81]
	iny
	bne	:--

	inc	DirPointer+1		;				[FC]
	dec	PageCounter		; two pages done?		[02]
	bpl	:--			; no, -> next 256 bytes		[017D]
	rts

; unused!
StackPage153:				;				[0199]
	LoadB	P6510, $35		; I/O+RAM only
	jmp	(J_00FE)		;				[00FE]


;**  Read one byte of data from the RAM under the $D0xx or $D2xx area
; in:	Y = location within D000/D200 area
RdDataRamDxxx:				;				[01A0]
	lda	#$30			; 64 KB of RAM visible
	stx	TempStore		; save X			[FA]

	ldx	P6510			; save original value		[01]
	sta	P6510			;				[01]

	lda	(DirPointer),Y		; read data from RAM		[FB]

	stx	P6510			; restore original value	[01]

	ldx	TempStore		; restore X			[FA]
	rts


;**  Write one byte of data to the RAM under the $D0xx or $D2xx area
; in:	Y = location within D000/D2000 area
;	A = data to be stored
WrDataRamDxxx:				;				[01AF]
	pha

	stx	TempStore		; save X; XXX txa+pha?

	ldx	P6510			; save original value		[01]

	LoadB	P6510, $30		; 64K of RAM

	pla
	sta	(DirPointer),Y		;				[FB]

	stx	P6510			; restore original value	[01]

	ldx	TempStore		; restore X			[FA]
	rts
 
.end					; End of part to assemble
 
 
