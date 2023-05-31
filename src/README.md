
# TODO

- look at manual and MULT.ASC and update labels - TapeBuffer+?? seems to overlap with named labels; data load from MULT.ASC looks easy to follow
- keep load address in first 2 bytes of the file, where it belongs
- correct and reassemble utilities, this time with jump table
- fail fast if there is no FDD or no disk in FDD
- own BASIC startup message
- display directory using tokenized BASIC to avoid own number/text routines
	- add '<' for read-only files
	- add 'DIR' for directories
	- display volume label as disk header
	- show 'BLOCKS FREE' assuming 256-byte blocks (we can't allocate it like that, but it makes CBM drives comparable, it's equally meaningless to 'BYTES FREE' message)

# Source code

- split ROM into multiple files with clear exports/imports (like reassembled GEOS) and several segments
- use constants for BIOS Parameter Block and file entries
- replace some bit testing jumps by GEOS macros
- disassembled utilities use direct jumps to ROM, without using JUMPTABLE

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

# Build system

You need latest cc65 package with ca65/ld65 and GNU Make.

Run `make` to build 8K ROM file in `build/tib001.bin`.

Run `make clean && make regress` to check of the resulting binary matches reference V1.1 ROM.

You can set parameters within `Makefile` or pass them from the command line. For example:
```
make DEVNUM=7
```
to assemble ROM with DD-001 mapped to device #7.
