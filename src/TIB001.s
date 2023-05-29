;
;	Disassembly of the ROM of the TIB-001 FDC cartridge
;

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


.eq P6510		= $01	; DR onboard I/O port of 6510
.eq PageCounter		= $02
.eq PtrBasText		= $7A	; pointer to momentary byte in BASIC line
.eq StatusIO		= $90	; Status of KERNAL after action
.eq FlgLoadVerify	= $93	; 0 = LOAD, 1 = VERIFY
.eq MSGFLG		= $9D	; flag: $80 = direct mode, 0 = program mode
.eq EndAddrBuf		= $AE	; end of cassette / end of program
.eq LengthFileName	= $B7	; length of filename
.eq SecondAddress	= $B9	; actual secondary address
.eq DeviceNumber	= $BA	; actual device number
.eq AddrFileName	= $BB	; pointer to string with filename

; The used RS232 variabels:
.eq NumOfSectors	= $F7	; number of sectors to read or write
.eq SectorL		= $F8	; --- number of the sector that is wanted
.eq SectorH		= $F9	; -/
.eq TempStore		= $FA

.eq DirPointer		= $FB
.eq Z_FD		= $FD
.eq J_00FE		= $FE
.eq Z_FF		= $FF
.eq StackPage		= $0100
.eq NmiVector		= $0318	; pointer to NMI-interrupt ($FE47)
.eq ICKOUT		= $0320	; pointer to KERNAL CHKOUT routine
.eq ILOAD		= $0330	; pointer to KERNAL LOAD routine
.eq ISAVE		= $0332	; pointer to KERNAL SAVE routine

; $0334-$033B = original free area = 8 bytes
.eq StartofDir		= $0334
.eq EndofDir		= $0335
.eq NewICKOUT		= $0336
.eq NewNMI		= $0338


;.eq Fdc		= $034	; 

.eq TapeBuffer		= $033C	; cassette buffer
.eq FdcST0		= $033C ; Status Regiser 0
.eq FdcST1		= $033D ; Status Regiser 1
.eq FdcST2		= $033E ; Status Regiser 2
.eq FdcC		= $033F ; Cylinder
.eq FdcH		= $0340 ; Head
.eq FdcR		= $0341 ; Record = sector
.eq FdcN		= $0342 ; Number of data bytes written into a sector
.eq FdcST3		= $0343 ; Status Regiser 3
.eq FdcPCN		= $0344	; present cylinder = track
.eq FdcCommand		= $0345 ; 
.eq FdcHSEL		= $0346	; head, shifted twice, needed for FDC commands
.eq FdcTrack		= $0347	; 
.eq FdcHead		= $0348	; 
.eq FdcSector		= $0349	; 
.eq FdcNumber		= $034A	; bytes/sector during format, 2 = 512 b/s
.eq FdcEOT		= $034B	; end of track

.eq FdcTrack2		= $034E	; = FdcTrack and $FE  ???

.eq TempStackPtr	= $0350	; temporary storage for the stack pointer

.eq FdcFormatData	= $0352	; block of data used by the format command

.eq NumDirSectors	= $0364	; number of directory sectors
				; also used deteming number of free bytes
.eq Counter		= $0366

.eq DirSector		= $0369	; momentary directory sector
.eq FdcFileName		= $036C	; temp storage for file name

.eq ErrorCode		= $0351	; $0B = file not found
				; $10 = first part of name greater than 8 chars
				; $11 = no file name

.eq NewILOAD		= $03FC
.eq NewISAVE		= $03FE
.eq VICSCN		= $0400	; screenmemory


.eq BasicCold		= $A000
.eq BasicNMI		= $A002
.eq VICCTR1		= $D011	; controlregister 1
.eq VICLINE		= $D012	; line to generate IRQ
.eq ColourRAM		= $D800	; color RAM area for screen
.eq CIA1DRB		= $DC01	; data register port B
.eq CIA2TI1L		= $DD04	; low byte timer 1
.eq CIA2TI1H		= $DD05	; high byte timer 1
.eq CIA2TI2L		= $DD06	; low byte timer 2
.eq CIA2TI2H		= $DD07	; high byte timer 2
.eq CIA2IRQ		= $DD0D	; IRQ-register
.eq CIA2CRA		= $DD0E	; controlregister 1
.eq CIA2CRB		= $DD0F	; controlregister 2


; Registers for the GM82C765B
;  Note: No other address lines than A0 are used so in fact any address in its 
;        page could be used.
;        The GM82C765B is used in programmed I/O mode, thus no DMA is used.
.eq StatusRegister	= $DE80	; bit, if bit = (H) then ...
				;  0  =  FDD0 is busy
				;  1  =  FDD1 is busy
				;  2  =  FDD2 is busy
				;  3  =  FDD3 is busy
				;  4  =  read/write command in progress
				;  5  =  execution mode (non-DMA mode)
				;  6  =  data direcion, 765 => CPU
				;  7  =  data register = ready

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

.eq DataRegister	= $DE81
.eq ResetFDC		= $DF80


.eq InitScreenKeyb	= $E518
.eq IncrClock22		= $F6BC
.eq SetVectorsIO2	= $FD15
.eq TestRAM2		= $FD50
.eq InitSidCIAIrq2	= $FDA3
.eq InitialiseVIC2	= $FF5B
.eq OutByteChan		= $FFD2
.eq ScanStopKey		= $FFE1

.eq D_FFFA		= $FFFA
.eq D_FFFB		= $FFFB


.ba $8000				; Begin address of this block
S_8000:
.wo CartInit				;				[8087]
.wo CartNMI				;				[8DE7]
 
S_8004:
.by $C3, $C2, $CD, $38, $30		; CBM80, identifying code for cartridge


; ???  WHERE IS THIS JUMP TABLE USED  ???
; 1st possebility: the idea was there to use it but it never happened
; 2nd possebility: it is used by external programs
F_8009:					;				[8009]
	jmp	NewLoad			;				[86BC]

F_800C:					;				[800C]
	jmp	NewSave			;				[838A]

F_800F:					;				[800F]
	jmp	FormatDisk		;				[89DB]

F_8012:					;				[8012]
	jmp	DisplayDir		;				[8E67]

F_8015:					;				[8015]
	jmp	ReadSector		;				[8C78]

F_8018:					;				[8018]
	jmp	SetWatchdog		;				[8D90]

F_801B:					;				[801B]
	jmp	ReadSectors		;				[885E]

F_801E:					;				[801E]
	jmp	WriteSector		;				[8BEE]

F_8021:					;				[8021]
	jmp	ReadStatus		;				[8962]

F_8024:					;				[8024]
	jmp	Scratch			;				[8355]

F_8027:					;				[8027]
	jmp	Rename			;				[81C0]

F_802A:					;				[802A]
	jmp	FormatTrack		;				[8B93]

F_802D:					;				[802D]
	jmp	InitStackProg		;				[8D5A]

F_8030:					;				[8030]
	jmp	SetupSector		;				[8899]

F_8033:					;				[8033]
	jmp	Specify			;				[891A]

F_8036:					;				[8036]
	jmp	Recalibrate		;				[88F7]

F_8039:					;				[8039]
	jmp	SetSoace		;				[834B]

F_803C:					;				[803C]
	jmp	GetNextCluster		;				[87A4]

F_803F:					;				[803F]
	jmp	Enfile			;				[8684]

F_8042:					;				[8042]
	jmp	MarkFAT			;				[8534]

F_8045:					;				[8045]
	jmp	FindFAT			;				[85A8]

F_8048:					;				[8048]
	jmp	FindNextFAT		;				[85B2]

F_804B:					;				[804B]
	jmp	WriteFATs		;				[860C]

F_804E:					;				[804E]
	jmp	ClearFATs		;				[8650]

F_8051:					;				[8051]
	jmp	CalcFirst		;				[883A]

F_8054:					;				[8054]
	jmp	GetFATs			;				[8813]

F_8057:					;				[8057]
	jmp	SeekTrack		;				[898A]

F_805A:					;				[805A]
	jmp	FindFile		;				[8FEA]

F_805D:					;				[805D]
	jmp	WriteDirectory		;				[850F]

F_8060:					;				[8060]
	jmp	ReadDirectory		;				[8E0F]

F_8063:					;				[8063]
	jmp	J_8472			;				[8472]

F_8066:					;				[8066]
	jmp	SaveRloc		;				[9127]

F_8069:					;				[8069]
	jmp	ShowError		;				[926C]

F_806C:					;				[806C]
	jmp	ShowBytesFree		;				[916A]

F_806F:					;				[806F]
	jmp	BN2DEC			;				[920E]

F_8072:					;				[8072]
	jmp	StripSP			;				[90A7]

F_8075:					;				[8075]
	jmp	Search			;				[9011]

F_8078:					;				[8078]
	jmp	FindBlank		;				[8F4F]

F_807B:					;				[807B]
	jmp	PadOut			;				[90CE]

F_807E:					;				[807E]
	jmp	StopWatchdog		;				[8DBD]

F_8081:					;				[8081]
	jmp	RdDataRamDxxx		;				[01A0]

; Spare
F_8084:					;				[8084]
	jmp	$FFFF			;				[FFFF]


; Here starts the initialisation of the cartridge
CartInit:				;				[8087]
	ldx	#$FF
	txs				; set the stack pointer

	sei
	cld

	jsr	InitC64			;				[80F2]
CartInit2:				;				[808F]
	jsr	LoadBootExe		; loading went OK?		[9294]
	bcc	A_80AE			; yes, ->			[80AE]
A_8094:					;				[8094]
	lda	ErrorCode		;				[0351]
	cmp	#$0B			; file not found?
	beq	A_80A8			; yes, ->			[80A8]

	lda	#$1B			; screen on
	sta	VICCTR1			;				[D011]

	jsr	TryAgain		; another try?			[8124]
	beq	A_80A8			; no, ->			[80A8]

	jmp	CartInit2		;				[808F]

; File "BOOT.EXE" not found
A_80A8:					;				[80A8]
	jsr	InitC64			;				[80F2]

	jmp	(BasicCold)		;				[A000]

; Error found
A_80AE:					;				[80AE]
	lda	ErrorCode		; error found?			[0351]
	bne	A_8094			;				[8094]

	jmp	(EndAddrBuf)		;				[00AE]


;**  Initialize the C64 - part 2
;    Note: not used anywhere else AFAIK, so why not one routine?
InitC64_2:				;				[80B6]
	lda	#$D0
	sta	StartofDir		;				[0334]

	lda	#$D2
	sta	EndofDir		;				[0335]

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
	lda	#<NewLoad
	sta	ILOAD			;				[0330]

	lda	#>NewLoad
	sta	ILOAD+1			;				[0331]

	lda	#<NewSave
	sta	ISAVE			;				[0332]

	lda	#>NewSave
	sta	ISAVE+1			;				[0333]

	lda	#<NewCkout
	sta	ICKOUT			;				[0320]

	lda	#>NewCkout
	sta	ICKOUT+1		;				[0321]

	rts


;**  Initialize the C64 - part 1
InitC64:				;				[80F2]
	jsr	InitSidCIAIrq2		;				[FDA3]
	jsr	TestRAM2		;				[FD50]
	jsr	SetVectorsIO2		;				[FD15]
	jsr	InitialiseVIC2		;				[FF5B]

