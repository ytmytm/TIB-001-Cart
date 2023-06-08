
# Supported hardware and disk format

You can use standard PC floppy drive and HD floppies.

In my experience it is necessary to cover the HD hole (opposite to write protect) and then format HD disks - either using PC or from within BASIC:

```
OPEN 15,7,15:PRINT#15,"N:NEWDISK":CLOSE15
```

On a PC it is *very* important to choose correct allocation size. You need 1K (1024 bytes, 2 sectors) allocation size/cluster size, not 512 bytes.

On Linux this can be done with:
```
mkfs.vfat -F 12 -r 112 -f 2 -s 2 /dev/fd # or disk.img
```

This is:

- FAT12
- 112 root directory entries
- 2 FATs
- 2 sectors per cluster


# TODO

- correct and reassemble utilities, this time with jump table
- fail fast if there is no FDD or no disk in FDD
- display directory using tokenized BASIC to avoid own number/text routines
	- add '<' for read-only files
	- add 'DIR' for directories
	- show 'BLOCKS FREE' assuming 256-byte blocks (we can't allocate it like that, but it makes CBM drives comparable, it's equally meaningless to 'BYTES FREE' message)

# Source code

- use constants for BIOS Parameter Block and file entries
- disassembled utilities use direct jumps to ROM, without using JUMPTABLE

# Optimizations

- filename processing code is repeating (8 characters, dot, 3 characters and space padding)
- screen on is repeating a lot
- loading vector to StartofDir repeats a lot
- move temporary values to zero-page occupied by tape
- actually implement VERIFY (needed?)

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

Run `make utils` to build some basic utilities.

You can set parameters within `Makefile` or pass them from the command line. For example:
```
make DEVNUM=7
```
to assemble ROM with DD-001 mapped to device #7.

## Only on `dd001-rom-v1.1` branch

Run `make clean && make regress` to check of the resulting binary matches reference V1.1 ROM and utilities.

