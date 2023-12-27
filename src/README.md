# New firmware

This is an updated firmware for TIB DD-001 cartridge. 

The main, most important change is that I removed filesystem format used by original ROM. The load address comes from first two bytes of the file data stream, just like in CBM DOS, so PRG files can be easily exchanged between C64 and PC.

The original firmware kept this information in date and time fields of FAT file entry, making it impossible to copy files without some custom software (that never existed) on PC side.

I believe this design flaw was the main reason why this product failed and became curiosity instead of something as commmon as sd2iec but several years earlier.

All modifications were done by Maciej Witkowiak, relying on work of:

- Ruud Baltissen who disassembled and commented the original ROM http://www.softwolves.com/arkiv/cbm-hackers/28/28457.html
- Steve Gray's cartridge project for hardware part (this repository is a fork of his project)

## Modifications

- load address, like in CBM DOS, comes from the first two bytes of file - just copy PRG file and it will work
- device number configurable during ROM assembly (default is now 7, because original 9 was a very poor choice)
- corrected handling of disk commands so R(ename), S(cratch), N(ew) work both via OPEN15,7,15,"...." and OPEN15,7,15:PRINT#15,"..."
- changed disk directory format to match CBM standard when you LOAD"$",7 and LIST it
- actually allow to load the directory like a BASIC program
- after reset there is a brief pause after which ROM tries to load and run BOOT.PRG, this can be interrupted with `RUN/STOP`
- several optimizations, removed unused code - also from the tools
- GEOS macros (LoadW, MoveW, PushW/PopW) to make the code easier to read
- LOAD/SAVE show start/end address, just like Action Replay loader
- DOS wedge adapted into ROM from 1541 demo disk; with @$, @, /, ^, % commands
- function keys with assigned commands
- long filenames are ignored

## Possible enhancements

- support for changing directory, parsing paths is too much, but `CD:folder` and `CD..` would make a difference already
- LOAD can load files up to $CFFF, it could do full $0400-$FFFF if chain of clusters to read would be cached somewhere in low memory
- detect and support for FAT format with 1 sector per cluster (512 byte allocation unit instead of 1024)
- support two drives
- GEOS disk driver - only raw track and sector (256 bytes) access; with boot sector, FAT and directory indicating one file that occupies whole disk space

# Supported hardware and disk format

You can use standard PC floppy drive and HD floppies, but the HD hole (opposite to write protect slider) **must** be covered.

HD floppies have to be reformatted as DD.

In BASIC:
```
OPEN 15,7,15:PRINT#15,"N:NEWDISK":CLOSE15
```
or
```
OPEN 15,7,15,"N:NEWDISK":CLOSE15
```
or using built-in DOS wedge
```
@#7
@N:NEWDISK
```

On a PC it is *very* important to choose correct allocation size. You need 1K (1024 bytes, 2 sectors) allocation size/cluster size, not 512 bytes.

In DOS you can do:
```
format a: /f:720 /a:1024 /v:volname
```
or
```
format a: /a:1024 /v:volname /t:80 /n:9
```

On Linux this can be done with:
```
mkfs.vfat -F 12 -r 112 -f 2 -s 2 /dev/fd # or disk.img
```

This means:

- FAT12
- 112 root directory entries
- 2 FATs
- 2 sectors per cluster

Note that `mkfs.vfat` only writes the filesytem information, disk has to be formatted as DD before that.

# Reset and BOOT.PRG

After power-on or RESET a welcome screen will appear briefly. If you press `RUN/STOP` you will enter BASIC immediately. Otherwise ROM will try to load and run `BOOT.PRG` program from the floppy.

You can put filebrowser on a floppy and rename it to `BOOT.PRG`. This one works very well: https://commodore.software/downloads/download/29-disk-menus/1140-cbm-filebrowser-v1-6

# Function keys

Most often used commands are available via function keys. You can customize it in [src/fkeys.s](fkeys.s)

| key | command | description |
|---- | ---- |---- |
| F1 | `@$` | display directory |
| F2 | `LIST` | clear the screen and list BASIC program |
| F3 | `RUN:` | run BASIC program |
| F4 | `^` | load and run, use it after `@$` - move cursor up and hit F4 |
| F5 | `/` | load, use it after `@$` - move cursor up and hit F5 |
| F6 | `{left arrow}` | save a file |
| F7 | `@#7` | change current device to TIB-001 |
| F8 | `@#8` | change current device to disk drive #8 |

# DOS wedge

DOS wedge comes from disassembly of DOS 5.1 wedge from 1541 DEMO DISK by Bob Fairbairn (1982-07-13)

## Commands

| command 				| description |
|--------				|--------|
|  `@`   				| display status |
|  `@#<number>` 			| change current device |
|  `@$`					| display directory |
|  `@Q` 				| disable DOS wedge |
|  `@<CBM DOS command>` 		| send command to the drive, i.e. `@N:EMPTY,00` or `@R:OLDNAME=NEWNAME` |
|  `/<filename>` 			| load a file into BASIC area |
|  `%<filename>` 			| load a file by its load address |
|  `^<filename>` 			| load and run BASIC program |
|  `{left arrow}<filename>`		| save a file |

## Directory

Directory listing will show subdirectories as file type `DIR`, all other files are `PRG`.

Hidden files are displayed with splat (`*PRG`).

Read-only files will have lock mark (`PRG<`).

After displaying directory you can quickload a file by moving cursor up next to the file you want to load and putting '/' or '^' into the first column and pressing RETURN.

# Build system

## GitHub actions

It's possible to rebuild these ROMs entirely within GitHub using their infrastructure. Use it to customize your ROM: change device number of function key definitions.
For any patches that fix bugs or add enhancements please send be back a pull request.

1. Clone this repository
2. Make any changes you wish, edit files directly within GitHub
3. Look into `Actions` tab, there will be runs of 'Makefile CI' continuous integration workflow after each of the new commits
4. Click on the name of the latest workflow run - on the bottom of the page there will be build artfiacts to download

There are two ROMs build - 8K image that contains only the new code and a 16K image with new code in the lower half and the original code in the upper half.

The tools archive contains only the tools that call functions from new code via jump table.

## Local

You need latest cc65 package with ca65/ld65 and GNU Make.

Run `make` to build 8K ROM file in `build/tib001.bin`.

Run `make utils` to build some basic utilities.

You can set parameters within `Makefile` or pass them from the command line. For example:
```
make DEVNUM=7
```
to assemble ROM with DD-001 mapped to device #7.

### Only on `dd001-rom-v1.1` branch

Run `make clean && make regress` to check of the resulting binary matches reference V1.1 ROM and utilities.