; Copy the original vectors of the LOAD and SAVE routine to another place
	ldx	#$03
A_8100:					;				[8100]
	lda	ILOAD,X			;				[0330]
	sta	NewILOAD,X		;				[03FC]

	dex
	bpl	A_8100			;				[8100]

; Copy the ICKOUT vector to another place
	lda	ICKOUT			;				[0320]
	sta	NewICKOUT		;				[0336]

	lda	ICKOUT+1		;				[0321]
	sta	NewICKOUT+1		;				[0337]

; Copy the NMI vector to another place
	lda	NmiVector		;				[0318]
	sta	NewNMI			;				[0338]

	lda	NmiVector+1		;				[0319]
	sta	NewNMI+1		;				[0339]

	jmp	InitC64_2		; part 2			[80B6]


;**  File "BOOT.EXE" has been found
TryAgain:				;				[8124]

; Clear the screen
	ldy	#0
A_8126:					;				[8126]
	lda	#$20
	sta	VICSCN,Y		;				[0400]
	sta	VICSCN+256,Y		;				[0500]
	sta	VICSCN+512,Y		;				[0600]
	sta	VICSCN+768,Y		;				[0700]

	lda	#1
	sta	ColourRAM,Y		;				[D800]

	dey
	bne	A_8126			;				[8126]

; Display two lines of text
	ldy	#0
A_813E:					;				[813E]
	lda	Text1,Y			; '@' =	zero?			[8172]
	beq	A_814F			; yes, -> stop displaying	[814F]

	sta	VICSCN+40,Y		;				[0428]

	lda	Text2,Y			;				[8199]
	sta	VICSCN+80,Y		;				[0450]

	iny
	bne	A_813E			; always ->			[813E]

A_814F:					;				[814F]
	lda	#$1B			; screen on
	sta	VICCTR1			;				[D011]

	ldx	#$64

; Wait for line 255
	lda	#$FF
A_8158:					;				[8158]
	cmp	VICLINE			;				[D012]
	bne	A_8158			;				[8158]
A_815D:					;				[815D]
	cmp	VICLINE			;				[D012]
	beq	A_815D			;				[815D]

	lda	CIA1DRB			;				[DC01]
	cmp	#$7F			; RUN/STOP key pressed?
	beq	A_8171			; yes, -> exit			[8171]

	dex				; wait longer?
	bne	A_8158			; yes, ->			[8158]

	lda	#$0B			; screen off
	sta	VICCTR1			;				[D011]
A_8171:					;				[8171]
	rts

 
Text1:					;				[8172]
.tp 'PLEASE LEAVE UNTIL C64 + DRIVE SYNC UP@'
Text2:					;				[8199]
.tp ' OR PRESS RUN/STOP IF NO DISC PRESENT @'


;**  Rename a file 
Rename:					;				[81C0]
	jsr	InitStackProg		;				[8D5A]
	jsr	WaitRasterLine		;				[8851]

	jsr	FindFile		; file found?			[8FEA]
	bcs	A_81CC			; yes, -> 

	rts

A_81CC:					;				[81CC]
	ldy	LengthFileName		;				[B7]

; ??? what is going on here ???
	lda	(AddrFileName),Y	;				[BB]
	lda	#0
	lda	#0
	clc

	cpy	TapeBuffer+89		;				[0395]
	bne	A_81DF			;				[81DF]

	lda	#$0B			; file not found
	jmp	ShowError		;				[926C]

A_81DF:					;				[81DF]
	ldx	#0
	iny
A_81E2:					;				[81E2]
	lda	(AddrFileName),Y	;				[BB]
	iny
	sta	FdcFileName,X		;				[036C]
	sta	TapeBuffer+78,X		;				[038A]

	inx
	cpx	#$0B
	bne	A_81E2			;				[81E2]

	ldy	#0
	lda	#$2E
A_81F4:					;				[81F4]
	cmp	FdcFileName,Y		;				[036C]
	beq	A_8220			;				[8220]

	iny
	cpy	#$08
	bne	A_81F4			;				[81F4]

	ldy	#0
A_8200:					;				[8200]
	lda	FdcFileName,Y		;				[036C]
	iny
	cmp	#$22
	bne	A_8200			;				[8200]

	cpy	#$0A
	bcs	A_821A			;				[821A]

	dey
A_820D:					;				[820D]
	lda	#$20
	sta	FdcFileName,Y		;				[036C]

	iny
	cpy	#$0B
	bne	A_820D			;				[820D]

	jmp	J_823C			;				[823C]

A_821A:					;				[821A]
	lda	#$10
	sta	ErrorCode		;				[0351]

	rts

A_8220:					;				[8220]
	tya
	pha

	ldx	#$08
A_8224:					;				[8224]
	iny
	lda	TapeBuffer+78,Y		;				[038A]
	sta	FdcFileName,X		;				[036C]

	inx
	cpx	#$0B
	bne	A_8224			;				[8224]

	pla
	tay
	lda	#$20
A_8234:					;				[8234]
	sta	FdcFileName,Y		;				[036C]

	iny
	cpy	#$08
	bne	A_8234			;				[8234]
J_823C:					;				[823C]
	jsr	WaitRasterLine		;				[8851]

	lda	DirPointer		;				[FB]
	pha

	lda	DirPointer+1		;				[FC]
	pha

	lda	DirSector		;				[0369]
	pha

	jsr	Search			;				[9011]

	pla
	sta	DirSector		;				[0369]

	bcs	A_8291			;				[8291]

	jsr	WaitRasterLine		;				[8851]

	lda	#0
	sta	DirPointer		;				[FB]

	lda	StartofDir		;				[0334]
	sta	DirPointer+1		;				[FC]

	lda	#1
	sta	NumOfSectors		;				[F7]

	lda	DirSector		;				[0369]
	sta	SectorL			;				[F8]

	jsr	SetWatchdog		;				[8D90]
	jsr	SetupSector		;				[8899]
	jsr	SeekTrack		;				[898A]
	jsr	ReadSectors		;				[885E]
	jsr	SetWatchdog		;				[8D90]

	pla
	sta	DirPointer+1		;				[FC]

	pla
	sta	DirPointer		;				[FB]

	ldy	#0
A_827E:					;				[827E]
	lda	FdcFileName,Y		;				[036C]
	jsr	WrDataRamDxxx		;				[01AF]

	iny
	cpy	#$0B
	bne	A_827E			;				[827E]

	jsr	WaitRasterLine		;				[8851]
	jsr	WriteDirectory		;				[850F]

	clc
	rts

A_8291:					;				[8291]
	sec
	pla
	pla
	rts


;**  New routine for opening a channel for output
NewCkout:				;				[8295]
	pha

	lda	DeviceNumber		;				[BA]
	cmp	#9			; our DD drive?
	beq	A_82A1			; yes, ->			[82A1]

	pla
	jmp	(TapeBuffer+188)	; = ($03F8)			[03F8]
; ??? where is this vector filled ???
; I would expect (NewICKOUT) = ($0336)
 

; Not used
S_82A0:
	rti
 
 
A_82A1:					;				[82A1]
	sei
	tya
	pha

	txa
	pha

	ldy	#0
	lda	(PtrBasText),Y		;				[7A]
	cmp	#'"'			; quote found?
	bne	J_8307			; no, ->			[8307]

	iny

; Save current Y
	tya
	pha

; Check if the string between the quotes is not too long
A_82B1:					;				[82B1]
	lda	(PtrBasText),Y		;				[7A]
	iny
	cpy	#$21			; 33 or more characters?
	bcs	A_82D8			; yes, -> exit			[82D8]

	cmp	#'"'			; quote found?
	bne	A_82B1			; no, ->			[82B1]

; Restore original Y
	pla
	tay

	lda	(PtrBasText),Y		;				[7A]
	cmp	#'S'			; 'S' ?
	bne	A_82DD			; no, -> next possible char	[82DD]

; Handle as SCRATCH
	lda	PtrBasText		;				[7A]
	clc
	adc	#$03
	sta	AddrFileName		;				[BB]

	lda	PtrBasText+1		;				[7B]
	sta	AddrFileName+1		;				[BC]

	jsr	GetlengthFName		;				[8336]
	jsr	Scratch			;				[8355]

	jmp	J_8307			;				[8307]

A_82D8:					;				[82D8]
	pla
	sec
	jmp	J_8307			;				[8307]

; Handle as RENAME
A_82DD:					;				[82DD]
	cmp	#'R'			; 'R' ?
	bne	A_82F5			; no, -> next possible char	[82F5]

	lda	PtrBasText		;				[7A]
	clc
	adc	#$03
	sta	AddrFileName		;				[BB]

	lda	PtrBasText+1		;				[7B]
	sta	AddrFileName+1		;				[BC]

	jsr	P_831A			;				[831A]
	jsr	Rename			;				[81C0]

	jmp	J_8307			;				[8307]

; Handle as NEW = format disk
A_82F5:					;				[82F5]
	cmp	#'N'			; 'N' ?
	bne	J_8307			; no, -> exit			[8307]

	lda	PtrBasText		;				[7A]
	clc
	adc	#$03
	sta	AddrFileName		;				[BB]

	lda	PtrBasText+1		;				[7B]
	sta	AddrFileName+1		;				[BC]

	jsr	FormatDisk		;				[89DB]
J_8307:					;				[8307]
	php

	lda	ErrorCode		;				[0351]
	jsr	ShowError		;				[926C]

	lda	#$1B			; screen on
	sta	VICCTR1			;				[D011]

	plp

	pla
	tax

	pla
	tay

	pla

	rts



P_831A:					;				[831A]
	ldy	#0
A_831C:					;				[831C]
	lda	(AddrFileName),Y	;				[BB]
	cmp	#$3D
	beq	A_8325			;				[8325]

	iny
	bne	A_831C			;				[831C]
A_8325:					;				[8325]
	tya
	sty	LengthFileName		;				[B7]

	tya
	pha

	jsr	GetlengthFName		;				[8336]

	lda	LengthFileName		;				[B7]
	sta	TapeBuffer+89		;				[0395]

	pla
	sta	LengthFileName		;				[B7]

	rts


;**  Get the length of the file name between the quotes
GetlengthFName:				;				[8336]
	ldy	#1

; Look for a quote
A_8338:					;				[8338]
	lda	(PtrBasText),Y		;				[7A]
	cmp	#'"'			; quote found?
	beq	A_8341			; yes, ->			[8341]

	iny
	bne	A_8338			; always ->
; Note: length has already been checked. Therefore "always".

A_8341:					;				[8341]
	tya

	iny
	sty	LengthFileName		;				[B7]

	clc
	adc	PtrBasText		;				[7A]
	sta	PtrBasText		;				[7A]

	rts


SetSoace:				;				[834B]
	sta	StartofDir		;				[0334]

	clc
	adc	#2
	sta	EndofDir		;				[0335]

	rts


;**  Scratch a file
Scratch:				;				[8355]
	jsr	InitStackProg		;				[8D5A]

	jsr	FindFile		; file found?			[8FEA]
	bcs	A_8363			; yes, ->			[8363]

	lda	#$0B			; file not found
	sta	ErrorCode		;				[0351]

	rts

A_8363:					;				[8363]
	ldy	#0
	lda	#$E5			; means: file has been deleted
	jsr	WrDataRamDxxx		;				[01AF]
