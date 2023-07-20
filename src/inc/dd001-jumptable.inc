
; DD-001 jump table

DD001_JUMP	=	$8010

NewLoad		=	DD001_JUMP+0*3
NewSave		=	DD001_JUMP+1*3
FormatDisk	=	DD001_JUMP+2*3
DisplayDir	=	DD001_JUMP+3*3
ReadSector	=	DD001_JUMP+4*3
SetWatchdog	=	DD001_JUMP+5*3
ReadSectors	=	DD001_JUMP+6*3
WriteSector	=	DD001_JUMP+7*3
ReadStatus	=	DD001_JUMP+8*3
Scratch		=	DD001_JUMP+9*3
Rename		=	DD001_JUMP+10*3
FormatTrack	=	DD001_JUMP+11*3
InitStackProg	=	DD001_JUMP+12*3
SetupSector	=	DD001_JUMP+13*3
Specify		=	DD001_JUMP+14*3
Recalibrate	=	DD001_JUMP+15*3
SetSpace	=	DD001_JUMP+16*3
GetNextCluster	=	DD001_JUMP+17*3
Enfile		=	DD001_JUMP+18*3
MarkFAT		=	DD001_JUMP+19*3
FindFAT		=	DD001_JUMP+20*3
FindNextFAT	=	DD001_JUMP+21*3
WriteFATs	=	DD001_JUMP+22*3
ClearFATs	=	DD001_JUMP+23*3
CalcFirst	=	DD001_JUMP+24*3
GetFATs		=	DD001_JUMP+25*3
SeekTrack	=	DD001_JUMP+26*3
FindFile	=	DD001_JUMP+27*3
WriteDirectory	=	DD001_JUMP+28*3
ReadDirectory	=	DD001_JUMP+29*3
SaveReloc	=	DD001_JUMP+30*3
ShowError	=	DD001_JUMP+31*3
StripSP		=	DD001_JUMP+32*3
FindBlank	=	DD001_JUMP+33*3
PadOut		=	DD001_JUMP+34*3
StopWatchdog	=	DD001_JUMP+35*3
RdDataRamDxxx	=	DD001_JUMP+36*3
WrDataRamDxxx	=	DD001_JUMP+37*3
OpenDir		=	DD001_JUMP+38*3
GetNextDirEntry	=	DD001_JUMP+39*3
CloseDir	=	DD001_JUMP+40*3

