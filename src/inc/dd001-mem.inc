
; DD-001 memory locations

CPU_PORT	= $01	; onboard I/O port of 6510
PageCounter	= $02
PtrBasText	= $7A	; pointer to momentary byte in BASIC line
STATUSIO	= $90	; Status of KERNAL after action
FlgLoadVerify	= $93	; 0 = LOAD, 1 = VERIFY
MSGFLG		= $9D	; flag: $80 = direct mode, 0 = program mode
ENDADDR		= $AE	; vector, word - end of cassette / end of program
FNLEN		= $B7	; length of filename
SECADR		= $B9	; actual secondary address
CURDEVICE	= $BA	; actual device number
FNADR		= $BB	; pointer to string with filename

; these used in LOAD/SAVE, with ENDADDR
STARTADDR	= $C1	; vector, start address for saving programss
LOADADDR	= $C3	; vector, load address for program (Kernal), keep it unchanged

; The used RS232 variables:
STARTUP		= $F0	; defined in MULT.ASC but not used actually
NumOfSectors	= $F7	; (1) TTLSEC - number of sectors to read or write
Sector		= $F8	; (word)
SectorL		= $F8	; --- number of the sector that is wanted
SectorH		= $F9	; -/
TempStore	= $FA

Pointer		= $FB	; (2) TO, general source/target memory pointer
Z_FD		= $FD
J_00FE		= $FE	; vector, unused
Z_FF		= $FF
StackPage	= $0100

COLOR           = $0286                        ; foreground text color

NmiVector	= $0318	; pointer to NMI-interrupt ($FE47)
ICKOUT		= $0320	; pointer to KERNAL CHKOUT routine
ILOAD		= $0330	; pointer to KERNAL LOAD routine
ISAVE		= $0332	; pointer to KERNAL SAVE routine

; $0334-$033B = original free area = 8 bytes
StartofDir	= $0334
EndofDir	= $0335
NewICKOUT	= $0336
NewNMI		= $0338


;TapeBuffer	= $033C	; cassette buffer
FdcST0		= $033C ; +0 (1)	Status Register 0
FdcST1		= $033D ; +1 (1)	Status Register 1
FdcST2		= $033E ; +2 (1)	Status Register 2
FdcC		= $033F ; +3 (1)	Cylinder
FdcH		= $0340 ; +4 (1)	Head
FdcR		= $0341 ; +5 (1)	Record = sector
FdcN		= $0342 ; +6 (1)	Number of data bytes written into a sector
FdcST3		= $0343 ; +7 (1)	Status Register 3
FdcPCN		= $0344	; +8 (1)	present cylinder = track
FdcCommand	= $0345 ; +9 (1)
FdcHSEL		= $0346	; +10 (1) head, shifted twice, needed for FDC commands
FdcTrack	= $0347	; +11 (1)
FdcHead		= $0348	; +12 (1)
FdcSector	= $0349	; +13 (1)
FdcNumber	= $034A	; +14 (1) bytes/sector during format, 2 = 512 b/s
FdcEOT		= $034B	; +15 (1) end of track
FdcGPL		= $034C	; +16 (1) unused; gap length? (but not for format), in docs initalized to $1b
FdcDTL		= $034D	; +17 (1) unused
FdcTrack2	= $034E	; +18 (1) CYLIND; = FdcTrack and $FE  ???
FdcTEMP		= $034F	; +19 (1) unused
TempStackPtr	= $0350	; +20 (1) TSTACK; temporary storage for the stack pointer
ErrorCode	= $0351	; +21 (1) ERROR; error code, 0=ok, any other from Msg table
FdcFormatData	= $0352	; +22 (4) FRED; block of data used only by the format command (4 bytes but overwrites the 5th - following SCLUSTER)
FdcSCLUSTER	= $0356	; +26 (2)
FdcLCLUSTER	= $0358	; +28 (2)
FdcCLUSTER	= $035A	; +30 (2) (lots of occurences, move to zp?)
FdcCLUSTER_2	= $035C	; +32 (2) (3 occurences)
FdcLENGTH	= $035E	; +34 (4) file length in bytes, lowest byte first (to FS_OFFS_SIZE)
FdcBYTESLEFT	= $0362	; +38 (2) number of bytes to transfer via stack-routine?
FdcNBUF		= $0364	; +40 (1) number of buffers
FdcPASS		= $0365	; +41 (1) SaveReloc stores 1 here, not used otherwise (1 occurence)
Counter		= $0366	; +42 (1) TRYS
FdcOFFSET	= $0367	; +43 (1) offset to zero page where load address stayed for SAVE (3 occurences)
FdcHOWMANY	= $0368	; +44 (1) (2 occurences)
DirSector	= $0369	; +45 (1) DIRSEC; momentary directory sector
FdcLOADAD	= $036A	; +46 (2) load address in LOAD/SAVE, copied from offset $10 in directory entry (2 occurences)
FdcFileName	= $036C	; +48 (30) FILEBUF; temp storage for file name
FdcFILETEM	= $038A	; +78 (11) storage for 8.3 filename (2 occurences)
FdcFILELEN	= $0395	; +89 (1) filename length? (2 occurences)

A_03F8		= $03F8 ; firmware BUG: jumps here instead of NewICKOUT vector ($0336)
NewILOAD	= $03FC
NewISAVE	= $03FE
VICSCN		= $0400	; screenmemory


BasicCold	= $A000
BasicNMI	= $A002
VICCTR1		= $D011	; controlregister 1
VICLINE		= $D012	; line to generate IRQ
VICBOCL         = $D020                        ; border color

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

; Kernal ROM functions (C64)
InitScreenKeyb	= $E518
PrintSearchingFor = $F5AF	; display 'SEARCHING FOR <filename>'
PrintLoading	= $F5D2		; display 'LOADING' or 'VERIFYING'
PrintSaving	= $F68F		; display 'SAVING <filename>"
IncrClock22	= $F6BC
SetVectorsIO2	= $FD15
TestRAM2	= $FD50
InitSidCIAIrq2	= $FDA3
InitialiseVIC2	= $FF5B
; Kernal jump table (C64/128)
KERNAL_SETLFS	= $FFBA
KERNAL_SETNAM	= $FFBD
KERNAL_CHROUT	= $FFD2
KERNAL_STOP	= $FFE1

NmiVectorRAM	= $FFFA