; Note: MS-DOS saves the first character

	lda	DirPointer		;				[FB]
	pha

	lda	DirPointer+1		;				[FC]
	pha

	jsr	WaitRasterLine		;				[8851]
	jsr	WriteDirectory		;				[850F]
	jsr	GetFATs			;				[8813]
	jsr	WaitRasterLine		;				[8851]

	pla
	sta	DirPointer+1		;				[FC]

	pla
	sta	DirPointer		;				[FB]

	jsr	ClearFATs		;				[8650]
	jsr	WriteFATs		;				[860C]

	clc
	rts


;**  Routine that replaces original SAVE routine of C64
NewSave:				;				[838A]
	sei
	stx	TapeBuffer+43		;				[0367]

	lda	DeviceNumber		;				[BA]
	cmp	#9
	beq	A_8397			;				[8397]

	jmp	(NewISAVE)		;				[03FE]

A_8397:					;				[8397]
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
	bcs	A_83B6			; yes, ->			[83B6]

; File too large
	lda	#$0D
	jsr	ShowError		;				[926C]

	lda	#$1B			; screen on
	sta	VICCTR1			;				[D011]

	rts

A_83B6:					;				[83B6]
	lsr	NumDirSectors		;				[0364]
	lsr	NumDirSectors		;				[0364]
	inc	NumDirSectors		;				[0364]

	lda	NumDirSectors		;				[0364]
	sta	TapeBuffer+44		;				[0368]

	jsr	InitStackProg		;				[8D5A]

	lda	FdcST3			;				[0343]
	and	#$40
	beq	A_83D7			;				[83D7]

	lda	#1
	sta	ErrorCode		;				[0351]

	jmp	ShowError		;				[926C]

A_83D7:					;				[83D7]
	jsr	GetFATs			;				[8813]
	jsr	FindFile		;				[8FEA]

	bcs	A_83F2			;				[83F2]

	lda	ErrorCode		;				[0351]
	cmp	#$0B
	beq	A_8407			;				[8407]

	lda	ErrorCode		;				[0351]
	jsr	ShowError		;				[926C]

	lda	#$1B			; screen on
	sta	VICCTR1			;				[D011]

	rts

A_83F2:					;				[83F2]
	jsr	StopWatchdog		;				[8DBD]

	lda	DirPointer		;				[FB]
	pha

	lda	DirPointer+1		;				[FC]
	pha

	jsr	ClearFATs		;				[8650]

	pla
	sta	DirPointer+1		;				[FC]

	pla
	sta	DirPointer		;				[FB]

	jmp	J_8418			;				[8418]

A_8407:					;				[8407]
	jsr	FindBlank		;				[8F4F]

	lda	ErrorCode		; error found?			[0351]
	beq	J_8418			;				[8418]

	jsr	ShowError		;				[926C]

	lda	#$1B			; screen on
	sta	VICCTR1			;				[D011]

	rts

J_8418:					;				[8418]
	jsr	StopWatchdog		;				[8DBD]

	lda	DirPointer+1		;				[FC]
	pha

	lda	DirPointer		;				[FB]
	pha

	ldx	#0
	jsr	FindFAT			;				[85A8]

	pla
	sta	DirPointer		;				[FB]

	pla
	sta	DirPointer+1		;				[FC]

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
J_8472:					;				[8472]
	lda	#1
	sta	TapeBuffer+41		;				[0365]

	lda	TapeBuffer+44		;				[0368]
	sta	NumDirSectors		;				[0364]
J_847D:					;				[847D]
	jsr	SeekTrack		;				[898A]

	lda	#0
	sta	ErrorCode		;				[0351]

	jsr	WaitRasterLine		;				[8851]

	ldx	TapeBuffer+43		;				[0367]
	lda	$00,X			;				[00]
	sta	DirPointer		;				[FB]

	lda	$01,X			;				[01]
	sta	DirPointer+1		;				[FC]
J_8493:					;				[8493]
	jsr	CalcFirst		;				[883A]

	lda	TapeBuffer+30		;				[035A]
	sta	TapeBuffer+28		;				[0358]

	lda	TapeBuffer+31		;				[035B]
	sta	TapeBuffer+29		;				[0359]

	jsr	SetupSector		;				[8899]
	jsr	Delay41ms		;				[89D0]
	jsr	SeekTrack		;				[898A]

	lda	#2
	sta	NumOfSectors		;				[F7]

	jsr	SetWatchdog		;				[8D90]
	jsr	WriteSector		;				[8BEE]
	jsr	StopWatchdog		;				[8DBD]

	lda	ErrorCode		; error found?			[0351]
	bne	A_8506			;				[8506]

	dec	NumDirSectors		;				[0364]
	beq	A_84E5			;				[84E5]

	lda	DirPointer		;				[FB]
	pha

	lda	DirPointer+1		;				[FC]
	pha

	ldx	#1
	jsr	FindNextFAT		;				[85B2]

	bcs	A_84D9			;				[84D9]

	pla
	pla
	lda	#$0D
	sta	ErrorCode		;				[0351]

	jmp	J_84F1			;				[84F1]

A_84D9:					;				[84D9]
	jsr	MarkFAT			;				[8534]

	pla
	sta	DirPointer+1		;				[FC]

	pla
	sta	DirPointer		;				[FB]

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

	lda	#$1B			; screen on
	sta	VICCTR1			;				[D011]

	cli
	lda	#0
	sta	StatusIO		;				[90]

	clc
	rts

A_8506:					;				[8506]
	jsr	Specify			;				[891A]
	jsr	Recalibrate		;				[88F7]

	jmp	J_847D			;				[847D]

WriteDirectory:				;				[850F]
	lda	#1
	sta	NumOfSectors		;				[F7]

	lda	StartofDir		;				[0334]
	sta	DirPointer+1		;				[FC]

	lda	#0
	sta	DirPointer		;				[FB]

	lda	DirSector		;				[0369]
	sta	SectorL			;				[F8]

	lda	#0
	sta	SectorH			;				[F9]

	jsr	SetupSector		;				[8899]
	jsr	SeekTrack		;				[898A]
	jsr	SetWatchdog		;				[8D90]
	jsr	WriteSector		;				[8BEE]

	jmp	StopWatchdog		;				[8DBD]

MarkFAT:				;				[8534]
	lda	TapeBuffer+29		;				[0359]
	sta	TempStore		;				[FA]

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

	lda	TapeBuffer+28		;				[0358]
	sta	DirPointer		;				[FB]

	lda	TapeBuffer+29		;				[0359]
	adc	EndofDir		;				[0335]
	sta	DirPointer+1		;				[FC]

	pla
	and	#1
	bne	A_857B			;				[857B]

	ldy	#0
	lda	TapeBuffer+26		;				[0356]
	jsr	WrDataRamDxxx		;				[01AF]

	iny
	jsr	RdDataRamDxxx		;				[01A0]

	and	#$F0
	ora	TapeBuffer+27		;				[0357]
	jsr	WrDataRamDxxx		;				[01AF]

	rts

A_857B:					;				[857B]
	ldy	#1
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
	lda	#2
	sta	TapeBuffer+26		;				[0356]

	lda	#0
	sta	TapeBuffer+27		;				[0357]
FindNextFAT:				;				[85B2]
	lda	TapeBuffer+26		;				[0356]
	sta	TapeBuffer+30		;				[035A]

	lda	TapeBuffer+27		;				[0357]
	sta	TapeBuffer+31		;				[035B]

	jsr	GetNextCluster		;				[87A4]

	lda	TapeBuffer+30		;				[035A]
	ora	TapeBuffer+31		;				[035B]
	beq	A_85E7			;				[85E7]

	lda	TapeBuffer+26		;				[0356]
	clc
	adc	#1
	sta	TapeBuffer+26		;				[0356]

	lda	TapeBuffer+27		;				[0357]
	adc	#0
	sta	TapeBuffer+27		;				[0357]

	cmp	#2
	bne	FindNextFAT		;				[85B2]

	lda	TapeBuffer+26		;				[0356]
	cmp	#$CA
	bne	FindNextFAT		;				[85B2]

	clc
	rts

A_85E7:					;				[85E7]
	lda	TapeBuffer+26		;				[0356]
	sta	TapeBuffer+30		;				[035A]

	lda	TapeBuffer+27		;				[0357]
	sta	TapeBuffer+31		;				[035B]

	dex
	bmi	A_860A			;				[860A]

	lda	TapeBuffer+26		;				[0356]
	clc
	adc	#1
	sta	TapeBuffer+26		;				[0356]

	lda	TapeBuffer+27		;				[0357]
	adc	#0
	sta	TapeBuffer+27		;				[0357]

	jmp	FindNextFAT		;				[85B2]

A_860A:					;				[860A]
	sec
	rts

WriteFATs:				;				[860C]
	lda	#$03
	sta	NumOfSectors		;				[F7]

	lda	EndofDir		;				[0335]
	sta	DirPointer+1		;				[FC]

	lda	#0
	sta	DirPointer		;				[FB]

	lda	#1
	sta	SectorL			;				[F8]

	lda	#0
	sta	SectorH			;				[F9]

	jsr	SetupSector		;				[8899]
	jsr	SeekTrack		;				[898A]
	jsr	SetWatchdog		;				[8D90]
	jsr	WriteSector		;				[8BEE]
	jsr	StopWatchdog		;				[8DBD]

	lda	EndofDir		;				[0335]
	sta	DirPointer+1		;				[FC]

	lda	#0
	sta	DirPointer		;				[FB]

	lda	#$03
	sta	NumOfSectors		;				[F7]

	lda	#$04
	sta	SectorL			;				[F8]

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

	lda	#0
	sta	TapeBuffer+26		;				[0356]
	sta	TapeBuffer+27		;				[0357]
A_866D:					;				[866D]
	jsr	GetNextCluster		;				[87A4]
	jsr	MarkFAT			;				[8534]

	lda	TapeBuffer+30		;				[035A]
	sta	TapeBuffer+28		;				[0358]

	lda	TapeBuffer+31		;				[035B]
	sta	TapeBuffer+29		;				[0359]

	cmp	#$0F
	bne	A_866D			;				[866D]

	rts

Enfile:					;				[8684]
	lda	TapeBuffer+30		;				[035A]
	sta	TapeBuffer+28		;				[0358]

	lda	TapeBuffer+31		;				[035B]
	sta	TapeBuffer+29		;				[0359]

	lda	#$FF
	sta	TapeBuffer+26		;				[0356]

	lda	#$0F
	sta	TapeBuffer+27		;				[0357]

	jmp	MarkFAT			;				[8534]


;**  Load the File BOOT.EXE ino memory - part 2
;    Note: not used anywhere else AFAIK, so why not one routine?
LoadBootExe2:				;				[869D]
	sei

	stx	EndAddrBuf		;				[AE]
	sty	EndAddrBuf+1		;				[AF]

	lda	#$FF
	sta	SecondAddress		;				[B9]

	jsr	InitStackProg		;				[8D5A]

	jsr	FindFile		; File found?			[8FEA]
	bcc	A_86B4			; no, ->			[86B4]

	lda	VICCTR1			;				[D011]
	pha

	bcs	A_86EB			; always ->			[86EB]

A_86B4:					;				[86B4]
	sec

	lda	#0
	sta	SecondAddress		;				[B9]
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

	lda	DeviceNumber		;				[BA]
	cmp	#9
	beq	A_86CC			;				[86CC]

	pla
	jmp	(NewILOAD)		;				[03FC]

