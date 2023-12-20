
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

