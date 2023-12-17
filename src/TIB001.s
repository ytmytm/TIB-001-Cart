;
;	Disassembly of the ROM of the TIB-001 FDC cartridge

; (started by Ruud Baltissen, http://www.softwolves.com/arkiv/cbm-hackers/28/28457.html - thank you very much!)
; continued by Maciej 'YTM/Elysium' Witkowiak, 2023

; Changes (YTM):
; - change device number to 7
; - LOAD needs 1K buffer for first cluster but now standard PRG files (with load address) can be used
;	LOAD can load data in $0400-$D1FF range
; - SAVE also uses 1K buffer and saves standard PRG files with load address
; - corrected CHKOUT to that commands can be sent to both DD-001 and IEC devices
;   DD-001 supports: N(ew), S(cratch), R(ename)
; - loads BOOT.PRG instead of BOOT.EXE
; - directory listing converted to BASIC, matching CBM DOS format
; - filesizes shown in blocks (256 bytes), same for disk free space
; - DOS wedge for @#<number>, @$, /, %, ^, <- commands, @Q to disable
; - a lot of loading Pointer with (0, StartofDir), move that to a subroutine
; - handle disk commands with both OPEN15,7,15,"R:..." and OPEN+PRINT#
; - store version, number of drives and own device number in fixed signature right after jump table

; Remarks/TODO (YTM):
; - make DOS wedge commands shorter: @<number>, $, % (as load+run same as ^) 
; - if LOAD could stash FAT chain somewhere (up to 128 bytes) it could load files up to $FFFF
; - for ICKOUT (PRINT#) check length of buffer, not just the ending quote mark
; - handle disk commands only on SA=15
; - check disk format (BIOS Parameter Block) and explain when+why it's not supported (e.g. because of 1 sector/cluster)
; - move more variables to zero page, check C64 memory maps on what it used with tape (a lot!)
; - check code paths, which locations are temporary and can overlap between functions
; - add programmable function keys (JiffyDOS / ActionReplay style)

; My (Ruud's) notes/ideas regarding this disassembly
; - only a 3,5" 720 KB DD FDD can be used, not a 5.25" 360 KB one
; - only ONE drive can be used
; - a directory sector is stored in the RAM under the $Dxxx area, followed by FAT, followed by temp area for LOAD/SAVE first cluster (loadaddress)
; - probably a bug, look for "; BUG"
; - Some RS232 variables are used, meaning: we cannot use RS 232 anymore
; - bad: I/O port of 6510 is manipulated but not restored with original value
; - bad: video control register is manipulated using and not restored
; - look for ??? for some questions I had
; - inconsistent use of Carry for reporting an error
; - in general: the programming could have been done more efficient


; Remarks:
; - The data sheet speaks of "cylinders", nowadays the word "track" is favored.


; device number, this can be set externally via ca65: -DDEVNUM=9 or 'make DEVNUM=9'
.ifndef DEVNUM
DEVNUM = 7
.endif

; GEOS macros for readability and shorter code
.include "geosmac.inc"
; FAT12 constants
.include "fat12.inc"
; DD-001 constants
.include "dd001-sym.inc"
; DD-001 memory locations and defines
.include "dd001-mem.inc"

.export Wedge_BUFFER
.export Wedge_tmpDEVNUM
.export Wedge_tmp1
.export Wedge_tmp2
.export Wedge_tmp3

		.segment "ram0200"

; unused space: $02A7-$02FF
Wedge_BUFFER:	.res 80	; (80) ; share with FdcFILELEN, FdcFILETEM?
Wedge_tmpDEVNUM: .res 1	; (1)
Wedge_tmp1:	.res 1	; (1)
Wedge_tmp2:	.res 1	; (1)
Wedge_tmp3:	.res 1	; (1)


		.segment "ram0300"

NewILOAD:	.res 2
NewISAVE:	.res 2
NewICKOUT:	.res 2
NewIOPEN:	.res 2
NewNMI:		.res 2

FdcST0:		.res 1 ; +0 (1)	Status Register 0
FdcST1:		.res 1 ; +1 (1)	Status Register 1
FdcST2:		.res 1 ; +2 (1)	Status Register 2
FdcC:		.res 1 ; +3 (1)	Cylinder
FdcH:		.res 1 ; +4 (1)	Head
FdcR:		.res 1 ; +5 (1)	Record = sector
FdcN:		.res 1 ; +6 (1)	Number of data bytes written into a sector
FdcST3:		.res 1 ; +7 (1)	Status Register 3
FdcPCN:		.res 1 ; +8 (1)	present cylinder = track
FdcCommand:	.res 1 ; +9 (1)
FdcHSEL:	.res 1	; +10 (1) head, shifted twice, needed for FDC commands
FdcTrack:	.res 1	; +11 (1)
FdcHead:	.res 1	; +12 (1)
FdcSector:	.res 1	; +13 (1)
FdcNumber:	.res 1	; +14 (1) bytes/sector during format, 2 = 512 b/s
FdcEOT:		.res 1	; +15 (1) end of track
FdcTrack2:	.res 1	; +18 (1) CYLIND; = FdcTrack and $FE  ???
TempStackPtr:	.res 1	; +20 (1) TSTACK; temporary storage for the stack pointer
FdcFormatData:	.res 4	; +22 (4) FRED; block of data used only by the format command (4 bytes but overwrites the 5th - following SCLUSTER)
FdcSCLUSTER:	.res 2	; +26 (2)
FdcLCLUSTER:	.res 2	; +28 (2)
FdcCLUSTER_2:	.res 2	; +32 (2) (3 occurences)
Counter:	.res 1	; +42 (1) TRYS
FdcHOWMANY:	.res 1	; +44 (1) (2 occurences)
DirSector:	.res 1	; +45 (1) DIRSEC; momentary directory sector
FdcFileName:	.res 30	; +48 (30) FILEBUF; temp storage for file name
FdcFILETEM:	.res 11	; +78 (11) storage for 8.3 filename (2 occurences, only RENAME)
FdcFILELEN:	.res 1	; +89 (1) filename length? (2 occurences, only RENAME)

StartofDir:	.res 1
EndofDir:	.res 1


DirectoryBuffer		= $D000	; buffer ($0200, 1 sector) for directory operations (FAT operations will take EndofDir, so expect this area to be overwritten)
FATBuffer		= $D200	; buffer ($0600, 3 sectors) for one whole FAT (set implicitly by taking EndofDir as start page)
; (note: if DirBuffer is put after FAT we could reduce this by 6 pages - only FAT needs to stay in memory during LOAD)
LoadSaveBuffer  	= $D800 ; buffer ($0400, 2 sectors) buffer for 1 cluster needed by LOAD/SAVE, must not overlap FATBuffer

; linker will update that
.import __romstack_RUN__
.import __romstack_SIZE__
.import __romstack_LOAD__
; wedge
.import DOSWedge_Reset
.import DOSWedge_Install
; for wedge
.export NewCkout

			.segment "rom8000"

			.assert *=$8000, error, "cartridge ROM must start at $8000"

			.word CartInit				; coldstart			[8087]
			.word CartNMI				; warmstart			[8DE7]
 
			.assert *=$8004, error, "cartridge signature CBM80 must be at $8004"
			.byte $C3, $C2, $CD, $38, $30		; CBM80, cartridge signature

			.assert *=$8009, error, "version and capabilities must be at $8009"
			.byte "DD01"	; magic
			.byte $12	; version 1.2
			.byte $01	; support for 1 drive
			.byte $02	; clusters have 2 sectors (1K allocation)

			.assert *=$8010, error, "jump table must be at $8010"
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
_SetSpace:		jmp	SetSpace		; [8039] -> [834B]
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
_SaveReloc:		jmp	SaveReloc		; [8063] -> [8472]
_ShowError:		jmp	ShowError		; [8069] -> [926C]
_StripSP:		jmp	StripSP			; [8072] -> [90A7]
_FindBlank:		jmp	FindBlank		; [8078] -> [8F4F]
_PadOut:		jmp	PadOut			; [807B] -> [90CE]
_StopWatchdog:		jmp	StopWatchdog		; [807E] -> [8DBD]
_RdDataRamDxxx:		jmp	RdDataRamDxxx		; [8081] -> [01A0]
_WrDataRamDxxx:		jmp	WrDataRamDxxx
_OpenDir:		jmp	OpenDir
_GetNextDirEntry:	jmp	GetNextDirEntry
_CloseDir:		jmp	CloseDir

; disk copy needs more functions:
; WaitRasterLine
; Wait4DataReady

; Here starts the initialisation of the cartridge
CartInit:				;				[8087]
	stx	$d016			; turn on VIC for PAL/NTSC check by Kernal
	sei
	cld
	ldx	#$FB
	txs				; set the stack pointer

	jsr	InitC64			;				[80F2]

@tryagain:
	jsr	TryAgain		; show message			[8124]
	beq	@done			; RUN/STOP pressed?		[80A8]
	jsr	LoadBootExe		; loading went OK?		[9294]
	bcc	@bootLoadDone		; yes, ->			[80AE]
@checkerr:
	CmpBI	ErrorCode, ERR_FILE_NOT_FOUND ; file not found?
	beq	@done			; yes, ->			[80A8]

	jmp	@tryagain		;				[808F]

; File "BOOT.PRG" not found, return control to BASIC
@done:	;jsr	InitC64			;				[80F2]
	jsr	StopWatchdog
	cli
	jsr	$E453			; cold start: BASIC vectors
	jsr	$E3BF			; cold start: BASIC ram init
	jsr	$E422			; cold start: startup message
	LoadB	CURDEVICE, DEVNUM	; make our device default
	LoadB	VICCTR1, $1b		; screen is visible
	jsr	DOSWedge_Reset		; install wedge
	jmp	$E37B			; warm start & loop

; Error found
@bootLoadDone:
	lda	ErrorCode		; error found?			[0351]
	bne	@checkerr		;				[8094]
; no error, run BOOT.PRG through BASIC
	PushW	ENDADDR			; ? needed
	jsr	$E453			; BASIC vectors
	jsr	$E3BF			; init BASIC RAM
	PopW	ENDADDR
	cli
	LoadB	VICCTR1, $1b
	lda	ENDADDR
	sta	$2d
	sta	$2f
	sta	$31
	lda	ENDADDR+1
	sta	$2e
	sta	$30
	sta	$32
	lda	#0			; basic start
	jsr	$A871			; clr
	jsr	$A533			; re-link
	jsr	$A68E			; set current character pointer to start of basic - 1
	jmp	$A7AE			; run

;**  Initialize the C64
InitC64:				;				[80F2]
	jsr	InitSidCIAIrq2		;				[FDA3]
	jsr	TestRAM2		;				[FD50]
	jsr	SetVectorsIO2		;				[FD15]
	jsr	InitialiseVIC2		;				[FF5B]

	; store original vectors of intercepted routines
	MoveW	ILOAD, NewILOAD
	MoveW	ISAVE, NewISAVE
	MoveW	ICKOUT, NewICKOUT
	MoveW	IOPEN, NewIOPEN
	MoveW	NmiVector, NewNMI

; Replace some routines by new ones (also called from NMI via RUN/STOP+RESTORE)
NewRoutines:				;				[80C0]
	lda	ResetFDC		; reset the FDC			[DF80]

	lda	#>DirectoryBuffer
	jsr	SetSpace

; Use the NMI routine of the cartridge as first routine for the C64
	lda	#<CartNMI
	sta	NmiVector		;				[0318]
	sta	NmiVectorRAM		;				[FFFA]

	lda	#>CartNMI
	sta	NmiVector+1		;				[0319]
	sta	NmiVectorRAM+1		;				[FFFB]

; Set the new LOAD, SAVE and CKOUT routines for the C64

	LoadW	ILOAD, NewLoad
	LoadW	ISAVE, NewSave
	LoadW	ICKOUT, NewCkout
	LoadW	IOPEN, NewOpen

	LoadB	COLOR, 1		; white on blue	

	jmp	DOSWedge_Install	; install wedge patch


;**  File "BOOT.EXE" has been found
TryAgain:				;				[8124]
	LoadB	VICCTR1, $1B		; screen on

	ldy	#0
:	lda	StartupTxt,y
	beq	:+
	jsr	KERNAL_CHROUT
	iny
	bne	:-
:

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

StartupTxt:
	.byte $93, 13, 13
	;      0123456789012345678901234567890123456789
	.byte "       *** DD-001 V1.2 (2023) ***"
	.byte 13
	.byte " ** FIXED AND UPDATED BY YTM/ELYSIUM **"
	.byte 13,13
	.byte " HTTPS://GITHUB.COM/YTMYTM/TIB-001-CART"
	.byte 13,13
	.byte " INSERT A 720K DISK OR PRESS RUN/STOP"
	.byte 13,13
	.byte " FDD AS DEVICE ",$30+DEVNUM
	.byte 13,13,13
	.byte 0
 
;**  Rename a file 
; in: (FNADR): [oldname]=[newname]"
; in: FNLEN offset to '=' character (?)
; in: FdcFILELEN offset to '"' character (?)
; changes: FdcFileName, FdcFILETEM
; out: ErrorCode, C=0 OK, C=1 ERROR
Rename:					;				[81C0]
	jsr	InitStackProg		;				[8D5A]
	jsr	WaitRasterLine		;				[8851]

	jsr	FindFile		; file found?			[8FEA]
	bcs	:+			; yes, -> 
	rts

:	ldy	FNLEN		;				[B7]
; ??? what is going on here ???
	clc
	cpy	FdcFILELEN		;				[0395]
	bne	:+			;				[81DF]
	lda	#ERR_FILE_NOT_FOUND
	jmp	ShowError		;				[926C]

:	ldx	#0
	iny

:	lda	(FNADR),Y	;				[BB]
	iny
	sta	FdcFileName,X		;				[036C]
	sta	FdcFILETEM,X		;				[038A]
	inx
	cpx	#FE_OFFS_NAME_END
	bne	:-

	ldy	#0
	lda	#'.'
:	cmp	FdcFileName,Y		;				[036C]
	beq	@found_dot
	iny
	cpy	#FE_OFFS_EXT
	bne	:-			;				[81F4]

	ldy	#0
:	lda	FdcFileName,Y		;				[036C]
	iny
	cmp	#'"'
	bne	:-			;				[8200]

	cpy	#FE_OFFS_NAME_END-1	; XXX off by one error?
	bcs	@err_longname
	dey

	lda	#' '
:	sta	FdcFileName,Y		;				[036C]
	iny
	cpy	#FE_OFFS_NAME_END
	bne	:-
	beq	@cont

@err_longname:
	LoadB	ErrorCode, ERR_NAME_TOO_LONG
	rts

@found_dot:
	tya
	pha

	ldx	#FE_OFFS_EXT
:	iny
	lda	FdcFILETEM,Y		;				[038A]
	sta	FdcFileName,X		;				[036C]
	inx
	cpx	#FE_OFFS_NAME_END
	bne	:-

	pla
	tay

	lda	#' '
:	sta	FdcFileName,Y		;				[036C]
	iny
	cpy	#FE_OFFS_EXT
	bne	:-			;				[8234]

@cont:	jsr	WaitRasterLine		;				[8851]

	PushW	Pointer

	PushB	DirSector
	jsr	Search			;				[9011]
	PopB	DirSector

	bcs	@err

	jsr	WaitRasterLine		;				[8851]

	jsr	LoadDirPointer

	LoadB	NumOfSectors, 1
	MoveB	DirSector, SectorL

	jsr	SetWatchdog		;				[8D90]
	jsr	SetupSector		;				[8899]
	jsr	SeekTrack		;				[898A]
	jsr	ReadSectors		;				[885E]
	jsr	SetWatchdog		;				[8D90]

	PopW	Pointer

	ldy	#0
:	lda	FdcFileName,Y		;				[036C]
	jsr	WrDataRamDxxx		;				[01AF]
	iny
	cpy	#FE_OFFS_NAME_END
	bne	:-

	jsr	WaitRasterLine		;				[8851]
	jsr	WriteDirectory		;				[850F]

	clc
	rts

@err:					; C=1 already here
	pla				; pop Pointer
	pla
	rts

;**  New routine for opening channel
; use OPEN15,7,15,"N:DISK" to issue command
NewOpen:
	CmpBI	CURDEVICE, DEVNUM	; our DD drive?
	bne	@org
	CmpBI	SECADR, 15		; channel 15?
	beq	@flen			; yes, a command
	jmp	$F707			; print "DEVICE NOT PRESENT" error
@flen:	lda	FNLEN			; is there a filename (command) provided?
	bne	__NewOpen		; yes, execute it
@org:	jmp	(NewIOPEN)		; no, fall back into Kernal, command can come from PRINT# (CKOUT)
	; prepare command from file name like wedge does, enclose command in quotes
__NewOpen:
	lda	#'"'
	sta	Wedge_BUFFER
	ldy	#0
	ldx	#1
:	lda	(FNADR),y
	sta	Wedge_BUFFER,x
	inx
	iny
	cpy	FNLEN
	bcc	:-
	lda	#'"'
	sta	Wedge_BUFFER,x
	inx
	stx	TempStore
	PushW	PtrBasText
	LoadW	PtrBasText, Wedge_BUFFER
	jsr	NewCkout
	PopW	PtrBasText
	clc				; no error
	rts

;**  New routine for printing into a channel
; manual says to use it for commands OPEN15,9,15:PRINT#15,"N:DISK"
; (there must be ending quote)
; (it must use channel 15)
NewCkout:				;				[8295]
	pha
	CmpBI	CURDEVICE, DEVNUM	; our DD drive?
	beq	__NewCkout		; yes, ->			[82A1]
	pla
	jmp	(NewICKOUT)
 
__NewCkout:
	sei
	tya
	pha
	txa
	pha

	ldy	#0
	lda	(PtrBasText),Y		;				[7A]
	cmp	#'"'			; quote found?
	bne	@end			; no -> exit, must start with quote
	iny

; Save current Y (but it must be 1)
	tya
	pha

; Check if the string between the quotes is not too long
; XXX it does the same thing as GetlengthFName just checks for bound (could set C flag about it, no?)
:	lda	(PtrBasText),Y		;				[7A]
	iny
	cpy	#$21			; 33 or more characters?
	bcs	@toolong		; yes, -> exit			[82D8]
	cmp	#'"'			; quote found?
	bne	:-			; must end with quote within 33 characters

; Restore original Y (but it must be 1)
	pla
	tay

	lda	(PtrBasText),Y		;				[7A]
; Handle as SCRATCH
	cmp	#'S'			; 'S' ?
	bne	:+
	lda	PtrBasText		;				[7A]
	addv	3
	sta	FNADR		;				[BB]
	MoveB	PtrBasText+1, FNADR+1
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
	sta	FNADR		;				[BB]
	MoveB	PtrBasText+1, FNADR+1
	jsr	RenameFilePrep
	jsr	Rename			;				[81C0]
	jmp	@end

; Handle as NEW = format disk
:	cmp	#'N'			; 'N' ?
	bne	@end

	lda	PtrBasText		;				[7A]
	addv	3
	sta	FNADR		;				[BB]
	MoveB	PtrBasText+1, FNADR+1
	jsr	FormatDisk		;				[89DB]

@end:	php
	jsr	ShowErrorCode
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
:	lda	(FNADR),Y	;				[BB]
	cmp	#'='
	beq	:+			;				[8325]
	iny
	bne	:-
:	tya
	pha
	jsr	GetlengthFName		;				[8336]
	MoveB	FNLEN, FdcFILELEN
	PopB	FNLEN
	rts


;**  Get the length of the file name between the quotes
GetlengthFName:				;				[8336]
	ldy	#1			; offset 1 - skip over start quote
; Look for a quote
:	lda	(PtrBasText),Y		;				[7A]
	cmp	#'"'			; end quote found?
	beq	:+			; yes, ->			[8341]
	iny
	bne	:-

:	tya
	iny
	sty	FNLEN		;				[B7]
	clc
	adc	PtrBasText		;				[7A]
	sta	PtrBasText		;				[7A]
	rts

; in: A - page number where directory will be loaded, need space for whole sector (2 pages)
SetSpace:				;				[834B]
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
	rts				; sec?

@found:	ldy	#FE_OFFS_NAME
	lda	#FE_DELETED		; means: file has been deleted
	jsr	WrDataRamDxxx		;				[01AF]
; Note: MS-DOS saves the first character

	PushW	Pointer
	jsr	WaitRasterLine		;				[8851]
	jsr	WriteDirectory		;				[850F]
	jsr	GetFATs			;				[8813]
	jsr	WaitRasterLine		;				[8851]
	PopW	Pointer

	jsr	ClearFATs		;				[8650]
	jsr	WriteFATs		;				[860C]

	clc
	rts


;**  Routine that replaces original SAVE routine of C64
; in: Kernal already stored to ENDADDR ($AE/F) X/Y (end address)
;     and to STARTADDR $C1/2 location pointed by A (start address)

NewSave:				;				[838A]
	CmpBI	CURDEVICE, DEVNUM	; our device?
	beq	__NewSave
	jmp	(NewISAVE)		;				[03FE]

__NewSave:
	lda	ENDADDR		;				[AE]
	sec
	sbc	STARTADDR		; minus start address LB
	sta	FdcLENGTH		; 				[0361]

	lda	ENDADDR+1		;				[AF]
	sbc	STARTADDR+1		; minus start address HB
	sta	FdcLENGTH+1		;				[0360]

; End address > start address?
	bcs	SaveDo			; yes, -> OK			[83B6]

; File too large
	LoadB	ErrorCode, ERR_FILE_TOO_LARGE
SaveExitErr:
	jsr	ShowErrorCode		;				[926C]
	lda	#3			; Kernal error code 3 = FILE NOT OPEN
	cli
	sec
	rts

; continue with save file
SaveDo:
	jsr	PrintSaving

	bit	MSGFLG			; are we in direct mode?
	bpl	:+			; no, skip that
	lda	#' '			; display load and end addresses, like Action Replay
	jsr	KERNAL_CHROUT
	lda	#'$'
	jsr	KERNAL_CHROUT
	ldx	#STARTADDR		; point to load address on zp
	jsr	PrintHexWord
	lda	#' '
	jsr	KERNAL_CHROUT
	lda	#'$'
	jsr	KERNAL_CHROUT
	ldx	#ENDADDR		; point to end address on zp
	jsr	PrintHexWord
	lda	#$0D
	jsr	KERNAL_CHROUT		; new line
:

	sei

	AddVW	2, FdcLENGTH		; add extra 2 bytes for load address
	MoveB	FdcLENGTH+1, FdcHOWMANY	; copy length in pages

	lsr	FdcHOWMANY	;				[0364]
	lsr	FdcHOWMANY	; length in pages/4+1				[0364]
	inc	FdcHOWMANY	; number of needed clusters (2 pages in sector, 2 sectors in cluster+one more for file remainder)

	jsr	InitStackProg		;				[8D5A]

	bbrf	6, FdcST3, :+		; WP bit set?
	LoadB	ErrorCode, ERR_DISK_WRITE_PROTECT	; yes -> error
	bne	SaveExitErr		; return with general error

:	jsr	GetFATs			;				[8813]
	jsr	FindFile		;				[8FEA]
	bcs	SaveOverwrite		; file exists, will be overwritten

	CmpBI	ErrorCode, ERR_FILE_NOT_FOUND
	beq	SaveNewFile		; not found - a new file will be saved

SaveExitErrScreenOn:
	jsr	StopWatchdog		; not needed in every code path but it doesn't hurt
	LoadB	VICCTR1, $1b		; screen on (hidden by GetFATs/FindFile)
	jmp	SaveExitErr		; error: different kind of error (I/O on FAT?)

SaveOverwrite:
	jsr	StopWatchdog		;				[8DBD]
	PushW	Pointer
	jsr	ClearFATs		;				[8650]
	PopW	Pointer
	jmp	SaveFillDirEntry	; skip over, we already have directory entry in Pointer

SaveNewFile:
	jsr	FindBlank		; find available directory entry
	lda	ErrorCode		; error found? DIRECTORY FULL	[0351]
	bne	SaveExitErrScreenOn

SaveFillDirEntry:
	jsr	StopWatchdog		;				[8DBD]
; here Pointer points to directory entry in DirectoryBuffer

	PushW	Pointer
	ldx	#0
	jsr	FindFAT			;				[85A8]
	PopW	Pointer

	ldy	#FE_OFFS_LAST_WRITE_TIME
	lda	#$79			; write time (1) 1991-08-05 01:35:50
	jsr	WrDataRamDxxx		;				[01AF]
	iny
	lda	#$0C			; write time (2)
	jsr	WrDataRamDxxx		;				[01AF]

	iny
	lda	#5			; write date (1)
	jsr	WrDataRamDxxx		;				[01AF]
	iny
	lda	#$17			; write date (2)
	jsr	WrDataRamDxxx		;				[01AF]

	iny
	lda	FdcCLUSTER		; start cluster lo		[035A]
	jsr	WrDataRamDxxx		;				[01AF]
	iny
	lda	FdcCLUSTER+1		; start cluster hi		[035B]
	jsr	WrDataRamDxxx		;				[01AF]

	iny
	lda	FdcLENGTH		; length lo			[0361]
	jsr	WrDataRamDxxx		;				[01AF]
	iny
	lda	FdcLENGTH+1		; length hi			[0360]
	jsr	WrDataRamDxxx		;				[01AF]
	iny
	lda	#0
	jsr	WrDataRamDxxx		; length+3
	iny
	jsr	WrDataRamDxxx		; length+4

SaveReloc:				;				[8472]
	MoveB	FdcHOWMANY, FdcNBUF

J_847D:					;				[847D]
	jsr	SeekTrack		;				[898A]

	LoadB	ErrorCode, ERR_OK

	jsr	WaitRasterLine		; why?				[8851]

	; handle first cluster differently because of load address
	LoadW	Pointer, LoadSaveBuffer
	ldy	#0
	lda	STARTADDR
	jsr	WrDataRamDxxx
	iny
	lda	STARTADDR+1
	jsr	WrDataRamDxxx

	LoadW	Z_FD, LoadSaveBuffer+2	; buffer starts with 2-byte offset
	LoadB	Z_FF, 4			; 4 pages in 2 sectors in 1 cluster
	ldx	#2			; first page starts without first 2 bytes
	ldy	#0
:	MoveW	STARTADDR, Pointer	; read from RAM
	jsr	RdDataRamDxxx
	pha
	MoveW	Z_FD, Pointer		; write to buffer
	pla
	jsr	WrDataRamDxxx
	IncW	STARTADDR		; next address
	IncW	Z_FD
	DecW	FdcLENGTH
	lda	FdcLENGTH
	ora	FdcLENGTH+1
	beq	:+			; nothing more left
	inx
	bne	:-			; until all bytes from page
	dec	Z_FF
	bne	:-			; until all pages

:	; reload Pointer to the buffer
	LoadW	Pointer, LoadSaveBuffer
	; do save that first cluster
	jsr	CalcFirst
	MoveW	FdcCLUSTER, FdcLCLUSTER
	jsr	SetupSector
	jsr	Delay41ms
	jsr	SeekTrack
	LoadB	NumOfSectors, 2		; 2 sectors in one cluster
	jsr	SetWatchdog
	jsr	WriteSector

	MoveW	STARTADDR, Pointer	; now copy adjusted load address to Pointer
	jmp	@loopend		; jump into the loop

	; this loop saves $0200 bytes each from Pointer until FdcNBUF is exausted
@loop:	jsr	CalcFirst		;				[883A]

	MoveW	FdcCLUSTER, FdcLCLUSTER

	jsr	SetupSector		;				[8899]
	jsr	Delay41ms		;				[89D0]
	jsr	SeekTrack		;				[898A]

	LoadB	NumOfSectors, 2		; 2 sectors, one cluster

	jsr	SetWatchdog		;				[8D90]
	jsr	WriteSector		;				[8BEE]
@loopend:
	jsr	StopWatchdog		;				[8DBD]

	lda	ErrorCode		; error found?			[0351]
	bne	A_8506			;				[8506]

	dec	FdcNBUF			; are we done?			[0364]
	beq	@end			; yes ->			[84E5]

	PushW	Pointer
	ldx	#1			; no, find next free cluster
	jsr	FindNextFAT		;				[85B2]
	bcc	:+			; no more FAT clusters free?
	jsr	MarkFAT			; mark cluster occupied		[8534]
	PopW	Pointer
	jmp	@loop			; save next cluster		[8493]

:	pla				; pop Pointer data if there was error
	pla
	LoadB	ErrorCode, ERR_FILE_TOO_LARGE ; is it rather 'DISK FULL'?
	jsr	StopWatchdog
	cli
	jmp	SaveExitErrScreenOn	; turn on screen and exit, directory and FAT were not updated yet, just exit

@end:	; file was saved
	jsr	Enfile			;				[8684]
	jsr	WaitRasterLine		;				[8851]
	jsr	WriteFATs		;				[860C]
	jsr	WriteDirectory		;				[850F]

	jsr	ShowErrorCode

	LoadB	VICCTR1, $1B		; screen on
	LoadB	STATUSIO, 0
	cli
	clc				; no error
	rts

	; if there is an error saving sector this seems like infinite loop
A_8506:					;				[8506]
	jsr	Specify			;				[891A]
	jsr	Recalibrate		;				[88F7]
	jmp	J_847D			;				[847D]

WriteDirectory:				;				[850F]

	LoadB	NumOfSectors, 1

	jsr	LoadDirPointer

	MoveB	DirSector, SectorL
	LoadB	SectorH, 0

	jsr	SetupSector		;				[8899]
	jsr	SeekTrack		;				[898A]
	jsr	SetWatchdog		;				[8D90]
	jsr	WriteSector		;				[8BEE]

	jmp	StopWatchdog		;				[8DBD]

MarkFAT:
	MoveB	FdcLCLUSTER+1, TempStore

	lda	FdcLCLUSTER		;				[0358]
	lsr	FdcLCLUSTER+1		;				[0359]
	ror	FdcLCLUSTER		;				[0358]
	pha

	and	#$FE
	clc
	adc	FdcLCLUSTER		;				[0358]
	sta	FdcLCLUSTER		;				[0358]

	lda	TempStore		;				[FA]
	adc	FdcLCLUSTER+1		;				[0359]
	sta	FdcLCLUSTER+1		;				[0359]

	MoveB	FdcLCLUSTER, Pointer

	lda	FdcLCLUSTER+1		;				[0359]
	adc	EndofDir		;				[0335]
	sta	Pointer+1		;				[FC]

	pla
	and	#1
	bne	:+

	ldy	#0
	lda	FdcSCLUSTER		;				[0356]
	jsr	WrDataRamDxxx		;				[01AF]
	iny
	jsr	RdDataRamDxxx		;				[01A0]
	and	#$F0
	ora	FdcSCLUSTER+1		;				[0357]
	jmp	WrDataRamDxxx

:	ldy	#1
	jsr	RdDataRamDxxx		;				[01A0]
	and	#$0F
	sta	TempStore		;				[FA]

	lda	FdcSCLUSTER		;				[0356]
	asl	A
	asl	A
	asl	A
	asl	A
	ora	TempStore		;				[FA]
	jsr	WrDataRamDxxx		;				[01AF]

	iny
	lda	FdcSCLUSTER		;				[0356]
	lsr	FdcSCLUSTER+1		;				[0357]
	ror	A
	lsr	FdcSCLUSTER+1		;				[0357]
	ror	A
	lsr	FdcSCLUSTER+1		;				[0357]
	ror	A
	lsr	FdcSCLUSTER+1		;				[0357]
	ror	A
	jsr	WrDataRamDxxx		;				[01AF]
	rts

FindFAT:				;				[85A8]
	LoadB	FdcSCLUSTER, 2
	LoadB	FdcSCLUSTER+1, 0

FindNextFAT:				;				[85B2]
	MoveW	FdcSCLUSTER, FdcCLUSTER

	jsr	GetNextCluster		;				[87A4]

	lda	FdcCLUSTER		;				[035A]
	ora	FdcCLUSTER+1		;				[035B]
	beq	:+

	IncW	FdcSCLUSTER
	CmpBI	FdcSCLUSTER+1, 2	; ???? XXX
	bne	FindNextFAT		;				[85B2]

	CmpBI	FdcSCLUSTER, $CA	; ???? XXX
	bne	FindNextFAT		;				[85B2]

	clc
	rts

:	MoveW	FdcSCLUSTER, FdcCLUSTER
	dex
	bmi	:+			;				[860A]

	IncW	FdcSCLUSTER
	jmp	FindNextFAT		;				[85B2]

:	sec
	rts

WriteFATs:				;				[860C]
	LoadB	NumOfSectors, DD_FAT_SIZE	; 3 sectors

	MoveB	EndofDir, Pointer+1	; FAT buffer starts right after directory buffer
	LoadB	Pointer, 0

	LoadB	SectorL, DD_SECT_FAT1	; starting on FAT1 sector
	LoadB	SectorH, 0

	jsr	SetupSector		;				[8899]
	jsr	SeekTrack		;				[898A]
	jsr	SetWatchdog		;				[8D90]
	jsr	WriteSector		;				[8BEE]
	jsr	StopWatchdog		;				[8DBD]

	MoveB	EndofDir, Pointer+1	; FAT buffer starts right after directory buffer
	LoadB	Pointer, 0

	LoadB	NumOfSectors, DD_FAT_SIZE	; 3 sectors

	LoadB	SectorL, DD_SECT_FAT2	; starting on FAT2 sector

	jsr	SetupSector		;				[8899]
	jsr	SeekTrack		;				[898A]
	jsr	SetWatchdog		;				[8D90]
	jsr	WriteSector		;				[8BEE]

	jmp	StopWatchdog		;				[8DBD]

ClearFATs:				;				[8650]
	ldy	#FE_OFFS_START_CLUSTER	; first cluster of a file
	jsr	RdDataRamDxxx		;				[01A0]
	sta	FdcCLUSTER		;				[035A]
	sta	FdcLCLUSTER		;				[0358]

	iny
	jsr	RdDataRamDxxx		;				[01A0]
	sta	FdcCLUSTER+1		;				[035B]
	sta	FdcLCLUSTER+1		;				[0359]

	LoadW	FdcSCLUSTER, 0

:	jsr	GetNextCluster		;				[87A4]
	jsr	MarkFAT			;				[8534]
	MoveW	FdcCLUSTER, FdcLCLUSTER
	CmpBI	FdcCLUSTER+1, $0F	; $0F=magic value for the end of file?
	bne	:-
	rts

Enfile:					;				[8684]
	MoveW	FdcCLUSTER, FdcLCLUSTER
	LoadW	FdcSCLUSTER, $0FFF	; ??? FAT magic?
	jmp	MarkFAT			;				[8534]


;**  Load the File BOOT.PRG into memory
LoadBootExe:				;				[9294]
	lda	#1
	ldx	#DEVNUM
	ldy	#1			; <>0 - load to address from file
	jsr	KERNAL_SETLFS
	lda	#BootExeNameEnd-BootExeName
	ldx	#<BootExeName
	ldy	#>BootExeName
	jsr	KERNAL_SETNAM
	lda	#0			; LOAD
;	jmp	NewLoad
	.assert * = NewLoad, error, "LoadBoot exe must fall through into NewLoad"
; New LOAD routine
; in:	X/Y = Load address 
;       A   = LOAD (0)  or   VERIFY (1) 
NewLoad:				;				[86BC]
	sei

	stx	ENDADDR		;				[AE]
	sty	ENDADDR+1		;				[AF]

	pha

	CmpBI	CURDEVICE, DEVNUM	; our device number?
	beq	__NewLoad

	pla
	jmp	(NewILOAD)		;				[03FC]

__NewLoad:
	PopB	FlgLoadVerify		; we ignore VERIFY but at least store the flag

	PushB	VICCTR1			; we don't know if we enter with screen on or off

	jsr	PrintSearchingFor	; Kernal code to display 'SEARCHING FOR ...'
	lda	#$0D
	jsr	KERNAL_CHROUT

	sei
	jsr	InitStackProg		;				[8D5A]
	jsr	FindFile		;				[8FEA]
	bcs	__LoadFileFound

	PopB	VICCTR1			; restore screen status

	jsr	ShowErrorCode
	LoadB	STATUSIO, 4		; file not found error
	sec
	rts


; File found
__LoadFileFound:
	jsr	PrintLoading		; Kernal code to display 'LOADING' or 'VERIFYING'
	CmpBI	FdcFileName, '$'	; directory wanted?
	bne	:+
	PopB	VICCTR1			; yes, restore stack
	jmp	LoadDir			; continue in special routine that maps directory entries to BASIC code into (ENDADDR)

:	sei
	ldy	#FE_OFFS_START_CLUSTER	; first cluster
	jsr	RdDataRamDxxx		;				[01A0]
	sta	FdcCLUSTER		;				[035A]
	iny
	jsr	RdDataRamDxxx		;				[01A0]
	sta	FdcCLUSTER+1		;				[035B]

	iny
	jsr	RdDataRamDxxx		; length			[01A0]
	iny
	sta	FdcLENGTH		;				[0361]
	jsr	RdDataRamDxxx		;				[01A0]
	iny
	sta	FdcLENGTH+1		;				[0360]
	jsr	RdDataRamDxxx		;				[01A0]
	iny
	sta	FdcLENGTH+2		; can't use it			[035F]
	jsr	RdDataRamDxxx		;				[01A0]
	sta	FdcLENGTH+3		; can't use it			[035E]

	jsr	GetFATs			;				[8813]
	jsr	CalcFirst		;				[883A]

	;; handle loadaddress
	LoadW	Pointer, LoadSaveBuffer	; load whole first cluster into buffer after FATs ($D800)
	LoadW	FdcBYTESLEFT, 2*DD_SECTOR_SIZE	; space for 1 cluster
	jsr	SetupSector
	jsr	SeekTrack
	LoadB	NumOfSectors, 2		; 1 cluster
	jsr	ReadSectors

	; load address from user or file?
	lda	SECADR
	beq	:+			; load address from user

	; read load address from file
	; restore pointer for RdDataRamDxxx
	LoadW	Pointer, LoadSaveBuffer
	ldy	#0
	jsr	RdDataRamDxxx
	sta	ENDADDR
	iny
	jsr	RdDataRamDxxx
	sta	ENDADDR+1

:	; ENDADDR is now LOADADDR target
	MoveW	ENDADDR, LOADADDR	; preserve load address (only to run BOOT)
	SubVW	2, FdcLENGTH		; filesystem length is 2 bytes more than data stream lenth
	; FdcLENGTH is intact
	LoadW	Z_FD, LoadSaveBuffer+2	; buffer starts with 2-byte offset
	LoadB	Z_FF, 4			; 4 pages in 2 sectors in 1 cluster
	ldx	#2			; first page starts without first 2 bytes
	ldy	#0
:	MoveW	Z_FD, Pointer		; read from Z_FD
	jsr	RdDataRamDxxx
	pha
	MoveW	ENDADDR, Pointer	; write to ENDADDR
	pla
	jsr	WrDataRamDxxx
	IncW	ENDADDR			; next address
	IncW	Z_FD
	DecW	FdcLENGTH
	lda	FdcLENGTH
	ora	FdcLENGTH+1		; is there anything left?
	beq	@done			; file shorter than 1K
	inx
	bne	:-			; until all bytes from page
	dec	Z_FF
	bne	:-			; until all pages
	; file is longer than 1 cluster
	jsr	GetNextCluster		;				[87A4]
	jsr	CalcFirst		; convert cluster to sector
	MoveW	ENDADDR, Pointer	; update Pointer from ENDADDR
	MoveW	FdcLENGTH, FdcBYTESLEFT	; count of what's left to load
@loop:
	jsr	SetupSector		;				[8899]
	jsr	SeekTrack		;				[898A]

	LoadB	NumOfSectors, 2		; 1 cluster
	jsr	ReadSectors		;				[885E]

	PushW	Pointer
	jsr	GetNextCluster		;				[87A4]
	PopW	Pointer

	CmpBI	FdcCLUSTER+1, $0F	; magic FAT value for end of file?
	beq	@done

	jsr	CalcFirst		; no, read next cluster
	jmp	@loop

@done:
	PopB	VICCTR1			; restore screen status
	AddW	FdcLENGTH, ENDADDR	; Kernal also sets ENDADDR to end of file

	bit	MSGFLG			; are we in direct mode?
	bpl	:+			; no, skip that
	lda	#' '			; display load and end addresses, like Action Replay
	jsr	KERNAL_CHROUT
	lda	#'$'
	jsr	KERNAL_CHROUT
	ldx	#LOADADDR		; point to load address on zp
	jsr	PrintHexWord
	lda	#' '
	jsr	KERNAL_CHROUT
	lda	#'$'
	jsr	KERNAL_CHROUT
	ldx	#ENDADDR		; point to end address on zp
	jsr	PrintHexWord
	lda	#$0D
	jsr	KERNAL_CHROUT		; new line
	jsr	ShowErrorCode

:	LoadB	STATUSIO, 0		; no error
	ldx	ENDADDR			; return end address in X/Y
	ldy	ENDADDR+1
	cli
	clc
	rts

GetNextCluster:				;				[87A4]
	MoveB	FdcCLUSTER+1, FdcCLUSTER_2+1

	lda	FdcCLUSTER		;				[035A]
	and	#$FE
	sta	FdcCLUSTER_2		;				[035C]

	lsr	FdcCLUSTER_2+1		;				[035D]
	ror	FdcCLUSTER_2		;				[035C]
	clc
	adc	FdcCLUSTER_2		;				[035C]
	sta	Pointer		;				[FB]

	lda	FdcCLUSTER_2+1		;				[035D]
	and	#$0F
	adc	EndofDir		;				[0335]
	clc
	adc	FdcCLUSTER+1		;				[035B]
	sta	Pointer+1		;				[FC]

	lda	FdcCLUSTER		;				[035A]
	and	#1
	bne	:+

	ldy	#0
	jsr	RdDataRamDxxx		;				[01A0]
	iny
	sta	FdcCLUSTER		;				[035A]
	jsr	RdDataRamDxxx		;				[01A0]
	and	#$0F
	sta	FdcCLUSTER+1		;				[035B]
	rts

:	ldy	#1
	lda	#0
	sta	FdcCLUSTER+1		;				[035B]

	jsr	RdDataRamDxxx		;				[01A0]

	iny
	and	#$F0
	lsr	A
	lsr	A
	lsr	A
	lsr	A
	sta	FdcCLUSTER		;				[035A]

	jsr	RdDataRamDxxx		;				[01A0]

	asl	A
	rol	FdcCLUSTER+1		;				[035B]
	asl	A
	rol	FdcCLUSTER+1		;				[035B]
	asl	A
	rol	FdcCLUSTER+1		;				[035B]
	asl	A
	rol	FdcCLUSTER+1		;				[035B]
	ora	FdcCLUSTER		;				[035A]
	sta	FdcCLUSTER		;				[035A]

	rts


; Load 3 sectors of the FAT table into RAM under the I/O from $D200 on
GetFATs:				;				[8813]
	LoadB	Pointer, 0
	MoveB	EndofDir, Pointer+1	; FAT buffer starts right after directory buffer

	LoadB	SectorL, DD_SECT_FAT1
	LoadB	SectorH, 0

	jsr	SetupSector		;				[8899]

	LoadB	FdcBYTESLEFT, 0

	LoadB	NumOfSectors, DD_FAT_SIZE	; 3 sectors
	asl	A			; A := 3*2 = 6 pages
	sta	FdcBYTESLEFT+1		; read this many bytes		[0363]

	jsr	ReadSectors		;				[885E]
	jmp	StopWatchdog		;				[8DBD]


; in: FdcCLUSTER (cluster number?)
; out: SectorL/H
; calc: out=in*2+10
CalcFirst:				;				[883A]
	MoveB	FdcCLUSTER+1, SectorH

	lda	FdcCLUSTER		;				[035A]
	asl	A
	rol	SectorH			;				[F9]
	addv	10
	sta	SectorL			;				[F8]
	bcc	:+
	inc	SectorH
:	rts


;**  Turn off the screen and Wait for rasterline $1FF
WaitRasterLine:				;				[8851]
	LoadB	VICCTR1, $0b		; screen off
:	CmpBI	VICLINE, $FF
	bne :-
	rts

;**  Read multiple sectors
; IMHO it reads 9 sectors = a complete track of one side
; XXX it also looks like 9 retries
ReadSectors:				;				[885E]

	LoadB	Counter, 0

@loop:	LoadB	ErrorCode, ERR_OK	; also 0 XXX

	jsr	WaitRasterLine		;				[8851]
	jsr	SetWatchdog		;				[8D90]
	jsr	ReadSector		;				[8C78]

	CmpBI	Counter, 9		; 9 retries?
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
	CmpBI	SectorH, >DD_TOTAL_SECTORS ; 1440
	bcc	:+
	CmpBI	SectorL, <DD_TOTAL_SECTORS
	bcs	@end			; exit but don't report any error?
; FYI: 5*256 + 160 = 1440 = number of sectors on 3.5" 720 KB disk
; BUG: if (SectorH > 5) and SectorL < 160) then routine continues as well

; Convert sector to track
:	ldx	#0			; tracks

:	lda	SectorL			;				[F8]
	subv	DD_SECTORS_PER_TRACK
	sta	SectorL			;				[F8]
	inx
	bcs	:-			; if SectorL > 8 then repeat	[88A9]

	lda	SectorH			; XXX BCS+DEC?			[F9]
	sbc	#0
	sta	SectorH			;				[F9]
	bcs	:-			; if SectorH > 0 then repeat	[88A9]

	dex
; Correct last subtraction
	AddVB	1+DD_SECTORS_PER_TRACK, SectorL	; one extra because FDC counts 1..9
	sta	FdcSector		;				[0349]
	inc	SectorH			; 				[F9]
	sta	FdcEOT			;				[034B]

	txa
	and	#1			; odd or even?
	sta	FdcHead			;				[0348]

	asl	A			; *4
	asl	A
	sta	FdcHSEL			;				[0346]

	txa
	lsr	A
	sta	FdcTrack		;				[0347]

	and	#$FE
	sta	FdcTrack2		;				[034E]
@end:	rts

;**  Recalibrate the drive
Recalibrate:				;				[88F7]
	jsr	Wait4FdcReady		;				[89C0]

	LoadB	DataRegister, 7		; ???
	jsr	Wait4DataReady		;				[89C8]

	LoadB	DataRegister, 0		; drive 0

:	jsr	SenseIrqStatus		;				[894A]
	bbrf	5, FdcST0, :-		; wait as long as 5th bit is 0
	lda	FdcPCN			; track = 0?			[0344]
	bne	:-			; no, -> wait			[8907]

;**  Sense the status of the drive
; XXX USED ONLY ONCE
SenseDrvStatus:				;				[8933]
	LoadB	DataRegister, $04	; ???
	jsr	Wait4DataReady		;				[89C8]

	LoadB 	DataRegister, 0		; select drive 0
					; head select = 0
	jsr	Wait4DataReady		;				[89C8]

	MoveB	DataRegister, FdcST3
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

:	bbsf	5, StatusRegister, :-	; wait as long as 5th bit is 1
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
	bbrf	5, FdcST0, :-		; wait as long as 5th bit is 0
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
Wait4DataReady:
:	bbrf	7, StatusRegister, :-
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


; format a disk in FAT12 filesystem with 1024 (2 sectors) cluster size
; in: (FNADDR) volume name, ends with '"' (copied from CKOUT)
FormatDisk:				;				[89DB]
	ldy	#0
:	lda	(FNADR),Y		;				[BB]
	cmp	#'"'			; stop at '"' or 11th character
	beq	:+
	sta	FdcFileName,Y		;				[036C]
	iny
	cpy	#FE_OFFS_NAME_END
	bne	:-

:	cpy	#FE_OFFS_NAME_END	; pad with spaces until 11 characters
	beq	:+
	lda	#' '
	sta	FdcFileName,Y		;				[036C]
	iny
	bne	:-

:	sei
	jsr	WaitRasterLine
	jsr	InitStackProg		;				[8D5A]

	bbrf	6, FdcST3, :+		; bit 6=0?, yes -> jump

	lda	#ERR_DISK_WRITE_PROTECT
	jmp	ShowError		;				[926C]

:	ldx	#15			; XXX define this constant
	jsr	ClearDirectory

	LoadB	FdcTrack2, 0
	LoadB	Counter, 1

FormatDiskLoop:
	LoadB	ErrorCode, ERR_OK

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

	jsr	LoadDirPointer		; directory sector buffer

	ldy	#0			; FAT12 identifier+BIOS Parameter Block
:	lda	BIOSParameterBlock,Y	;				[943E]
	jsr	WrDataRamDxxx		;				[01AF]
	iny
	cpy	#32
	bne	:-

	ldy	#$26
	lda	#$29			; DOS 4.1 signature
	jsr	WrDataRamDxxx
	iny				; randomize volume serial number
	lda	$a2			; jiffy low
	jsr	WrDataRamDxxx
	iny
	lda	VICLINE			; raster
	jsr	WrDataRamDxxx
	iny
	lda	$a1			; jiffy mid
	jsr	WrDataRamDxxx
	iny
	lda	$a0
	jsr	WrDataRamDxxx		; jiffy hi

	ldx	#0
:	iny
	lda	FdcFileName,x		; volume label
	jsr	WrDataRamDxxx
	inx
	cpx	#11
	bne	:-

	ldx	#0
:	iny
	lda	BIOSFileSystemType,x	; filesystem type
	jsr	WrDataRamDxxx
	inx
	cpx	#8
	bne	:-

	MoveB	EndofDir, Pointer+1	; FAT buffer starts right after directory buffer

	ldy	#0
	lda	#$F9			; $FFF9 - FAT#1 magic?
	jsr	WrDataRamDxxx		;				[01AF]
	iny
	lda	#$FF
	jsr	WrDataRamDxxx		;				[01AF]
	iny
	lda	#$FF
	jsr	WrDataRamDxxx		;				[01AF]

	lda	EndofDir
	addv	6			; XXX DD_FAT_SIZE*2 or dir buffer is included? $D000+$0200+3*$0200 = $D800; beyond fat#1, start of fat#2 ($D200+3*$0200)
	sta	Pointer+1

	ldy	#0
	lda	#$F9			; $FFF9 - FAT#2 magic?
	jsr	WrDataRamDxxx		;				[01AF]
	iny
	lda	#$FF
	jsr	WrDataRamDxxx		;				[01AF]
	iny
	lda	#$FF
	jsr	WrDataRamDxxx		;				[01AF]

	LoadB	NumOfSectors, 8		; BUG: 8 or 7? we will write first 8 sectors (boot + two fats + one more? (directory, but it's not cleared with zeros)
	LoadW	Sector, 0		; write staring from to boot sector

	jsr	SetupSector		;				[8899]
	jsr	SeekTrack		;				[898A]
	jsr	SetWatchdog		;				[8D90]

	jsr	LoadDirPointer		; set Pointer back to directory sector buffer (with boot sector data at the moment)

	jsr	WriteSector		; write all these sectors at once
	jsr	StopWatchdog		;				[8DBD]

	ldx	#1
	jsr	ClearDirectory

	jsr	LoadDirPointer		; set back to directory sector buffer, now for file entries

	tax				; A=0 here, after LoadDirPointer
	tay
:	lda	FdcFileName,X		; volume label			[036C]
	inx
	jsr	WrDataRamDxxx		;				[01AF]
	iny
	cpy	#FE_OFFS_NAME_END
	bne	:-
	lda	#FE_ATTR_VOLUME_ID	; volume label attribute
	jsr	WrDataRamDxxx		;				[01AF]

	LoadB	SectorL, DD_SECT_ROOT
	jsr	SetupSector		;				[8899]
	LoadB	NumOfSectors, 1
	jsr	SetWatchdog		;				[8D90]
	jsr	WriteSector		;				[8BEE]
	jsr	StopWatchdog		;				[8DBD]
	;we don't have to clear out all sectors occupied by root directory because FormatTrack does this for whole disk

@endok:	LoadB	VICCTR1, $1B		; screen on
	clc
	rts

@tryagain:
	dec	Counter			;				[0366]
	bpl	@enderr

	LoadB	ErrorCode, ERR_DISK_UNRELIABLE
	jsr	ShowError		;				[926C]
	jmp	@endok

@enderr:
	jsr	StopWatchdog		;				[8DBD]
	jsr	Specify			;				[891A]
	jsr	Recalibrate		;				[88F7]
	jmp	FormatDiskLoop


; clear pages starting at StartofDir page
; in: X = number of pages to clear-1 (1=only dir (2 pages), 7=directory+fat, 12=directory+fat+fat2)
;     changes Pointer
ClearDirectory:
	jsr	LoadDirPointer		; directory sector buffer
	tay				; A=0 here
:	jsr	WrDataRamDxxx		;				[01AF]
	iny
	bne	:-
	inc	Pointer+1		;				[FC]
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
:	bbrf	7, StatusRegister, :-	; wait as long as bit 7 is 0; FDC ready?
	lda	FdcCommand,Y		;				[0345]
	sta	DataRegister		;				[DE81]
	iny
	cpy	#9
	bne	:-

	ldx	#15			; retries
	ldy	#0
@loop:	bbrf	7, StatusRegister, @loop ; wait as long as bit 7 is 0

	lda	DataRegister
	beq	:+			;				[8B8A]

	LoadB	ErrorCode, ERR_DISK_WRITE_PROTECT
:	iny
	bne	@loop
	dex
	bpl	@loop
	jmp	ReadStatus		;				[8962]


;**  Format a track
FormatTrack:				;				[8B93]
	LoadB	FdcFormatData, $4D	; ???

	MoveB	FdcHSEL, FdcFormatData+1
	MoveB	FdcNumber, FdcFormatData+2
	LoadB	FdcFormatData+3, DD_SECTORS_PER_TRACK	; sectors / track
	LoadB	FdcFormatData+4, $54	; gap length, see datasheet
	LoadB	FdcFormatData+5, 0

	ldy	#0
:	bbrf	7, StatusRegister, :-	; wait as long as bit 7 is 0; FDC ready?
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
:	bbrf	7, StatusRegister, :-	; wait as long as bit 7 is 0; FDC ready?
	sta	DataRegister		;				[DE81]
	iny
	cpy	#$04			; supplied neede 5 bytes?
	bne	:--
	inc	FdcSector		; next sector			[0349]
	dex				; nine sectors done?
	bpl	@loop			; no, -> more			[8BCC]

A_8BE4:					;				[8BE4]
:	bbsf	5, StatusRegister, :-	; wait as long as bit 5 is 1; execution finished?
	jmp	ReadStatus		;				[8962]


;**  Write one or more sector to the disk
WriteSector:				;				[8BEE]
	ldy	#0
	LoadB	FdcCommand, $65		; code for "write sector"

:	bbrf	7, StatusRegister, :-	; wait as long as bit 7 is 0; FDC ready?
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
@retry:	dec	Pointer+1		;				[FC]
	dec	Pointer+1		;				[FC]

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
:	bbrf	7, StatusRegister, :-	; wait as long as bit 7 is 0; FDC ready?
	lda	FdcCommand,Y		;				[0345]
	sta	DataRegister		;				[DE81]
	iny
	cpy	#9			; nine bytes written?
	bne	:-

	CmpBI	FdcBYTESLEFT+1, 2
	bcs	@sector			;				[8CB7]

	and	#1
	beq	@part			;				[8CB1]

	MoveB	FdcBYTESLEFT, L_0165+1	; number of bytes to read after	first 256 bytes

	ldy	#0			; start with reading 256 bytes

	LoadB	NumOfSectors, 1

	jsr	RdBytesSector		;				[0139]
	jmp	@cont

; part of page
@part:	MoveB	FdcBYTESLEFT, L_0119+1
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

@retry:	dec	Pointer+1		;				[FC]
	dec	Pointer+1		;				[FC]
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
	CmpBI	FdcBYTESLEFT+1, 2	;				[0363]
	bcc	A_8D36			;				[8D36]

	subv	2
	sta	FdcBYTESLEFT+1		;				[0363]
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

;**  Initialize the program that should run in the stack page
InitStackProg:				;				[8D5A]
; Preset the "Read data" command,
	ldx	#8
:	lda	CmdReadData,X		;				[8D77]
	sta	FdcCommand,X		;				[0345]
	dex
	bpl	:-

; Actual copy
	ldx	#0
:	lda	__romstack_LOAD__,X		;				[9462]
	sta	__romstack_RUN__,X	;				[0101]
	inx
	cpx	#<(__romstack_SIZE__+1)
	bne	:-

	jsr	Specify			;				[891A]
	jmp	Recalibrate

;**  Bytes need for the command "Read data"  IMHO
; XXX check datasheet
CmdReadData:				;				[8D77]
.byte $66, $00, $02, $00, $01, $02, $01, $1B, $FF 


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


; NMI routine is used by the watchdog timer from CIA2, it's not connected to the cartridge
CartNMI:				;				[8DE7]
	pha
	PushB	CPU_PORT
	LoadB	CPU_PORT, $37		; ROM+I/O

	lda	CIA2IRQ			; XXX what is bit 7 and 2?
	bpl	:+			; branch if bit 7=0
	and	#%00000010		; bit 1 meaning? timeout on operation?
	beq	:+			; branch if bit 1=0

	inc	ErrorCode		; XXX ??? why (to be 1?)	[0351]
	ldx	TempStackPtr		; XXX ??? why 			[0350]
	txs				; ? abort current operation and return to caller (before TempStackPtr was saved?)
	lda	ResetFDC		; reset the FDC			[DF80]
	jmp	StopWatchdog		;				[8DBD]

:	jsr	NewRoutines		;				[80C0]
	PopB	CPU_PORT
	txa
	pha
	tya
	pha
	jsr	IncrClock22		;				[F6BC]
	jsr	KERNAL_STOP		;				[FFE1]
	beq	:+			; run/stop? do the RUN/STOP+RESTORE routine
	pla
	tay
	pla
	tax
	pla
	rti

:	jsr	InitSidCIAIrq2		;				[FDA3]
	jsr	InitScreenKeyb		;				[E518]
	LoadB	COLOR, 1		; white on blue	
	jmp	(BasicNMI)		;				[A002]


; set Pointer to StartofDir*$0100, return with 0 in A
LoadDirPointer:
	MoveB	StartofDir, Pointer+1
	LoadB	Pointer, 0
	rts

ReadDirectory:				;				[8E0F]
	LoadB	NumOfSectors, 1
	LoadB	Counter, 0
@repeat:				;				[8E18]
	jsr	LoadDirPointer
	sta	ErrorCode		; A=0 here
	sta	SectorH
	MoveB	Z_FF, SectorL

	jsr	SetupSector		;				[8899]

	jsr	SeekTrack		;				[898A]
	jsr	SetWatchdog		;				[8D90]
	jsr	WaitRasterLine		;				[8851]

	LoadW	FdcBYTESLEFT, DD_SECTOR_SIZE	; whole sector

	jsr	ReadSector		;				[8C78]

	CmpBI	Counter, 9		; retries? whole track?
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
	jmp	@repeat			;				[8E18]


; out: A=ErrorCode
; Pointer, Z_FF must not be changed until CloseDir
OpenDir:
        php
        sei
        PushB   VICCTR1
        LoadB   VICCTR1, $0b
        jsr     InitStackProg
        LoadB   Z_FF, DD_SECT_ROOT      ; start sector of root dir
        jsr     ReadDirectory           ;                               [8E0F]
        jsr     StopWatchdog            ;                               [8DBD]
        jsr     GetFATs                 ;                               [8813]
        PopB    VICCTR1
        plp
        jsr	LoadDirPointer		; setup pointer to StartofDir page (under I/O)
        lda     ErrorCode               ; error found?                  [0351]
        rts


; in: A=device
; not sure if this is necessary
CloseDir:
        LoadB   VICCTR1, $1B
        jsr     StopWatchdog            ;                               [8DBD]
        LoadB   ErrorCode, ERR_OK
        rts

; copy 32 bytes of FAT dir entry to FdcFileName buffer
; Pointer, Z_FF must not be changed until CloseDir
; out: A=0 ok, A<>0 error or end of dir
GetNextDirEntry:
	lda	Pointer			; end of dir from last call
	ora	Pointer+1
	bne	:+
	lda	#ERR_NO_MORE_DIRECTORY_SPACE
	rts

	; copy 32 bytes of FAT dir entry to FdcFileName buffer (spills into FdcFILETEM but that's not a problem)
:	php
	sei
	ldy	#0
:	jsr	RdDataRamDxxx
	sta	FdcFileName,y
	iny
	cpy	#FILE_ENTRY_SIZE
	bne	:-

	; prepare next dir entry, reset pointer to 0 if end of dir
	AddVW	FILE_ENTRY_SIZE, Pointer	; next directory entry
	CmpB	Pointer+1, EndofDir	; last page of directory buffer?
	beq	:+
	lda	ErrorCode		; no, keep going
	plp
	rts

:	inc	Z_FF
	CmpBI	Z_FF, DD_SECT_ROOT+DD_NUM_ROOTDIR_SECTORS ; whole directory read? (7 sectors but this counts pages, we could also count file entries up to DD_ROOT_ENTRIES)
	bcs	:+			; yes -> end			[8F46]

	sei
	PushB	VICCTR1
	LoadB	VICCTR1, $0b
	jsr	ReadDirectory		;				[8E0F]
	jsr	StopWatchdog		;				[8DBD]
	PopB	VICCTR1
	; reload pointer to start of buffer
	jsr	LoadDirPointer
	lda	ErrorCode
	plp
	rts

:	LoadW	Pointer, 0		; mark that it's the end of dir
	lda	ErrorCode
	plp
	rts


;**  Display the directory
DisplayDir:
	jsr	OpenDir
	tax
	beq	@loop			; error found?
	sec
	rts

@loop:
	jsr	GetNextDirEntry
	tax
	bne	@end

	lda	FdcFileName+FE_OFFS_NAME
	cmp	#FE_EMPTY		; empty file entry? (note: it's 0)
	beq	@end			; yes, end of directory
	cmp	#FE_DELETED		; deleted file entry?
	beq	@loop			; yes, next file entry

	lda	FdcFileName+FE_OFFS_START_CLUSTER
	ora	FdcFileName+FE_OFFS_START_CLUSTER+1
	beq	@loop			; cluster=0 -> this is VFAT long file name, skip to next file entry

	jsr	ConvertDirEntryToBASIC
	stx	TempStore

	ldx	Wedge_BUFFER+2		; filesize lo
	lda	Wedge_BUFFER+3
	jsr	PrintIntegerXA
	lda	#' '
	jsr	KERNAL_CHROUT

	ldy	#4
:	lda	Wedge_BUFFER,y		; print out until end of line marker
	beq	:+
	jsr	KERNAL_CHROUT
	iny
	cpy	TempStore
	bne	:-

:	lda	#$92			; RVS OFF (needed only once)
	jsr	KERNAL_CHROUT
	lda	#13			; new line
	jsr	KERNAL_CHROUT
	jsr	KERNAL_STOP		; run/stop?
	beq	@end			; yes -> end
	jmp	@loop

@end:	jsr	CloseDir
	jmp	ShowBytesFree



; in: X, offset into Wedge_BUFFER
; out: next X
WriteDirBASICByte:
	sta	Wedge_BUFFER,x
	inx
	rts

; convert FAT dir entry in FdcFileName buffer into BASIC line in Wedge_BUFFER
; in: FdcFileName (must be valid: no FE_EMPTY/FE_DELETED)
; out: Wedge_BUFFER filled up to X (points to byte past the needed one)
;      changes LOADADDR (don't know if that's an issue with LOAD+BASIC)
ConvertDirEntryToBASIC:
	ldx	#0

	lda	#1
	jsr	WriteDirBASICByte	; line link $0101, BASIC fixes that
	jsr	WriteDirBASICByte

	lda	FdcFileName+FE_OFFS_ATTR
	cmp	#FE_ATTR_VOLUME_ID	; is that entry volume id?
	bne	@fileentry		; no

; this part displays volume name, without extension, with ASCII to PETSCII conversion
	lda	#0			; line number
	jsr	WriteDirBASICByte
	jsr	WriteDirBASICByte
	lda	#$12			; RVS ON
	jsr	WriteDirBASICByte
	lda	#'"'
	jsr	WriteDirBASICByte

	ldy	#FE_OFFS_NAME
:	lda	FdcFileName,y
	cmp	#$60			; < 'a' ?
	bcc	:+			; yes, ->			[8EA6]
	subv	$20			; convert to PETSCII
:	jsr	WriteDirBASICByte
	iny
	cpy	#FE_OFFS_NAME_END
	bne	:--

	lda	#' '
:	jsr	WriteDirBASICByte	; pad to 16 characters
	iny
	cpy	#16
	bne	:-

	lda	#'"'
	jsr	WriteDirBASICByte
	lda	#' '
	jsr	WriteDirBASICByte
	lda	#'D'			; disk id = 'DD'
	jsr	WriteDirBASICByte
	jsr	WriteDirBASICByte
	lda	#' '
	jsr	WriteDirBASICByte
	lda	#'2'			; DOS id = '2A'
	jsr	WriteDirBASICByte
	lda	#'A'
	jsr	WriteDirBASICByte
	lda	#0			; end of line marker
	jmp	WriteDirBASICByte

; this part displays file entries, without ASCII to PETSCII convert
@fileentry:
	MoveW	FdcFileName+FE_OFFS_SIZE+1, LOADADDR ; skip over lowest byte
	lda	FdcFileName+FE_OFFS_SIZE
	beq	:+
	IncW	LOADADDR		; +1 sector if lowest byte is non-zero
:	lda	LOADADDR
	jsr	WriteDirBASICByte
	lda	LOADADDR+1
	jsr	WriteDirBASICByte

	CmpWI	LOADADDR, 100
	bcs	:+
	lda	#' '			; align for numbers <100
	jsr	WriteDirBASICByte
	CmpBI	LOADADDR, 10
	bcs	:+
	lda	#' '			; align for numbers <10
	jsr	WriteDirBASICByte

:	lda	#' '
	jsr	WriteDirBASICByte
	lda	#'"'
	jsr	WriteDirBASICByte

	ldy	#FE_OFFS_NAME		; filename always 8.3 with padded spaces
:	lda	FdcFileName,y
	jsr	WriteDirBASICByte
	iny
	cpy	#FE_OFFS_EXT
	bne	:+
	lda	#'.'
	jsr	WriteDirBASICByte
:	cpy	#FE_OFFS_NAME_END
	bne	:--

	lda	#'"'
	jsr	WriteDirBASICByte

	lda	#' '
:	jsr	WriteDirBASICByte	; pad to 16 characters
	iny
	cpy	#15			; 15 not 16 because there is a dot already in the name
	bne	:-

	lda	FdcFileName+FE_OFFS_ATTR
	pha				; remember attribute
	and	#FE_ATTR_HIDDEN		; hidden?
	beq	:+
	lda	#'*'			; show as splat file
	.byte	$2c
:	lda	#' '
	jsr	WriteDirBASICByte

	pla				; attribute
	pha				; remember again
	and	#FE_ATTR_DIRECTORY	; directory?
	beq	@prg
	lda	#'D'
	jsr	WriteDirBASICByte
	lda	#'I'
	jsr	WriteDirBASICByte
	lda	#'R'
	jsr	WriteDirBASICByte
	bne	:+
@prg:	lda	#'P'
	jsr	WriteDirBASICByte
	lda	#'R'
	jsr	WriteDirBASICByte
	lda	#'G'
	jsr	WriteDirBASICByte

:	pla				; attribute
	and	#FE_ATTR_READ_ONLY	; read only?
	beq	:+
	lda	#'<'
	.byte	$2c
:	lda	#' '
	jsr	WriteDirBASICByte
	lda	#' '
	jsr	WriteDirBASICByte	; one extra space at the end

	lda	#0			; end of line marker
	jmp	WriteDirBASICByte



; almost the same as DisplayDir but for loading dir as BASIC code
LoadDir:
	lda	SECADR			; load address from user or file?
	beq	:+			; from user
	LoadW	ENDADDR, $0401		; that's VIC / 1541 default

:	jsr	OpenDir
	tax
	beq	@loop			; error found?
	sec				; XXX exit properly with error from LOAD
	rts

@loop:
	jsr	GetNextDirEntry
	tax
	bne	@end

	lda	FdcFileName+FE_OFFS_NAME
	cmp	#FE_EMPTY		; empty file entry? (note: it's 0)
	beq	@end			; yes, end of directory
	cmp	#FE_DELETED		; deleted file entry?
	beq	@loop			; yes, next file entry
	lda	FdcFileName+FE_OFFS_START_CLUSTER
	ora	FdcFileName+FE_OFFS_START_CLUSTER+1
	beq	@loop			; cluster=0 -> this is VFAT long file name, skip to next file entry

	jsr	ConvertDirEntryToBASIC
	stx	TempStore
	ldy	#0
:	lda	Wedge_BUFFER,y		; copy line
	sta	(ENDADDR),y
	iny
	cpy	TempStore
	bne	:-
	AddB	TempStore, ENDADDR
	bcc	:+
	inc	ENDADDR+1
:	jmp	@loop			; next dir entry

@end:	jsr	CloseDir
	jsr	GetBlocksFree		; A(lo)/X(hi) number of free blocks
	tay				; lo
	txa
	pha				; hi
	tya
	pha				; lo

	ldy	#0
	lda	#1			; BASIC line link $0101
	sta	(ENDADDR),y
	iny
	sta	(ENDADDR),y
	iny

	pla				; blocks lo
	sta	(ENDADDR),y
	iny
	pla				; blocks hi
	sta	(ENDADDR),y
	iny

	ldx	#0
:	lda	BlocksFreeTxt,x
	beq	:+
	sta	(ENDADDR),y
	iny
	inx
	bne	:-

	; three zeros at the end
:	sta	(ENDADDR),y
	iny
	sta	(ENDADDR),y
	iny
	sta	(ENDADDR),y
	iny
	tya
	add	ENDADDR
	sta	ENDADDR
	bcc	:+
	inc	ENDADDR+1
:

	; the same ending as in NewLoad (XXX could start even earlier right after @done to display load/end addr)
	LoadB	STATUSIO, 0		; no error
	ldx	ENDADDR			; return end address in X/Y
	ldy	ENDADDR+1
	cli
	clc
	rts



; scan directory for available directory entry for a new file
; in: FdcFileName
; out: C=1 error (file exists or otherwise), C=0 ok and FdcFileName copied to that file entry
FindBlank:				;				[8F4F]
	LoadB	FdcNBUF, DD_NUM_ROOTDIR_SECTORS
	LoadB	SectorL, DD_SECT_ROOT	; XXX optimization, directory starts at sector 7
	sta	DirSector
	LoadB	SectorH, 0

	jsr	SetupSector		;				[8899]
A_8F62:					;				[8F62]
	jsr	LoadDirPointer

	LoadB	NumOfSectors, 1
	asl	A			; A:=2 -> $0200 in FdcBYTESLEFT,9
	sta	FdcBYTESLEFT+1		;				[0363]
	LoadB	FdcBYTESLEFT, 0

	jsr	ReadSectors		;				[885E]
	lda	ErrorCode		; error found?			[0351]
	beq	@noerr			;				[8F82]

	clc
	rts

@noerr:	jsr	LoadDirPointer
A_8F8B:					;				[8F8B]
	ldx	#0
	ldy	#FE_OFFS_NAME
:	jsr	RdDataRamDxxx		;				[01A0]
	iny
	cmp	#FE_EMPTY
	beq	A_8FD3			;				[8FD3]
	cmp	#FE_DELETED
	beq	A_8FD3			;				[8FD3]
	cmp	FdcFileName,X		; ????				[036C]
	bne	A_8FA7			;				[8FA7]
	inx
	cpx	#FE_OFFS_NAME_END-1	; XXX bug, should be without -1 because we count up
	bne	:-

	sec				; C=1 and ErrorCode=0 if file exists?
	rts

A_8FA7:					;				[8FA7]
	AddVW	FILE_ENTRY_SIZE, Pointer
	CmpB	Pointer+1, EndofDir	;				[0335]
	bne	A_8F8B			;				[8F8B]

	lda	DirSector		;				[0369]
	addv	1
	sta	SectorL			;				[F8]
	sta	DirSector		;				[0369]

	jsr	SetupSector		;				[8899]

	dec	FdcNBUF		;				[0364]
	bpl	A_8F62			; read next directory sector	[8F62]

	LoadB	ErrorCode, ERR_NO_MORE_DIRECTORY_SPACE

	clc
	rts

A_8FD3:					; found empty entry		[8FD3]
	ldy	#FILE_ENTRY_SIZE-1	; clear whole file entry
	lda	#0
:	jsr	WrDataRamDxxx		;				[01AF]
	dey
	bpl	:-

	ldy	#FE_OFFS_NAME_END-1	; copy filename from FdcFileName there
:	lda	FdcFileName,Y		;				[036C]
	jsr	WrDataRamDxxx		;				[01AF]
	dey
	bpl	:-
	clc				; no error
	rts


;**  Check the file name
; in: (FNADR), FNLEN
; changes FdcFileName
; out: C=1 file found, C=0 file not found, and another error in ErrorCode
FindFile:				;				[8FEA]
	lda	FNLEN		; file name present?		[B7]
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
	sec				; found
	rts



;**  Search for a file
; in: FdcFileName
; out: C=1 file found, C=0 file not found, and another error can be in ErrorCode
Search:					;				[9011]
	LoadB	FdcNBUF, DD_NUM_ROOTDIR_SECTORS-1	; why not 7?

	LoadB	SectorL, DD_SECT_ROOT	; directory starts at sector 7
	sta	DirSector		;				[0369]
	LoadB	SectorH, 0

	jsr	SetupSector		;				[8899]
A_9024:
	jsr	LoadDirPointer

	LoadB	NumOfSectors, 1
	asl	A			; A:=2 -> $0200 in FdcBYTESLEFT
	sta	FdcBYTESLEFT+1		;				[0363]
	LoadB	FdcBYTESLEFT, 0

	jsr	ReadSectors		;				[885E]

	lda	ErrorCode		; error found?			[0351]
	beq	A_9044			; no, -> continue		[9044]

	clc
	rts


; Read the directory under the $Dxxx area
A_9044:					;				[9044]
	jsr	LoadDirPointer

	ldy	#FE_OFFS_NAME
A_904F:					;				[904F]
	ldx	#0
	jsr	RdDataRamDxxx		;				[01A0]

	cmp	#FE_EMPTY		; skip if empty but why check twice? XXX
	beq	A_90A0			;				[90A0]
A_9058:					;				[9058]
	jsr	RdDataRamDxxx		;				[01A0]

	iny

	cmp	#FE_EMPTY		; empty file entry?
	beq	A_9079			; yes, ->			[9079]
	cmp	#FE_DELETED		; or deleted file?
	beq	A_9079			;				[9079]

	cmp	FdcFileName,X		; same as wanted name?		[036C]
	beq	A_9072			; yes, ->			[9072]

	lda	FdcFileName,X		;				[036C]
	cmp	#'*'			; wild card
	beq	A_9077			; yes, -> name found		[9077]
	bne	A_9079			; always ->			[9079]

A_9072:					;				[9072]
	inx
	cpx	#FE_OFFS_NAME_END	; eleven characters checked?
	bne	A_9058			; no, -> more			[9058]

; Name has been found
A_9077:					;				[9077]
	sec
	rts

A_9079:					;				[9079]
	ldy	#0

	AddVW	FILE_ENTRY_SIZE, Pointer
	CmpB	Pointer+1, EndofDir	; end of directory sector?	[0335]
	bne	A_904F			; no, -> more			[904F]

; Go to the next directory sector
	lda	DirSector		;				[0369]
	addv	1
	sta	SectorL			;				[F8]
	sta	DirSector		;				[0369]

	jsr	SetupSector		;				[8899]

	dec	FdcNBUF		; searched all dir sectors?	[0364]
	bpl	A_9024			; no, -> next one		[9024]
A_90A0:	
	LoadB	ErrorCode, ERR_FILE_NOT_FOUND

	clc
	rts


; Strip spaces? Reverse of PadOut?
; in: (FNADR), FNLEN
; out: (FNADR), uses FdcFileName as a work area
StripSP:				;				[90A7]
	ldy	#0
	ldx	#0

:	lda	(FNADR),Y	;				[BB]
	iny
	cmp	#' '
	beq	:+			; skip copying spaces	[90B8]

	sta	FdcFileName,X		;				[036C]
	inx
:	cpy	FNLEN			; whole name copied?		[B7]
	bne	:--			; no, -> next character		[90AB]

	lda	#0
	sta	FdcFileName,X		; zero end the name		[036C]

	stx	FNLEN
	ldy	#0
:	lda	FdcFileName,Y
	sta	(FNADR),Y
	iny
	cpy	FNLEN
	bne	:-
	rts

; in (FNADR), FNLEN in 'xx.zz'
; out: FdcFileName in 'xx       zz ' normalized for directory entry
PadOut:					;				[90CE]
	ldy	#0
	lda	#'$'			; '$' = directory wanted
	cmp	(FNADR),Y
	bne	:+
	sta	FdcFileName
	rts

:	lda	(FNADR),Y		;				[BB]
	cmp	#'.'			; dot?
	beq	@dotfound		; yes, -> 			[9107]
	iny
	cpy	FNLEN			; end of the name?		[B7]
	bne	:-			; no, -> next character		[90D0]

	ldy	#0
:	lda	FdcFileName,Y		;				[036C]
	iny
	cmp	#0			; end of the name found?
	bne	:-			; no, -> next character		[90E9]
	cpy	#FE_OFFS_NAME_END-1	; tenth character or more?
	bcs	@err			; yes, -> error			[9101]

; Fill up with spaces
	dey
:	lda	#' '
	sta	FdcFileName,Y		;				[036C]
	iny
	cpy	#FE_OFFS_NAME_END	; ten chars done?
	bne	:-
	rts

@err:	LoadB	ErrorCode, ERR_NAME_TOO_LONG
	rts

; Dot found, copy extension
@dotfound:					;				[9107]
	tya
	pha				; save Y

	ldx	#FE_OFFS_EXT
:	iny
	lda	(FNADR),Y	;				[BB]
	sta	FdcFileName,X		;				[036C]
	inx
	cpx	#FE_OFFS_NAME_END
	bne	:-

	pla
	tay				; restore Y
	cpy	#FE_OFFS_EXT
	beq	:++

; Fill up with spaces
	lda	#' '
:	sta	FdcFileName,Y		;				[036C]
	iny
	cpy	#FE_OFFS_EXT
	bne	:-
:	rts



; in: none
; out: A(lo)/X(hi) number of free blocks
GetBlocksFree:
	php
	PushW	Pointer			; preserve pointer because GetNextCluster will destroy it
	sei

	LoadW	FdcLENGTH, 0
	sta	FdcLENGTH+2		;				[0360]

	LoadW	FdcSCLUSTER, $0002
					;				[9180]
@loop:	MoveW	FdcSCLUSTER, FdcCLUSTER

	jsr	GetNextCluster		;				[87A4]

	lda	FdcCLUSTER		;				[035A]
	ora	FdcCLUSTER+1		;				[035B]
	bne	:+			;				[919F]

	IncW	FdcLENGTH+1		; yes - 16-bits FdcLENGTH+1/+2
:	IncW	FdcSCLUSTER
	CmpBI	FdcSCLUSTER+1, 2
	bne	@loop			;				[9180]

	CmpBI	FdcSCLUSTER, $CB	; XXX what is $CB?
	bne	@loop			;				[9180]

	; to bytes - * $0400
	asl	FdcLENGTH+1		;				[035F]
	rol	FdcLENGTH+2		;				[0360]
	asl	FdcLENGTH+1		;				[035F]
	rol	FdcLENGTH+2		;				[0360]
	; to blocks - * $0400 / $0100

	PopW	Pointer
	plp
	ldx	FdcLENGTH+2		; hi
	lda	FdcLENGTH+1		; lo
	rts

ShowBytesFree:
	jsr	GetBlocksFree
	; swap X/A to make X low, A hi
	ldx	FdcLENGTH+1		; lo
	lda	FdcLENGTH+2		; hi
	jsr	PrintIntegerXA

; print out message
	lda	#<BlocksFreeTxt
	ldy	#>BlocksFreeTxt
	jmp	PrintString

BlocksFreeTxt:	.byte " BLOCKS FREE.", 13, 0



;**  Show an error message
ShowErrorCode:
	lda	ErrorCode
ShowError:				;				[926C]
	ldx	MSGFLG			; direct mode?			[9D]
	bmi	:+			; yes, -> display error		[9271]
	rts

:	pha
	jsr	StopWatchdog
	pla
	tax
	lda	TblErrorMsgH,X		;				[92DC]
	tay
	lda	TblErrorMsgL,X		;				[92EE]
	jsr	PrintString
	clc
	rts



; in: X=offset on zero page to values
; changes: A, X, Y
PrintHexWord:
	lda	$01,x			; hi byte first
	jsr	PrintHexByte
	lda	$00,x			; fall through with low byte
; in: A=byte to print
; changes: A, Y
PrintHexByte:
	pha
	lsr	a
	lsr	a
	lsr	a
	lsr	a
	tay
	jsr	PrintHexDigit		; hi nibble first
	pla
	and	#$0F			; fall through with low nibble
	tay
; in: Y=nibble to print
PrintHexDigit:
	lda	HexDigits,y
	jmp	KERNAL_CHROUT

HexDigits:
        .byte   "0123456789ABCDEF"

; boot file name that gets loaded and executed from its load address
BootExeName:	.byte "BOOT.PRG"
BootExeNameEnd:

.define TblErrorMsg	Msg00, Msg01, Msg02, Msg03, Msg04, Msg05, Msg06, Msg07, Msg08, Msg09, Msg0A, Msg0B, Msg0C, Msg0D, Msg0E, Msg0F, Msg10, Msg11 

TblErrorMsgL:	.lobytes TblErrorMsg
TblErrorMsgH:	.hibytes TblErrorMsg
 
Msg00:		.asciiz "OK"
Msg01:		.asciiz "DISK IS WRITE PROTECTED"
Msg02:		.asciiz "DISK IS UNUSABLE"
Msg03:		.asciiz "DISK IS NOT FORMATTED"
Msg04:		.asciiz "FILE IS CORRUPT"
Msg05:		.asciiz "FORMATING DISK"
Msg06:		.asciiz "RENAMING FILE"
Msg07:		.asciiz "SCRATCHING FILE"
Msg08:		.asciiz "ERROR DURING WRITE"
Msg09:		.asciiz "ERROR DURING READ"
Msg0A:		.asciiz "DISK MAY BE DAMAGED"
Msg0B:		.asciiz "FILE NOT FOUND"
Msg0C:		.asciiz "NO FILE EXT SPECIFIED"
Msg0D:		.asciiz "FILE TO LARGE" ; XXX typo!
Msg0E:		.asciiz "NO MORE DIRECTORY SPACE"
Msg0F:		.asciiz "DISK FOUND TO BE UNRELIABLE"
Msg10:		.asciiz "NAME TO LONG" ; XXX typo!
Msg11:		.asciiz "NO NAME SPECIFIED"
 
BIOSParameterBlock:			;  (see FormatDisk)
	.byte $EB, $28, $90			; x86 jump? but there is no x86 code there
	.byte "C64 PNCI"			; OEM name
	.word DD_SECTOR_SIZE			; bytes per sector
	.byte $02				; sectors per cluster
	.word $0001				; reserved sectors
	.byte $02				; number of FATs
	.word DD_ROOT_ENTRIES			; number of entries in root directory
	.word DD_TOTAL_SECTORS			; total sectors
	.byte DD_MEDIA_TYPE
	.word DD_FAT_SIZE			; sectors per FAT
	.word DD_SECTORS_PER_TRACK		; sectors per track
	.word DD_HEADS				; number of heads
	.word 0					; hidden sectors
	.word 0					; reserved

BIOSFileSystemType:
	.byte "FAT12   "			; 8 bytes

;**  Program that is meant to run in the Stack
StackProgram:				;				[9462]
.segment "romstack"

;**  Read a number of pages (= 256 bytes) form the floppy
; in:	256-Y bytes are read 
; Note: only used at one place and for just two pages
ReadPagesFlop:				;				[0102]
	tsx
	stx	TempStackPtr		;				[0350]
ReadPagesFlopLoop:
	ldx	#$30			; 64K RAM config		[30]
ReadPagesFlopNextByte:
:	bbrf	7, StatusRegister, :-	; wait as long as 7th bit is 0; FDC ready?
	lda	DataRegister		; read byte			[DE81]
	stx	CPU_PORT			; 64K RAM config
	sta	(Pointer),Y		; save byte			[FB]
	LoadB	CPU_PORT, $37		; I/O+ROM config (XXX should rather restore config from entry point)
	iny

; "#0" in the next line can be changed by the program
L_0119:					;				[0119]
	cpy	#0			; finished with reading?
	bne	ReadPagesFlopNextByte	; no, -> next byte		[0108]

	inc	Pointer+1		;				[FC]
	dec	PageCounter		; more pages to be read?	[02]
	bpl	ReadPagesFlopLoop	; yes, ->			[0106]

	cpy	#0			; whole sector read?
	beq	@end			; yes, -> exit			[0138]
	inc	PageCounter		;				[02]

; Read and ignore the rest of the sector, FDC expects this
:	bbrf	7, StatusRegister, :-	; wait as long as 7th bit is 0; FDC ready?
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
:	bbrf	7, StatusRegister, :-	; wait as long as 7th bit is 0; FDC ready?
	lda	DataRegister		; read byte			[DE81]
	stx	CPU_PORT			; 64K RAM config
	sta	(Pointer),Y		; store byte			[FB]
	LoadB	CPU_PORT, $37		; I/O+ROM config (XXX should rather restore config from entry point)
	iny				; finished reading?
	bne	:-			; no, -> next byte		[013F]
; Next page in RAM
	inc	Pointer+1		;				[FC]

; Read next number of bytes. See L_0165.
RdBytesSectorByte:
:	bbrf	7, StatusRegister, :-	; wait as long as 7th bit is 0; FDC ready?
	lda	DataRegister		; read byte			[DE81]
	stx	CPU_PORT			; 64K RAM config		[01]
	sta	(Pointer),Y		; store byte			[FB]
	LoadB	CPU_PORT, $37		; I/O+ROM config (XXX should rather restore config from entry point)
	iny

; "#0" in the next line can be changed by the program
L_0165:					;				[0165]
	cpy	#0			; finished with reading?
	bne	RdBytesSectorByte	; no, -> next byte		[0154]
	tya				; whole sector read?
	beq	@end			; yes, -> exit			[0178]

; Read and ignore the rest of the sector, FDC expects this
:	bbrf	7, StatusRegister, :-	; wait as long as 7th bit is 0; FDC ready?
	lda	DataRegister		; dummy read			[DE81]
	iny				; finished reading?
	bne	:-			; no, -> next byte		[016D]
@end:	rts


;**  Write 512 bytes of data to the disk
WriteData:				;				[0179]
	tsx				; save the SP in case there is an error
	stx	TempStackPtr		;				[0350]

:	ldx	#$30			; 64 KB of RAM visible
	stx	CPU_PORT			;				[01]
	lda	(Pointer),Y		; read byte from RAM under I/O	[FB]
	ldx	#$37
	stx	CPU_PORT		; I/O+ROM
:	bbrf	7, StatusRegister, :-	; wait as long as 7th bit is 0; FDC ready?
	sta	DataRegister		;				[DE81]
	iny
	bne	:--

	inc	Pointer+1		;				[FC]
	dec	PageCounter		; two pages done?		[02]
	bpl	:--			; no, -> next 256 bytes		[017D]
	rts

; Read one byte from anywhere in RAM (incl. under I/O)
; Note: interrupts must be disabled
; in:	Y = pointer offset
;	Pointer = address base
; out:	A = data
;	no change in X, Y

RdDataRamDxxx:				;				[01A0]
	lda	#$30			; 64 KB of RAM visible
	stx	TempStore		; save X			[FA]
	ldx	CPU_PORT		; save original value		[01]
	sta	CPU_PORT		;				[01]
	lda	(Pointer),Y		; read data from RAM		[FB]
	stx	CPU_PORT		; restore original value	[01]
	ldx	TempStore		; restore X			[FA]
	rts

; Write one byte anywhere to RAM (incl. under I/O)
; Note: interrupts must be disabled
; in:	A = data
;	Y = pointer offset
;	Pointer = address base
; out:	no change in A, X, Y

WrDataRamDxxx:				;				[01AF]
	pha
	stx	TempStore		; save X
	ldx	CPU_PORT		; save original value		[01]
	LoadB	CPU_PORT, $30		; 64K of RAM
	pla
	sta	(Pointer),Y		;				[FB]
	stx	CPU_PORT		; restore original value	[01]
	ldx	TempStore		; restore X			[FA]
	rts
 