A_86CC:					;				[86CC]
	pla
; ??? is VERIFY ignored ???

	lda	VICCTR1			;				[D011]
	pha

	jsr	InitStackProg		;				[8D5A]
	jsr	FindFile		;				[8FEA]

	bcs	A_86EB			;				[86EB]

	pla
	and	#$7F
	sta	VICCTR1			;				[D011]

	lda	ErrorCode		;				[0351]
	jsr	ShowError		;				[926C]

	lda	#$1B			; screen on
	sta	VICCTR1			;				[D011]

	rts


; File found
A_86EB:					;				[86EB]
	ldy	#$10
	jsr	RdDataRamDxxx		;				[01A0]

	iny
	sta	TapeBuffer+47		;				[036B]

	jsr	RdDataRamDxxx		;				[01A0]

	iny
	sta	TapeBuffer+46		;				[036A]

	ldy	#$1A
	jsr	RdDataRamDxxx		;				[01A0]

	iny
	sta	TapeBuffer+30		;				[035A]

	jsr	RdDataRamDxxx		;				[01A0]

	iny
	sta	TapeBuffer+31		;				[035B]

	jsr	RdDataRamDxxx		;				[01A0]

	iny
	sta	TapeBuffer+37		;				[0361]

	jsr	RdDataRamDxxx		;				[01A0]

	iny

	sta	TapeBuffer+36		;				[0360]

	jsr	RdDataRamDxxx		;				[01A0]

	iny
	sta	TapeBuffer+35		;				[035F]

	jsr	RdDataRamDxxx		;				[01A0]

	iny
	sta	TapeBuffer+34		;				[035E]

	jsr	GetFATs			;				[8813]
	jsr	CalcFirst		;				[883A]

	lda	TapeBuffer+37		;				[0361]
	sta	TapeBuffer+38		;				[0362]

	lda	TapeBuffer+36		;				[0360]
	sta	TapeBuffer+39		;				[0363]

	lda	SecondAddress		;				[B9]
	beq	A_8747			;				[8747]

	lda	TapeBuffer+46		;				[036A]
	sta	EndAddrBuf		;				[AE]

	lda	TapeBuffer+47		;				[036B]
	sta	EndAddrBuf+1		;				[AF]
A_8747:					;				[8747]
	lda	EndAddrBuf		;				[AE]
	sta	DirPointer		;				[FB]

	lda	EndAddrBuf+1		;				[AF]
	sta	DirPointer+1		;				[FC]
J_874F:					;				[874F]
	lda	#2
	sta	NumOfSectors		;				[F7]

	jsr	SetupSector		;				[8899]
	jsr	SeekTrack		;				[898A]

	lda	#2
	sta	NumOfSectors		;				[F7]

	jsr	ReadSectors		;				[885E]

	lda	DirPointer		;				[FB]
	pha

	lda	DirPointer+1		;				[FC]
	pha

	jsr	GetNextCluster		;				[87A4]

	pla
	sta	DirPointer+1		;				[FC]

	pla
	sta	DirPointer		;				[FB]

	lda	TapeBuffer+31		;				[035B]
	cmp	#$0F
	beq	A_877C			;				[877C]

	jsr	CalcFirst		;				[883A]

	jmp	J_874F			;				[874F]

A_877C:					;				[877C]
	lda	EndAddrBuf		;				[AE]
	clc
	adc	TapeBuffer+37		;				[0361]
	tax

	lda	EndAddrBuf+1		;				[AF]
	adc	TapeBuffer+36		;				[0360]
	tay

	cli

	lda	#0
	sta	StatusIO		;				[90]

	pla
	and	#$7F
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
	lda	TapeBuffer+31		;				[035B]
	sta	TapeBuffer+33		;				[035D]

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
	bne	A_87E5			;				[87E5]

	ldy	#0
	jsr	RdDataRamDxxx		;				[01A0]

	iny
	sta	TapeBuffer+30		;				[035A]

	jsr	RdDataRamDxxx		;				[01A0]

	and	#$0F
	sta	TapeBuffer+31		;				[035B]

	rts

A_87E5:					;				[87E5]
	ldy	#1
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
	lda	#0
	sta	DirPointer		;				[FB]

	lda	EndofDir		; $D2 IMHO			[0335]
	sta	DirPointer+1		;				[FC]

	lda	#1
	sta	SectorL			;				[F8]

	lda	#0
	sta	SectorH			;				[F9]

	jsr	SetupSector		;				[8899]

	lda	#0
	sta	TapeBuffer+38		;				[0362]

	lda	#$03
	sta	NumOfSectors		;				[F7]

	asl	A			; A := 6
	sta	TapeBuffer+39		;				[0363]

	jsr	ReadSectors		;				[885E]
	jmp	StopWatchdog		;				[8DBD]


CalcFirst:				;				[883A]
	lda	TapeBuffer+31		;				[035B]
	sta	SectorH			;				[F9]

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
	lda	#$0B			; screen off
	sta	VICCTR1			;				[D011]
A_8856:					;				[8856]
	lda	VICLINE			; read rasterline bit 00.7	[D012]
	cmp	#$FF			; = 255?
	bne	A_8856			; no, -> wait			[8856]

	rts


;**  Read multiple sectors
; IMHO it reads 9 sectors = a complete track of one side
ReadSectors:				;				[885E]
	lda	#0
	sta	Counter			;				[0366]
A_8863:					;				[8863]
	lda	#0
	sta	ErrorCode		;				[0351]

	jsr	WaitRasterLine		;				[8851]
	jsr	SetWatchdog		;				[8D90]
	jsr	ReadSector		;				[8C78]

	lda	Counter			;				[0366]
	cmp	#9
	bne	A_887F			;				[887F]

	lda	#10
	sta	ErrorCode		;				[0351]
	bne	A_8887			; always ->

A_887F:					;				[887F]
	inc	Counter			;				[0366]

	lda	ErrorCode		; error found?			[0351]
	bne	A_888A			; yes, -> 			[888A]
A_8887:					;				[8887]
	jmp	StopWatchdog		;				[8DBD]

A_888A:					;				[888A]
	jsr	Delay41ms		;				[89D0]
	jsr	Specify			;				[891A]
	jsr	Recalibrate		;				[88F7]
	jsr	SeekTrack		;				[898A]

	jmp	A_8863			;				[8863]


;**  Setup the data needed for the FDC
SetupSector:				;				[8899]
	lda	SectorH			;				[F9]
	cmp	#5
	bcc	A_88A5			;				[88A5]

	lda	SectorL			;				[F8]
	cmp	#$A0
	bcs	A_88E0			;				[88E0]
; FYI: 5*256 + 160 = 1440 = number of sectors on 3.5" 720 KB disk

; BUG: if (SectorH > 5) and SectorL < 160) then routine continues as well


; Convert sector to track
A_88A5:					;				[88A5]
	ldx	#0
	ldy	#0
A_88A9:					;				[88A9]
	lda	SectorL			;				[F8]
	sec
	sbc	#9
	sta	SectorL			;				[F8]

	inx
	bcs	A_88A9			; if SectorL > 8 then repeat	[88A9]

	lda	SectorH			;				[F9]
	sbc	#0
	sta	SectorH			;				[F9]

	bcs	A_88A9			; if SectorH > 0 then repeat	[88A9]

	dex

; Correct last subtraction
	lda	SectorL			;				[F8]
	clc
	adc	#10			; one extra because FDC counts 1..9
	sta	SectorL			;				[F8]
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
A_88E0:					;				[88E0]
	rts


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

	lda	#$07
	sta	DataRegister		;				[DE81]

	jsr	Wait4DataReady		;				[89C8]

	lda	#0			; drive 0
	sta	DataRegister		;				[DE81]
A_8907:					;				[8907]
	jsr	SenseIrqStatus		;				[894A]

	lda	FdcST0			;				[033C]
	and	#$20			; command completed?
	beq	A_8907			; no, ->			[8907]

	lda	FdcPCN			; track = 0?			[0344]
	bne	A_8907			; no, -> wait			[8907]

	jsr	SenseDrvStatus		;				[8933]

	rts


;**  Set some values, head moves to track 0
Specify:				;				[891A]
	jsr	Wait4FdcReady		;				[89C0]

	lda	#$03
	sta	DataRegister		;				[DE81]

	jsr	Wait4DataReady		;				[89C8]

	lda	#$EF			; step rate time, E = 2 ms.
					; head unload time, F = 240 ms.
	sta	DataRegister		;				[DE81]

	jsr	Wait4DataReady		;				[89C8]

	lda	#1			; head load time, 0 = 2 ms.
					; 1 = set "no DMA mode"
	sta	DataRegister		;				[DE81]

	rts


;**  Sense the status of the drive
SenseDrvStatus:				;				[8933]
	lda	#$04
	sta	DataRegister		;				[DE81]

	jsr	Wait4DataReady		;				[89C8]

	lda	#0			; select drive 0
					; head select = 0
	sta	DataRegister		;				[DE81]

	jsr	Wait4DataReady		;				[89C8]

	lda	DataRegister		;				[DE81]
	sta	FdcST3			;				[0343]

	rts


;**  Sense the status of the interrupt
SenseIrqStatus:				;				[894A]
	lda	#$08
	sta	DataRegister		;				[DE81]

	jsr	Wait4DataReady		;				[89C8]

	lda	DataRegister		; read ST0			[DE81]
	sta	FdcST0			;				[033C]

	jsr	Wait4DataReady		;				[89C8]

	lda	DataRegister		;				[DE81]
	sta	FdcPCN			; present cyliner		[0344]

	rts


;**  Read seven bytes from the results after a command
ReadStatus:				;				[8962]
	ldy	#0
	ldx	#0			; try counter
A_8966:					;				[8966]
	lda	StatusRegister		;				[DE80]
	and	#$20
	bne	A_8966			;				[8966]

	dex				; 256 tries done?
	beq	A_8988			; yes, -> error			[8988]

	lda	StatusRegister		;				[DE80]
	and	#$C0
	cmp	#$C0			; FDC ready?
	bne	A_8966			; no, -> wait			[8966]

	lda	DataRegister		;				[DE81]
	sta	FdcST0,Y		;				[033C]

	ldx	#0
	iny
	cpy	#7			; seven bytes read?
	bne	A_8966			; no, -> more			[8966]

	clc
	rts

A_8988:					;				[8988]
	sec				; error
	rts


;**  Seek a track
SeekTrack:				;				[898A]
	lda	#$0F
	sta	DataRegister		;				[DE81]

	jsr	Wait4DataReady		;				[89C8]

	lda	FdcHSEL			;				[0346]
	sta	DataRegister		;				[DE81]

	jsr	Wait4DataReady		;				[89C8]

	lda	FdcTrack		;				[0347]
	sta	DataRegister		;				[DE81]

	jsr	Wait4DataReady		;				[89C8]
A_89A4:					;				[89A4]
	jsr	SenseIrqStatus		;				[894A]

	lda	FdcST0			;				[033C]
	lda	FdcST0			; why twice ???			[033C]
	and	#$20			; command completed?
	beq	A_89A4			; no, -> wait			[89A4]

	lda	FdcPCN			; present track			[0344]
	cmp	FdcTrack		; same track?			[0347]
	beq	A_89BF			; yes, -> exit			[89BF]

	jsr	Recalibrate		;				[88F7]
	jmp	SeekTrack		;				[898A]

