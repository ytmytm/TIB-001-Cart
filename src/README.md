
# TODO

- change device number to 7 (via define)
- disassemble these essential utilities:
	- format
	- dispasc (display text files)
	- diskcopy (3.5 to 3.5 backup)
	- v-max (I don't even know what it does)
- keep load address in first 2 bytes of the file, where it belongs
- fail fast if there is no FDD or no disk in FDD
- own BASIC startup message
- display directory using tokenized BASIC to avoid own number/text routines
	- add '<' for read-only files
	- add 'DIR' for directories
	- display volume label as disk header
	- show 'BLOCKS FREE' assuming 256-byte blocks (we can't allocate it like that, but it makes CBM drives comparable, it's equally meaningless to 'BYTES FREE' message)

# Source code

- add constants for BIOS Parameter Block and file entries
- change fixed length of $0101 code to actual segment length
- replace some bit testing jumps by GEOS macros

# Optimizations

- filename code is repeating (8 characters, dot, 3 characters and space padding)
- screen on is repeating a lot
- loading vector to StartofDir repeats a lot
- consistently use BIT/BPL for controller status, there are all variants
- remove unused code (but check how utilities use ROM first)
- replace screen text by ASCIIZ and $FFD2 printing (or BASIC $AB1E)
- display SEARCHING (F5AF) or LOADING/VERYFING (F5D2)
- actually implement VERIFY

# New utilities

- take DraBrowser/DraCopy, make it a new BOOT.EXE and add support for DD-001
	- directory browser
	- file loader
	- rename
	- scratch
	- disk format (with some visual $d020 indicator)
	- disk backup
		- 3.5 to 3.5 with progress information and **CLEAR** information about source/target disk
                  and number of remaining switches
		- 3.5 to IMG file on 1581 or SD2IEC and back

