
; FAT12 data structures

; BIOS Parameter block (boot sector)

BS_OEM_NAME		= $03		; (8)		OEM name (null terminated)
BPB_BYTES_PER_SECTOR	= $0B		; (2) = $0200	bytes per sector (low byte first)
BPB_SECTORS_PER_CLUSTER	= $0D		; (1) = $02	sectors per cluster
BPB_RESERVED_SECTORS	= $0E		; (2) = $0001	reserved sectors (low byte first)
BPB_NUM_FATS		= $10		; (1) = $02	the number of FATs
BPB_ROOT_ENTRIES	= $11		; (2) = $0070	root directory entries (low byte first)
BPB_TOTAL_SECTORS	= $13		; (2) = $05A0	total number of sectors (low byte first, 2*9*80=1440)
BPB_MEDIA_TYPE		= $15 		; (1) = $F9	media type ($F9 is 3.5", 720K)
BPB_SECTORS_PER_FAT	= $16 		; (2) = $0003	sectors per FAT (low byte first)
BPB_SECTORS_PER_TRACK 	= $18 		; (2) = $0009	sectors per track (low byte first)
BPB_NUM_HEADS		= $1A 		; (2) = $0002	number of heads (low byte first)
BPB_HIDDEN_SECTORS	= $1C		; (4) = 0	hidden sectors

; file entry
FILE_ENTRY_SIZE		= 32
FE_OFFS_NAME		= $00		; (8) filename, padded with spaces
FE_OFFS_EXT		= $08		; (3) extension, padded with spaces
FE_OFFS_ATTR		= $0B		; (1) attributes
FE_OFFS_RESERVED	= $0C		; (1) reserved
FE_OFFS_CREATED_TIME_S10 = $0D		; (1) created time 1/10 seconds
FE_OFFS_CREATED_TIME	= $0E		; (2) created time
FE_OFFS_CREATED_DATE	= $10		; (2) created date
FE_OFFS_LOAD_ADDRESS	= $10		; (2) load address (high byte first), TIB DD-001 extension
FE_OFFS_LAST_ACCESS_DATE = $12		; (2) last access date
FE_OFFS_RESERVED2	= $14		; (2) reserved
FE_OFFS_LAST_WRITE_TIME	= $16		; (2) last write time
FE_OFFS_LAST_WRITE_DATE = $18		; (2) last write date
FE_OFFS_START_CLUSTER	= $1A		; (2) first cluster with data (low byte first)
FE_OFFS_SIZE		= $1C		; (4) file size in bytes (low byte first)

; file entry attributes
FE_ATTR_READ_ONLY	= $01		; File or directory is read-only
FE_ATTR_HIDDEN		= $02 		; File or directory is hidden
FE_ATTR_SYSTEM 		= $04 		; System file or directory
FE_ATTR_VOLUME_ID	= $08 		; Directory entry is the volume label
FE_ATTR_DIRECTORY	= $10		; Entry is a subdirectory
FE_ATTR_ARCHIVE		= $20		; File needs to be archived
FE_ATTR_READ_ONLY_BIT	= 0
FE_ATTR_HIDDEN_BIT	= 1
FE_ATTR_SYSTEM_BIT	= 2
FE_ATTR_VOLUME_ID_BIT	= 3
FE_ATTR_DIRECTORY_BIT	= 4
FE_ATTR_ARCHIVE_BIT	= 5

; FAT magic values
FAT_ENTRY_FREE		= $0000		; free cluster
FAT_ENTRY_END_OF_FILE	= $0FFF		; end of file, last cluster in chain
FAT_ENTRY_BAD_CLUSTER	= $0FF7		; bad cluster
FAT_ENTRY_RESERVED	= $0FF0		; reserved value in the FAT

; constants for 720K 3.5" disk
DD_MEDIA_TYPE		= $F9		; 3.5", 720K DD
DD_SECTOR_SIZE		= 512
DD_FAT_SIZE		= 3		; 3 sectors per FAT
DD_SECTORS_PER_TRACK	= 9
DD_HEADS		= 2
DD_TRACKS		= 80		; also known as cylinders
DD_ROOT_ENTRIES		= 112
DD_TOTAL_SECTORS	= DD_HEADS * DD_TRACKS * DD_SECTORS_PER_TRACK

; Sector offsets (starting from 0 like in a disk image, on a track sectors start with 1)

DD_SECT_BOOT		= 0		; boot sector
DD_SECT_FAT1		= 1		; start of FAT1
DD_SECT_FAT2		= DD_SECT_FAT1+DD_FAT_SIZE
DD_SECT_ROOT		= DD_SECT_FAT2+DD_FAT_SIZE
DD_SECT_DATA		= DD_SECT_ROOT+(DD_ROOT_ENTRIES * FILE_ENTRY_SIZE / DD_SECTOR_SIZE)