A_89BF:					;				[89BF]
	rts


;**  Wait until the FDC is ready
Wait4FdcReady:				;				[89C0]
	lda	StatusRegister		;				[DE80]
	and	#$1F			; FDC is busy?
	bne	Wait4FdcReady		; yes, -> wait			[89C0]

	rts


;**  Wait until the data register is ready
Wait4DataReady:				;				[89C8]
	lda	StatusRegister		;				[DE80]
	and	#$80			; FDC ready?
	beq	Wait4DataReady		; no, -> wait			[89C8]

	rts


;**  Delay, roughly for 41 ms.
Delay41ms:				;				[89D0]
	ldx	#$C8
	ldy	#$28
A_89D4:					;				[89D4]
	dex
	bne	A_89D4			;				[89D4]

	dey
	bne	A_89D4			;				[89D4]

	rts



FormatDisk:				;				[89DB]
	sei
	jsr	WaitRasterLine		;				[8851]

	ldy	#0
A_89E1:					;				[89E1]
	lda	(AddrFileName),Y	;				[BB]
	cmp	#$22
	beq	A_89F1			;				[89F1]

	sta	FdcFileName,Y		;				[036C]

	iny
	cpy	#$0B
	bne	A_89E1			;				[89E1]

	sec
	rts

A_89F1:					;				[89F1]
	cpy	#$0B
	beq	A_89FD			;				[89FD]

	lda	#$20
	sta	FdcFileName,Y		;				[036C]

	iny
	bne	A_89F1			;				[89F1]
A_89FD:					;				[89FD]
	jsr	GetlengthFName		;				[8336]
	jsr	InitStackProg		;				[8D5A]

	lda	FdcST3			;				[0343]
	and	#$40
	beq	A_8A0F			;				[8A0F]

	lda	#1
	jmp	ShowError		;				[926C]

A_8A0F:					;				[8A0F]
	ldx	#$0F
	jsr	P_8B30			;				[8B30]

	lda	#0
	sta	FdcTrack2		;				[034E]

	lda	#1
	sta	Counter			;				[0366]
J_8A1E:					;				[8A1E]
	lda	#0
	sta	ErrorCode		;				[0351]

	lda	FdcTrack2		;				[034E]
	lsr	A
	sta	FdcTrack		;				[0347]

	lda	FdcTrack2		;				[034E]
	and	#1
	sta	FdcHead			;				[0348]

	asl	A
	asl	A
	sta	FdcHSEL			;				[0346]

	lda	#2
	sta	FdcNumber		;				[034A]

	lda	#1
	sta	FdcSector		;				[0349]

	jsr	SeekTrack		;				[898A]
	jsr	FormatTrack		;				[8B93]

	lda	ErrorCode		; error found?			[0351]
	beq	A_8A4F			;				[8A4F]
A_8A4C:					;				[8A4C]
	jmp	J_8B10			;				[8B10]

A_8A4F:					;				[8A4F]
	jsr	SetWatchdog		;				[8D90]
	jsr	P_8B49			;				[8B49]

	bcs	A_8A4C			;				[8A4C]

	lda	ErrorCode		; error found?			[0351]
	beq	A_8A5F			;				[8A5F]

	jmp	J_8B10			;				[8B10]

A_8A5F:					;				[8A5F]
	jsr	StopWatchdog		;				[8DBD]

	inc	FdcTrack2		;				[034E]
	lda	#1
	sta	Counter			;				[0366]

	lda	FdcTrack		;				[0347]
	cmp	#$50
	bne	J_8A1E			;				[8A1E]

	lda	#0
	sta	DirPointer		;				[FB]

	lda	StartofDir		;				[0334]
	sta	DirPointer+1		;				[FC]

	ldy	#0
A_8A7C:					;				[8A7C]
	lda	D_943E,Y		;				[943E]
	jsr	WrDataRamDxxx		;				[01AF]

	iny
	cpy	#$20
	bne	A_8A7C			;				[8A7C]

	lda	EndofDir		;				[0335]
	sta	DirPointer+1		;				[FC]

	lda	#$F9
	ldy	#0
	jsr	WrDataRamDxxx		;				[01AF]

	iny
	lda	#$FF
	jsr	WrDataRamDxxx		;				[01AF]

	iny
	lda	#$FF
	jsr	WrDataRamDxxx		;				[01AF]

	lda	#$D8
	sta	DirPointer+1		;				[FC]

	lda	#$F9
	ldy	#0
	jsr	WrDataRamDxxx		;				[01AF]

	iny
	lda	#$FF
	jsr	WrDataRamDxxx		;				[01AF]

	iny
	lda	#$FF
	jsr	WrDataRamDxxx		;				[01AF]

	lda	#$08
	sta	NumOfSectors		;				[F7]

	lda	#0
	sta	SectorL			;				[F8]

	lda	#0
	sta	SectorH			;				[F9]

	jsr	SetupSector		;				[8899]
	jsr	SeekTrack		;				[898A]
	jsr	SetWatchdog		;				[8D90]

	lda	StartofDir		;				[0334]
	sta	DirPointer+1		;				[FC]

	jsr	WriteSector		;				[8BEE]
	jsr	StopWatchdog		;				[8DBD]

	ldx	#1
	jsr	P_8B30			;				[8B30]

	lda	StartofDir		;				[0334]
	sta	DirPointer+1		;				[FC]

	ldx	#0
	ldy	#0
A_8AE4:					;				[8AE4]
	lda	FdcFileName,X		;				[036C]
	inx
	jsr	WrDataRamDxxx		;				[01AF]

	iny
	cpy	#$0B
	bne	A_8AE4			;				[8AE4]

	lda	#$08
	jsr	WrDataRamDxxx		;				[01AF]

	lda	#$07
	sta	SectorL			;				[F8]

	jsr	SetupSector		;				[8899]

	lda	#1
	sta	NumOfSectors		;				[F7]

	jsr	SetWatchdog		;				[8D90]
	jsr	WriteSector		;				[8BEE]
	jsr	StopWatchdog		;				[8DBD]

	lda	#$1B			; screen on
	sta	VICCTR1			;				[D011]

	clc
	rts

J_8B10:					;				[8B10]
	dec	Counter			;				[0366]
	bpl	A_8B24			;				[8B24]

	lda	#$0F
	sta	ErrorCode		;				[0351]

	jsr	ShowError		;				[926C]

	lda	#$1B			; screen on
	sta	VICCTR1			;				[D011]

	clc
	rts

A_8B24:					;				[8B24]
	jsr	StopWatchdog		;				[8DBD]
	jsr	Specify			;				[891A]
	jsr	Recalibrate		;				[88F7]

	jmp	J_8A1E			;				[8A1E]

P_8B30:					;				[8B30]
	lda	#0
	sta	DirPointer		;				[FB]

	lda	StartofDir		;				[0334]
	sta	DirPointer+1		;				[FC]

	lda	#0
	ldy	#0
A_8B3D:					;				[8B3D]
	jsr	WrDataRamDxxx		;				[01AF]

	iny
	bne	A_8B3D			;				[8B3D]

	inc	DirPointer+1		;				[FC]
	dex
	bpl	A_8B3D			;				[8B3D]

	rts

P_8B49:					;				[8B49]
	tsx
	stx	TempStackPtr		;				[0350]

	lda	#0
	sta	ErrorCode		;				[0351]

	lda	#$66
	sta	FdcCommand		;				[0345]

	lda	#9
	sta	FdcEOT			;				[034B]

	lda	#1
	sta	FdcSector		;				[0349]

	ldy	#0
A_8B63:					;				[8B63]
	lda	StatusRegister		;				[DE80]
	and	#$80
	beq	A_8B63			;				[8B63]

	lda	FdcCommand,Y		;				[0345]
	sta	DataRegister		;				[DE81]

	iny
	cpy	#9
	bne	A_8B63			;				[8B63]

	ldx	#$0F
	ldy	#0
A_8B79:					;				[8B79]
	bit	StatusRegister		; FDC ready?			[DE80]
	bpl	A_8B79			; no, -> wait			[8B79]

	lda	DataRegister		;				[DE81]
	cmp	#0
	beq	A_8B8A			;				[8B8A]

	lda	#1
	sta	ErrorCode		;				[0351]
A_8B8A:					;				[8B8A]
	iny
	bne	A_8B79			;				[8B79]

	dex
	bpl	A_8B79			;				[8B79]

	jmp	ReadStatus		;				[8962]


;**  Format a track
FormatTrack:				;				[8B93]
	lda	#$4D
	sta	FdcFormatData		;				[0352]

	lda	FdcHSEL			;				[0346]
	sta	FdcFormatData+1		;				[0353]

	lda	FdcNumber		;				[034A]
	sta	FdcFormatData+2		;				[0354]

	lda	#9			; sectors / track
	sta	FdcFormatData+3		;				[0355]

	lda	#$54			; gap length
	sta	FdcFormatData+4		;				[0356]

	lda	#0			; filler byte
	sta	FdcFormatData+5		;				[0357]

	ldy	#0
A_8BB5:					;				[8BB5]
	bit	StatusRegister		; FDC ready?			[DE80]
	bpl	A_8BB5			; no, -> wait			[8BB5]

	lda	FdcFormatData,Y		;				[0352]
	sta	DataRegister		;				[DE81]

	iny
	cpy	#6			; 6 bytes written?
	bne	A_8BB5			; no, -> more			[8BB5]

;* Supply the data field for each sector, see data sheet for details
	lda	#1
	sta	FdcSector		;				[0349]

	ldx	#$08
A_8BCC:					;				[8BCC]
	ldy	#0

; Supply TCHRN information
A_8BCE:					;				[8BCE]
	lda	FdcTrack,Y		;				[0347]
A_8BD1:					;				[8BD1]
	bit	StatusRegister		; FDC ready?			[DE80]
	bpl	A_8BD1			; no, -> wait			[8BD1]

	sta	DataRegister		;				[DE81]

	iny
	cpy	#$04			; supplied neede 5 bytes?
	bne	A_8BCE			; no, -> more			[8BCE]

	inc	FdcSector		; next sector			[0349]

	dex				; nine sectors done?
	bpl	A_8BCC			; no, -> more			[8BCC]
A_8BE4:					;				[8BE4]
	lda	StatusRegister		;				[DE80]
	and	#$20			; execution finished?
	bne	A_8BE4			; no, -> wait			[8BE4]

	jmp	ReadStatus		;				[8962]


;**  Write one or more sector to the disk
WriteSector:				;				[8BEE]
	ldy	#0
	lda	#$65			; code for "write sector"
	sta	FdcCommand		;				[0345]
A_8BF5:					;				[8BF5]
	lda	StatusRegister		;				[DE80]
	and	#$80			; FDC ready?
	beq	A_8BF5			; no, -> wait			[8BF5]

	lda	FdcCommand,Y		;				[0345]
	sta	DataRegister		;				[DE81]

	iny
	cpy	#9			; nine sectors done?
	bne	A_8BF5			; no, -> more			[8BF5]


	lda	#1
	sta	PageCounter		;				[02]

	ldy	#0
	jsr	WriteData		;				[0179]

	lda	ErrorCode		; error found?			[0351]
	bne	A_8C36			; yes, -> exit			[8C36]

	jsr	ReadStatus		; error found?			[8962]
	bcs	A_8C23			; yes, ->			[8C23]

	lda	FdcST1			;				[033D]
	and	#$F8
	cmp	#$80			; error found?
	beq	A_8C39			; no, ->			[8C39]

