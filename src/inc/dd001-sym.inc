
; DD-001 constants

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
