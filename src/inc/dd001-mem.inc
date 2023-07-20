
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

; BASIC FAC#2
FdcLENGTH	= $69	; (4) file length in bytes, lowest byte first (to FS_OFFS_SIZE)
FdcBYTESLEFT	= $6D	; (2) number of bytes to transfer via stack-routine?

; Used a lot in ROM, KERNAL uses them for tape routines
FdcCLUSTER	= $9B	; (2)
ErrorCode	= $9E	; (1) ERROR; error code, 0=ok, any other from Msg table

FdcNBUF		= $BD	; (1) number of buffers

; The used RS232 variables:
NumOfSectors	= $AB	; (1) TTLSEC - number of sectors to read or write
Sector		= $A9	; (word)
SectorL		= $A9	; --- number of the sector that is wanted
SectorH		= $AA	; -/
TempStore	= $A8	; (1) temp storage, particularly in Rd/WrDataRamDxxx

Pointer		= $A3	; (2) TO, general source/target memory pointer
Z_FD		= $A5	; (2) memory pointer used in save routine
Z_FF		= $A7	; (1) directory sector counter used in directory load/display

COLOR           = $0286                        ; foreground text color

NmiVector	= $0318	; pointer to NMI-interrupt ($FE47)
ICKOUT		= $0320	; pointer to KERNAL CHKOUT routine
ILOAD		= $0330	; pointer to KERNAL LOAD routine
ISAVE		= $0332	; pointer to KERNAL SAVE routine

BasicNMI	= $A002
VICCTR1		= $D011	; controlregister 1
VICLINE		= $D012	; line to generate IRQ
VICBOCL         = $D020 ; border color

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

; BASIC ROM functions (C64)
PrintString	= $AB1E		; print null-terminated string from Y/A (Y=hi)
PrintIntegerXA	= $BDCD		; print integer from X/A (X=low)

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
KERNAL_SETMSG	= $FF90
KERNAL_SECOND	= $FF93		; secondary address after LISTEN
KERNAL_TKSA	= $FF96		; secondary address after TALK
KERNAL_ACPTR	= $FFA5		; get data from the serial bus
KERNAL_CIOUT	= $FFA8		; send data through the serial bus
KERNAL_UNTALK	= $FFAB		; send UNTALK, talker stops talking
KERNAL_UNLISTEN = $FFAE		; send UNLISTEN, listeners stop listening
KERNAL_LISTEN	= $FFB1		; send LISTEN
KERNAL_TALK	= $FFB4		; send TALK
KERNAL_SETLFS	= $FFBA
KERNAL_SETNAM	= $FFBD
KERNAL_CHROUT	= $FFD2
KERNAL_LOAD	= $FFD5
KERNAL_STOP	= $FFE1
KERNAL_GETIN	= $FFE4


NmiVectorRAM	= $FFFA