; Error found, but we try again. But: HOW MAY TRIES ???
A_8C23:					;				[8C23]
	dec	DirPointer+1		;				[FC]
	dec	DirPointer+1		;				[FC]

	jsr	Specify			;				[891A]
	jsr	Recalibrate		;				[88F7]
	jsr	SeekTrack		;				[898A]
	jsr	SetWatchdog		;				[8D90]

	jmp	WriteSector		;				[8BEE]

; Error found
A_8C36:					;				[8C36]
	jmp	StopWatchdog		;				[8DBD]

A_8C39:					;				[8C39]
	jsr	SetWatchdog		;				[8D90]

	inc	FdcEOT			;				[034B]
	inc	FdcSector		;				[0349]

	dec	NumOfSectors		; all sectors written?		[F7]
	beq	A_8C75			; yes, -> exit			[8C75]

	lda	FdcEOT			;				[034B]
	cmp	#10			; complete track written?
	beq	A_8C50			; yes, -> next track		[8C50]

	jmp	WriteSector		;				[8BEE]

; Go to the next track
A_8C50:					;				[8C50]
	lda	#1
	sta	FdcEOT			;				[034B]
	sta	FdcSector		;				[0349]

; Go to the other head
	lda	FdcHead			;				[0348]
	eor	#1
	sta	FdcHead			;				[0348]

	asl	A
	asl	A
	sta	FdcHSEL			;				[0346]

	cmp	#4			; head 1?
	beq	A_8C72			; yes, -> continue		[8C72]

; Head 0 -> head 1 means: next track
	inc	FdcTrack		;				[0347]
	jsr	SeekTrack		;				[898A]

	jsr	SetWatchdog		;				[8D90]
A_8C72:					;				[8C72]
	jmp	WriteSector		;				[8BEE]

A_8C75:					;				[8C75]
	jmp	StopWatchdog		;				[8DBD]


;**  Read a sector
ReadSector:				;				[8C78]
	ldy	#0
	sty	L_0119+1		;				[011A]

	lda	#$66			; "Read sector" command
	sta	FdcCommand		;				[0345]

; Write the needed bytes into the FDC
A_8C82:					;				[8C82]
	lda	StatusRegister		;				[DE80]
	and	#$80			; FDC busy?
	beq	A_8C82			; yes, -> wait			[8C82]

	lda	FdcCommand,Y		;				[0345]
	sta	DataRegister		;				[DE81]

	iny
	cpy	#9			; nine bytes written?
	bne	A_8C82			; no, -> next one		[8C82]

	lda	TapeBuffer+39		;				[0363]
	cmp	#2
	bcs	A_8CB7			;				[8CB7]

	and	#1
	beq	A_8CB1			;				[8CB1]

	lda	TapeBuffer+38		; number of bytes to read after	[0362]
	sta	L_0165+1		;   first 256 bytes		[0166]

	ldy	#0			; start with reading 256 bytes

	lda	#1
	sta	NumOfSectors		;				[F7]

	jsr	RdBytesSector		;				[0139]
	jmp	A_8CC0			;				[8CC0]

A_8CB1:					;				[8CB1]
	lda	TapeBuffer+38		;				[0362]
	sta	L_0119+1		;				[011A]
A_8CB7:					;				[8CB7]
	lda	#1			; read two pages
	sta	PageCounter		;				[02]

	ldy	#0
	jsr	ReadPagesFlop		;				[0102]
A_8CC0:					;				[8CC0]
	lda	ErrorCode		; error found?			[0351]
	bne	A_8CE9			; yes, -> 			[8CE9]

	jsr	ReadStatus		;				[8962]
	bcs	A_8CD3			;				[8CD3]

	lda	FdcST1			;				[033D]
	and	#$F8
	cmp	#$80
	beq	A_8CEA			;				[8CEA]
A_8CD3:					;				[8CD3]
	dec	DirPointer+1		;				[FC]
	dec	DirPointer+1		;				[FC]
	jsr	StopWatchdog		;				[8DBD]
	jsr	Specify			;				[891A]
	jsr	Recalibrate		;				[88F7]
	jsr	SeekTrack		;				[898A]
	jsr	SetWatchdog		;				[8D90]

	jmp	ReadSector		;				[8C78]

A_8CE9:					;				[8CE9]
	rts

A_8CEA:					;				[8CEA]
	jsr	SetWatchdog		;				[8D90]

	inc	FdcEOT			;				[034B]
	inc	FdcSector		;				[0349]

	lda	TapeBuffer+39		;				[0363]
	cmp	#2
	bcc	A_8D36			;				[8D36]

	sec
	sbc	#2
	sta	TapeBuffer+39		;				[0363]

	dec	NumOfSectors		;				[F7]
	beq	A_8D36			;				[8D36]

	lda	FdcEOT			;				[034B]
	cmp	#$0A
	beq	A_8D0E			;				[8D0E]

	jmp	ReadSector		;				[8C78]

A_8D0E:					;				[8D0E]
	jsr	StopWatchdog		;				[8DBD]

	lda	#1
	sta	FdcEOT			;				[034B]
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

E_8D37:					;				[8D37]
	ldx	#2
A_8D39:					;				[8D39]
	lda	Wait4FdcReady		;				[89C0]
	and	#1
	bne	A_8D39			;				[8D39]

	rts

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
	ldx	#$08
A_8D5C:					;				[8D5C]
	lda	CmdReadData,X		;				[8D77]
	sta	FdcCommand,X		;				[0345]

	dex
	bpl	A_8D5C			;				[8D5C]

; Actual copy
	ldx	#$BE
A_8D67:					;				[8D67]
	lda	StackProgram,X		;				[9462]
	sta	StackPage1,X		;				[0101]

	dex
	bne	A_8D67			;				[8D67]

	jsr	Specify			;				[891A]
	jsr	Recalibrate		;				[88F7]

	rts


;**  Bytes need for the command "Read data"  IMHO
CmdReadData:				;				[8D77]
.by $66, $00, $02, $00, $01, $02, $01, $1B, $FF 
D_8D80:					;				[8D80]
.tp '0123456789ABCDEF'


;**  Set the timer of CIA2 to generate an IRQ when FDC has to wait too long
SetWatchdog:				;				[8D90]
	lda	#0			; stop the timers
	sta	CIA2CRA			;				[DD0E]
	sta	CIA2CRB			;				[DD0F]

	lda	#$08
	sta	CIA2TI1H		;				[DD05]

	lda	#2
	sta	CIA2TI2H		;				[DD07]

	lda	#0
	sta	CIA2TI1L		;				[DD04]
	sta	CIA2TI2L		;				[DD06]

	lda	#$51			; start the timer
	sta	CIA2CRB			; count underflow of timer A	[DD0F]

	lda	#$91			; start the timer for 50 Hz
	sta	CIA2CRA			;				[DD0E]

	lda	#$82			; enable IRQ for timer B underflow
	sta	CIA2IRQ			;				[DD0D]

	lda	CIA2IRQ			; clear register		[DD0D]
	rts


;**  Disable timer IRQ, stop the timer
StopWatchdog:				;				[8DBD]
	lda	#$7F
	sta	CIA2IRQ			;				[DD0D]

	lda	#0
	sta	CIA2CRA			;				[DD0E]
	sta	CIA2CRB			;				[DD0F]

	rts



J_8DCB:					;				[8DCB]
	pha

	txa
	pha

	tya
	pha

	jsr	IncrClock22		;				[F6BC]
	jsr	ScanStopKey		;				[FFE1]

	beq	A_8DDE			;				[8DDE]

	pla
	tay
	pla
	tax
	pla
	rti

A_8DDE:					;				[8DDE]
	jsr	InitSidCIAIrq2		;				[FDA3]
	jsr	InitScreenKeyb		;				[E518]

	jmp	(BasicNMI)		;				[A002]


; Oficially here starts the NMI routine of the cartridge. Now the weird fact:
; the NMI input of the expansion port is not connected. But during the 
; initialisation of the C64 the routine is set as first NMI routine for the it.
CartNMI:				;				[8DE7]
	pha

	lda	P6510			;				[01]
	pha

	lda	#$37
	sta	P6510			;				[01]

	lda	CIA2IRQ			;				[DD0D]
	bpl	A_8E05			;				[8E05]

	and	#2
	beq	A_8E05			;				[8E05]

	inc	ErrorCode		;				[0351]
	ldx	TempStackPtr		;				[0350]
	txs

	lda	ResetFDC		; reset the FDC			[DF80]

	jmp	StopWatchdog		;				[8DBD]

A_8E05:					;				[8E05]
	jsr	NewRoutines		;				[80C0]

	pla
	sta	P6510			;				[01]

	pla
	jmp	J_8DCB			;				[8DCB]

ReadDirectory:				;				[8E0F]
	lda	#1
	sta	NumOfSectors		;				[F7]

	lda	#0
	sta	Counter			;				[0366]
J_8E18:					;				[8E18]
	lda	Z_FF			;				[FF]
	sta	SectorL			;				[F8]

	ldx	#0
	stx	SectorH			;				[F9]

	lda	#0
	sta	DirPointer		;				[FB]

	lda	StartofDir		;				[0334]
	sta	DirPointer+1		;				[FC]

	jsr	SetupSector		;				[8899]

	lda	#0
	sta	ErrorCode		;				[0351]

	jsr	SeekTrack		;				[898A]
	jsr	SetWatchdog		;				[8D90]
	jsr	WaitRasterLine		;				[8851]

	lda	#2
	sta	TapeBuffer+39		;				[0363]

	lda	#0
	sta	TapeBuffer+38		;				[0362]

	jsr	ReadSector		;				[8C78]

	lda	Counter			;				[0366]
	cmp	#9
	bne	A_8E55			;				[8E55]

	lda	#$0A
	sta	ErrorCode		;				[0351]

	bne	A_8E5D			;				[8E5D]
A_8E55:					;				[8E55]
	inc	Counter			;				[0366]

	lda	ErrorCode		; error found?			[0351]
	bne	A_8E5E			;				[8E5E]
A_8E5D:					;				[8E5D]
	rts

A_8E5E:					;				[8E5E]
	jsr	Specify			;				[891A]
	jsr	Recalibrate		;				[88F7]

	jmp	J_8E18			;				[8E18]


;**  Load and display the directory
DisplayDir:				;				[8E67]
	lda	#$07
	sta	Z_FF			;				[FF]

	jsr	ReadDirectory		;				[8E0F]
	jsr	StopWatchdog		;				[8DBD]
	jsr	GetFATs			;				[8813]

	lda	#$1B			; screen on
	sta	VICCTR1			;				[D011]

	lda	ErrorCode		; error found?			[0351]
	beq	A_8E80			; no, ->			[8E80]

	clc
	rts


; ??? what has been loaded exactly at this point ???
A_8E80:					;				[8E80]
	lda	#0
	sta	DirPointer		;				[FB]

	lda	StartofDir		;				[0334]
	sta	DirPointer+1		;				[FC]

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
	lda	Z_FD			;				[FD]
	cmp	#$60			; < 'a' ?
	bcc	A_8EA6			; yes, ->			[8EA6]

	sec
	sbc	#$20
