
; DD-001 jump table
; direct jumptable to locations in v1.1 ROM

RdDataRamDxxx   := $01A0                        ; direct call to RdDataRamDxxx instead of jump table $8081; read data from 64K RAM (under I/O), after InitStackProg
WrDataRamDxxx   := $01AF                        ; (would that be spare call at jump table $8084?); read data from 64K RAM (under I/O), after InitStackProg

SaveReloc       := $8472                        ; direct call to SaveReloc instead of jump table _SaveReloc $8063
FindFAT         := $85A8                        ; direct call to FindFAT instead of jump table _FindFAT $8045
ClearFATs       := $8650                        ; direct call to ClearFATs instead of jump table _ClearFATs $804E
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
ShowSize        := $9127                        ; direct call to ShowSize instead of jump table _ShowSize $8066
ShowBytesFree   := $916A                        ; direct call to ShowBytesFree instead of jump table _ShowBytesFree $806C
BN2DEC          := $920E                        ; direct call to BN2DEC instead of jump table _BN2DEC $806F
ShowError       := $926C                        ; direct call to ShowError instead of jump table _ShowError $8069