A_8EA6:					;				[8EA6]
	jsr	OutByteChan		;				[FFD2]

	lda	Z_FD			;				[FD]
; ??? why ???, see next instruction

	pla
	tay

	iny
	cpy	#$0B
	bne	A_8E95			;				[8E95]

	lda	#$0D
	jsr	OutByteChan		;				[FFD2]

	jmp	J_8F1A			;				[8F1A]

J_8EBA:					;				[8EBA]
	lda	#0
	sta	DirPointer		;				[FB]

	lda	StartofDir		;				[0334]
	sta	DirPointer+1		;				[FC]
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
	lda	DirPointer		;				[FB]
	clc
	adc	#$20
	sta	DirPointer		;				[FB]

	lda	DirPointer+1		;				[FC]
	adc	#0
	sta	DirPointer+1		;				[FC]

	cmp	EndofDir		;				[0335]
	bne	A_8EC3			;				[8EC3]

	lda	Z_FF			;				[FF]
	clc
	adc	#1
	sta	Z_FF			;				[FF]

	cmp	#$0E
	bcs	A_8F46			;				[8F46]

	sei
	jsr	ReadDirectory		;				[8E0F]

	lda	#$1B			; screen on
	sta	VICCTR1			;				[D011]

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
	lda	#$07
	sta	NumDirSectors		;				[0364]

	lda	#$07
	sta	SectorL			;				[F8]

	sta	DirSector		;				[0369]

	lda	#0
	sta	SectorH			;				[F9]

	jsr	SetupSector		;				[8899]
A_8F62:					;				[8F62]
	lda	#0
	sta	DirPointer		;				[FB]

	lda	StartofDir		;				[0334]
	sta	DirPointer+1		;				[FC]

	lda	#1
	sta	NumOfSectors		;				[F7]

	asl	A
	sta	TapeBuffer+39		;				[0363]

	lda	#0
	sta	TapeBuffer+38		;				[0362]

	jsr	ReadSectors		;				[885E]

	lda	ErrorCode		; error found?			[0351]
	beq	A_8F82			;				[8F82]

	clc
	rts

A_8F82:					;				[8F82]
	lda	#0
	sta	DirPointer		;				[FB]

	lda	StartofDir		;				[0334]
	sta	DirPointer+1		;				[FC]
A_8F8B:					;				[8F8B]
	ldx	#0
	ldy	#0
A_8F8F:					;				[8F8F]
	jsr	RdDataRamDxxx		;				[01A0]

	iny
	cmp	#0
	beq	A_8FD3			;				[8FD3]

	cmp	#$E5
	beq	A_8FD3			;				[8FD3]

	cmp	FdcFileName,X		;				[036C]
	bne	A_8FA7			;				[8FA7]

	inx
	cpx	#$0A
	bne	A_8F8F			;				[8F8F]

	sec
	rts

A_8FA7:					;				[8FA7]
	lda	DirPointer		;				[FB]
	clc
	adc	#$20
	sta	DirPointer		;				[FB]

	lda	DirPointer+1		;				[FC]
	adc	#0
	sta	DirPointer+1		;				[FC]

	cmp	EndofDir		;				[0335]
	bne	A_8F8B			;				[8F8B]

	lda	DirSector		;				[0369]
	clc
	adc	#1
	sta	SectorL			;				[F8]

	sta	DirSector		;				[0369]

	jsr	SetupSector		;				[8899]

	dec	NumDirSectors		;				[0364]
	bpl	A_8F62			;				[8F62]

	lda	#$0E
	sta	ErrorCode		;				[0351]

	clc
	rts

A_8FD3:					;				[8FD3]
	ldy	#$1F
	lda	#0
A_8FD7:					;				[8FD7]
	jsr	WrDataRamDxxx		;				[01AF]

	dey
	bpl	A_8FD7			;				[8FD7]

	ldy	#$0A
A_8FDF:					;				[8FDF]
	lda	FdcFileName,Y		;				[036C]
	jsr	WrDataRamDxxx		;				[01AF]

	dey
	bpl	A_8FDF			;				[8FDF]

	clc
	rts


;**  Check the file name
FindFile:				;				[8FEA]
	lda	LengthFileName		; file name present?		[B7]
	bne	A_8FF5			; yes, ->			[8FF5]

	lda	#$11
	sta	ErrorCode		;				[0351]

	clc				; error found
	rts

A_8FF5:					;				[8FF5]
	lda	#0
	sta	ErrorCode		;				[0351]

	jsr	StripSP			;				[90A7]
	jsr	PadOut			;				[90CE]

	lda	ErrorCode		; error found?			[0351]
	beq	A_9007			; no, -> continue		[9007]

	clc
	rts

A_9007:					;				[9007]
	lda	FdcFileName		;				[036C]
	cmp	#'$'			; directory wanted?
	bne	Search			;				[9011]

	jmp	DisplayDir		;				[8E67]


;**  Search for a file
Search:					;				[9011]
	lda	#6
	sta	NumDirSectors		;				[0364]

; The directory start at sector 7
	lda	#7
	sta	SectorL			;				[F8]
	sta	DirSector		;				[0369]

	lda	#0
	sta	SectorH			;				[F9]

	jsr	SetupSector		;				[8899]
A_9024:					;				[9024]
	lda	#0
	sta	DirPointer		;				[FB]

	lda	StartofDir		; normally $D0			[0334]
	sta	DirPointer+1		;				[FC]

	lda	#1
	sta	NumOfSectors		;				[F7]

	asl	A			; A := 2
	sta	TapeBuffer+39		;				[0363]

	lda	#0
	sta	TapeBuffer+38		;				[0362]

	jsr	ReadSectors		;				[885E]

	lda	ErrorCode		; error found?			[0351]
	beq	A_9044			; no, -> continue		[9044]

	clc
	rts


; Read the directory under the $Dxxx area
A_9044:					;				[9044]
	lda	#0
	sta	DirPointer		;				[FB]

	lda	StartofDir		; starts with $D0		[0334]
	sta	DirPointer+1		;				[FC]
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

	lda	DirPointer		;				[FB]
	clc
	adc	#$20			; point to next entry
	sta	DirPointer		;				[FB]

	lda	DirPointer+1		;				[FC]
	adc	#0
	sta	DirPointer+1		;				[FC]

	cmp	EndofDir		; end of directory sector?	[0335]
	bne	A_904F			; no, -> more			[904F]

; Go to the next directory sector
	lda	DirSector		;				[0369]
	clc
	adc	#1
	sta	SectorL			;				[F8]
	sta	DirSector		;				[0369]

	jsr	SetupSector		;				[8899]

	dec	NumDirSectors		; searched all dir sectors?	[0364]
	bpl	A_9024			; no, -> next one		[9024]
A_90A0:					;				[90A0]
	lda	#$0B			; file not found
	sta	ErrorCode		;				[0351]

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
	lda	#$10
	sta	ErrorCode		;				[0351]

	rts

; Dot found, copy extension
A_9107:					;				[9107]
	tya
	pha				; save Y

	ldx	#8
A_910B:					;				[910B]
	iny
	lda	(AddrFileName),Y	;				[BB]
	sta	FdcFileName,X		;				[036C]

	inx
	cpx	#11
	bne	A_910B			;				[910B]

	pla
	tay				; restore Y

	cpy	#8
	beq	A_9126			;				[9126]

; Fill up with spaces
	lda	#' '
A_911E:					;				[911E]
	sta	FdcFileName,Y		;				[036C]

	iny
	cpy	#8
	bne	A_911E			;				[911E]
A_9126:					;				[9126]
	rts


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

	lda	#0
	sta	TapeBuffer+36		;				[0360]

	jsr	BN2DEC			;				[920E]

	ldy	#$04
	lda	#$30
A_9150:					;				[9150]
	cmp	NumDirSectors,Y		;				[0364]
	bne	A_915C			;				[915C]

	dey
	bpl	A_9150			;				[9150]

	jsr	OutByteChan		;				[FFD2]

	rts

A_915C:					;				[915C]
	tya
	pha

	lda	NumDirSectors,Y		;				[0364]
	jsr	OutByteChan		;				[FFD2]

	pla
	tay
	dey
	bpl	A_915C			;				[915C]

	rts


ShowBytesFree:				;				[916A]
	sei

	lda	#0
	sta	TapeBuffer+34		;				[035E]
	sta	TapeBuffer+35		;				[035F]
	sta	TapeBuffer+36		;				[0360]

	lda	#2
	sta	TapeBuffer+26		;				[0356]

	lda	#0
	sta	TapeBuffer+27		;				[0357]
A_9180:					;				[9180]
	lda	TapeBuffer+26		;				[0356]
	sta	TapeBuffer+30		;				[035A]

	lda	TapeBuffer+27		;				[0357]
	sta	TapeBuffer+31		;				[035B]

	jsr	GetNextCluster		;				[87A4]

	lda	TapeBuffer+30		;				[035A]
	ora	TapeBuffer+31		;				[035B]
	bne	A_919F			;				[919F]

	inc	TapeBuffer+35		;				[035F]
	bne	A_919F			;				[919F]

	inc	TapeBuffer+36		;				[0360]
A_919F:					;				[919F]
	lda	TapeBuffer+26		;				[0356]
	clc
	adc	#1
	sta	TapeBuffer+26		;				[0356]

	lda	TapeBuffer+27		;				[0357]
	adc	#0
	sta	TapeBuffer+27		;				[0357]

	cmp	#2
	bne	A_9180			;				[9180]

	lda	TapeBuffer+26		;				[0356]
	cmp	#$CB
	bne	A_9180			;				[9180]

	asl	TapeBuffer+35		;				[035F]
	rol	TapeBuffer+36		;				[0360]
	asl	TapeBuffer+35		;				[035F]
	rol	TapeBuffer+36		;				[0360]
	jsr	BN2DEC			;				[920E]

	ldy	#0
A_91CC:					;				[91CC]
	tya
	pha

	lda	D_91FC,Y		;				[91FC]
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
	lda	#$30
A_91E2:					;				[91E2]
	cmp	NumDirSectors,Y		;				[0364]
	bne	A_91EE			;				[91EE]

	dey
	bpl	A_91E2			;				[91E2]

	jsr	OutByteChan		;				[FFD2]

	rts

A_91EE:					;				[91EE]
	tya
	pha

	lda	NumDirSectors,Y		;				[0364]
	jsr	OutByteChan		;				[FFD2]

	pla
	tay
	dey
	bpl	A_91EE			;				[91EE]

	rts

 
D_91FC:					;				[91FC]
.tx 'TOTAL BYTES FREE '
.by $00


BN2DEC:					;				[920E]
	ldy	#5			; start with 100000
A_9210:					;				[9210]
	ldx	#0
A_9212:					;				[9212]
	lda	TapeBuffer+34		;				[035E]
	sec
	sbc	D_925A,Y		;				[925A]
	sta	TapeBuffer+34		;				[035E]

	lda	TapeBuffer+35		;				[035F]
	sbc	D_9260,Y		;				[9260]
	sta	TapeBuffer+35		;				[035F]

	lda	TapeBuffer+36		;				[0360]
	sbc	D_9266,Y		;				[9266]
	bcc	A_9233			;				[9233]

	sta	TapeBuffer+36		;				[0360]

	inx
	bne	A_9212			;				[9212]

; Oops, we subtracted to much. add it again
A_9233:					;				[9233]
	lda	TapeBuffer+34		;				[035E]
	clc
	adc	D_925A,Y		;				[925A]
	sta	TapeBuffer+34		;				[035E]

	lda	TapeBuffer+35		;				[035F]
	adc	D_9260,Y		;				[9260]
	sta	TapeBuffer+35		;				[035F]

	txa
	clc
	adc	#$30
	sta	NumDirSectors,Y		;				[0364]

	dey				; next multiple of ten?
	bne	A_9210			; yes, ->			[9210]

	lda	TapeBuffer+34		;				[035E]
	clc
	adc	#$30
	sta	NumDirSectors,Y		;				[0364]

	rts


;** The hexadecimal values of 0, 10, 100, 1000, 10000 and 100000 in three bytes
D_925A:					;				[925A]
.by $00, $0A, $64, $E8, $10, $A0
D_9260:					;				[9260]
.by $00, $00, $00, $03, $27, $86
D_9266:					;				[9266]
.by $00, $00, $00, $00, $00, $01


;**  Show an error message
ShowError:				;				[926C]
	ldx	MSGFLG			; direct mode?			[9D]
	bmi	A_9271			; yes, -> display error		[9271]

	rts

A_9271:					;				[9271]
	tax
	lda	TblErrorMsgL,X		;				[92DC]
	sta	DirPointer		;				[FB]

	lda	TblErrorMsgH,X		;				[92EE]
	sta	DirPointer+1		;				[FC]

	ldy	#0
	jsr	StopWatchdog		;				[8DBD]
J_9281:					;				[9281]
	lda	(DirPointer),Y		; end of message?		[FB]
	beq	A_9292			; yes, -> exit			[9292]

	tya
	pha
; Note: saving Y is not needed, OUTBYTECHAN does save Y

	lda	(DirPointer),Y		;				[FB]
	jsr	OutByteChan		;				[FFD2]

	pla
	tay

	iny
	jmp	J_9281			;				[9281]

A_9292:					;				[9292]
	clc
	rts


;**  Load the File BOOT.EXE ino memory - part 1
LoadBootExe:				;				[9294]
	lda	#<BootExe
	sta	AddrFileName		;				[BB]

	lda	#>BootExe
	sta	AddrFileName+1		;				[BC]

	lda	#$08
	sta	LengthFileName		;				[B7]

; Load address: $0801
	ldx	#1
	ldy	#$08

	jmp	LoadBootExe2		;				[869D]

 
S_92A7:
.tx 'T.I.B.  VOL'
.by $00

S_92B3:					;				[92B3]
.tp 'T.I.B PLC DISK DRIVER INSTALLED@'
 
BootExe:
.tx 'BOOT.EXE'
.by $00
 

TblErrorMsgL:				;				[92DC]
.by <Msg00
.by <Msg01
.by <Msg02
.by <Msg03
.by <Msg04
.by <Msg05
.by <Msg06
.by <Msg07
.by <Msg08
.by <Msg09
.by <Msg0A
.by <Msg0B
.by <Msg0C
.by <Msg0D
.by <Msg0E
.by <Msg0F
.by <Msg10
.by <Msg11


TblErrorMsgH:				;				[92EE]
.by >Msg00
.by >Msg01
.by >Msg02
.by >Msg03
.by >Msg04
.by >Msg05
.by >Msg06
.by >Msg07
.by >Msg08
.by >Msg09
.by >Msg0A
.by >Msg0B
.by >Msg0C
.by >Msg0D
.by >Msg0E
.by >Msg0F
.by >Msg10
.by >Msg11

 
S_9300:
Msg00:
.tx 'OK'
.by $00
Msg01:
.tx 'DISK IS WRITE PROTECTED'
.by $00
Msg02:
.tx 'DISK IS UNUSABLE'
.by $00
Msg03:
.tx 'DISK IS NOT FORMATTED'
.by $00
Msg04:
.tx 'FILE IS CORRUPT'
.by $00
Msg05:
.tx 'FORMATING DISK'
.by $00
Msg06:
.tx 'RENAMING FILE'
.by $00
Msg07:
.tx 'SCRATCHING FILE'
.by $00
Msg08:
.tx 'ERROR DURING WRITE'
.by $00
Msg09:
.tx 'ERROR DURING READ'
.by $00
Msg0A:
.tx 'DISK MAY BE DAMAGED'
.by $00
Msg0B:
.tx 'FILE NOT FOUND'
.by $00
Msg0C:
.tx 'NO FILE EXT SPECIFIED'
.by $00
Msg0D:
.tx 'FILE TO LARGE'
.by $00
Msg0E:
.tx 'NO MORE DIRECTORY SPACE'
.by $00
Msg0F:
.tx 'DISK FOUND TO BE UNRELIABLE'
.by $00
Msg10:
.tx 'NAME TO LONG'
.by $00
Msg11:
.tx 'NO NAME SPECIFIED'
.by $00
 
D_943E:					;				[943E]
.by $EB, $28, $90, $43, $36, $34, $20, $50	; .(.C64 P  $943E
.by $4E, $43, $49, $00, $02, $02, $01, $00	; NCI.....  $9446
.by $02, $70, $00, $A0, $05, $F9, $03, $00	; .p......  $944E
.by $09, $00, $02, $00, $00, $00, $00, $00	; ........  $9456
.by $00, $00, $00, $00			; ....  $945E


;**  Program that is meant to run in the Stack
StackProgram:				;				[9462]
.rb $0101

StackPage1:				;				[0101]
.by $00					; .  $0101
 

;**  Read a number of pages (= 256 bytes) form the floppy
; in:	256-Y bytes are read 
; Note: only used at one place and for just two pages
ReadPagesFlop:				;				[0102]
	tsx
	stx	TempStackPtr		;				[0350]
A_0106:					;				[0106]
	ldx	#$30			;				[30]
A_0108:					;				[0108]
	bit	StatusRegister		; FDC ready?			[DE80]
	bpl	A_0108			; no, -> wait			[0108]

	lda	DataRegister		; read byte			[DE81]

; Switch to 64 KB of RAM
	stx	P6510			;				[01]

	sta	(DirPointer),Y		; save byte			[FB]

; Switch back
	lda	#$37
	sta	P6510			;				[01]

	iny

; "#0" in the next line can be changed by the program
L_0119:					;				[0119]
	cpy	#0			; finished with reading?
	bne	A_0108			; no, -> next byte		[0108]

	inc	DirPointer+1		;				[FC]

	dec	PageCounter		; more pages to be read?	[02]
	bpl	A_0106	 		; yes, ->			[0106]

	cpy	#0			; whole sector read?
	beq	A_0138			; yes, -> exit			[0138]

	inc	PageCounter		;				[02]

; Read the rest of the sector, FDC expects this
A_0129:					;				[0129]
	bit	StatusRegister		; FDC ready?			[DE80]
	bpl	A_0129			; no, -> wait			[0129]

	lda	DataRegister		; dummy read			[DE81]

	iny				; finished reading?
	bne	A_0129			; no, -> next byte		[0129]

	dec	PageCounter		; more pages to be read?	[02]
	bpl	A_0129			; yes, ->			[0129]
A_0138:					;				[0138]
	rts


;**  Read a number of bytes from the momentary sector
; in:	256-Y bytes are read 
; Note: RdBytesSector is only called at one place and Y = 0 there
RdBytesSector:				;				[0139]
	tsx
	stx	TempStackPtr		;				[0350]

	ldx	#$30
A_013F:					;				[013F]
	bit	StatusRegister		; FDC ready?			[DE80]
	bpl	A_013F			; no, -> wait			[013F]

	lda	DataRegister		; read byte			[DE81]

; Switch to 64 KB RAM mode
	stx	P6510			;				[01]

	sta	(DirPointer),Y		; save byte			[FB]

; Switch back
	lda	#$37
	sta	P6510			;				[01]

	iny				; finished reading?
	bne	A_013F			; no, -> next byte		[013F]

; Next page in RAM
	inc	DirPointer+1		;				[FC]

; Read next number of bytes. See L_0165.
A_0154:					;				[0154]
	bit	StatusRegister		; FDC ready?			[DE80]
	bpl	A_0154			; no, -> wait			[0154]

	lda	DataRegister		; read byte			[DE81]

; Switch to 64 KB RAM mode
	stx	P6510			;				[01]

	sta	(DirPointer),Y		; save byte			[FB]

; Switch back
	lda	#$37
	sta	P6510			;				[01]

	iny

; "#0" in the next line can be changed by the program
L_0165:					;				[0165]
	cpy	#0			; finished with reading?
	bne	A_0154			; no, -> next byte		[0154]

	cpy	#0			; whole sector read?
	beq	A_0178			; yes, -> exit			[0178]

; Read the rest of the sector, FDC expects this
A_016D:					;				[016D]
	bit	StatusRegister		; FDC ready?			[DE80]
	bpl	A_016D			; no, -> wait			[016D]

	lda	DataRegister		; dummy read			[DE81]

	iny				; finished reading?
	bne	A_016D			; no, -> next byte		[016D]
A_0178:					;				[0178]
	rts


;**  Write 512 bytes of data to the disk
WriteData:				;				[0179]
	tsx				; save the SP in case there is an error
	stx	TempStackPtr		;				[0350]
A_017D:					;				[017D]
	ldx	#$30			; 64 KB of RAM visible
	stx	P6510			;				[01]

	lda	(DirPointer),Y		; read byte from RAM under I/O	[FB]

	ldx	#$37
	stx	P6510			;				[01]
A_0187:				;				[0187]
	bit	StatusRegister		; FDC ready?			[DE80]
	bpl	A_0187			; no, -> wait			[0187]

	sta	DataRegister		;				[DE81]

	iny
	bne	A_017D			;				[017D]

	inc	DirPointer+1		;				[FC]
	dec	PageCounter		; two pages done?		[02]
	bpl	A_017D			; no, -> next 256 bytes		[017D]

	rts


StackPage153:				;				[0199]
	lda	#$35
	sta	P6510			;				[01]

	jmp	(J_00FE)		;				[00FE]


;**  Read one byte of data from the RAM under the $D0xx or $D2xx area
; in:	Y = location within D000/D2000 area
RdDataRamDxxx:				;				[01A0]
	lda	#$30			; 64 KB of RAM visible
	stx	TempStore		; save X			[FA]

	ldx	P6510			; save original value		[01]
	sta	P6510			;				[01]

	lda	(DirPointer),Y		; ???				[FB]

	stx	P6510			; restore original value	[01]

	ldx	TempStore		; restore X			[FA]
	rts


;**  Write one byte of data to the RAM under the $D0xx or $D2xx area
; in:	Y = location within D000/D2000 area
;	A = data to be stored
WrDataRamDxxx:				;				[01AF]
	pha

	stx	TempStore		; save X			[FA]

	ldx	P6510			; save original value		[01]

	lda	#$30			; 64 KB of RAM visible
	sta	P6510			;				[01]

	pla
	sta	(DirPointer),Y		;				[FB]

	stx	P6510			; restore original value	[01]

	ldx	TempStore		; restore X			[FA]
	rts
.re

 
S_9521:
.fb $FF, $0ADF
 
.en					; End of part to assemble
 
 
