
# configuration

# DD-001 device number
DEVNUM ?= 9

# build part

AS = ca65
LD = ld65
ASFLAGS = -t none -I inc -I . -DDEVNUM=$(DEVNUM)
LDFLAGS = 

BUILD_DIR = build

SOURCES = TIB001.s

INC = inc/dd001-mem.inc inc/dd001-sym.inc inc/fat12.inc inc/geosmac.inc

OBJS = $(SOURCES:.s=.o)
PREFIXED_OBJS = $(addprefix $(BUILD_DIR)/, $(OBJS))

FIRMWARE_ROM = $(BUILD_DIR)/tib001.bin
REFERENCE_ROM = ../firmware/rom-8000-9FFFp.bin

$(FIRMWARE_ROM): $(PREFIXED_OBJS) $(INC) rom.cfg
	-mkdir -p $(BUILD_DIR)
	$(LD) $(LDFLAGS) -C rom.cfg $(PREFIXED_OBJS) -o $@

$(BUILD_DIR)/%.o: %.s
	@mkdir -p `dirname $@`
	$(AS) $(ASFLAGS) $< -o $@

# reference utilities
$(BUILD_DIR)/diskmon.o: utils/diskmon.s
	$(AS) $(ASFLAGS) $< -o $@

$(BUILD_DIR)/diskmon.exe: $(BUILD_DIR)/diskmon.o utils/cfg1000.cfg
	$(LD) $(LDFLAGS) -C utils/cfg1000.cfg $(BUILD_DIR)/diskmon.o -o $@

$(BUILD_DIR)/diskcopy.o: utils/diskcopy.s
	$(AS) $(ASFLAGS) $< -o $@

$(BUILD_DIR)/diskcopy.exe: $(BUILD_DIR)/diskcopy.o utils/cfg0800.cfg
	$(LD) $(LDFLAGS) -C utils/cfg0800.cfg $(BUILD_DIR)/diskcopy.o -o $@

$(BUILD_DIR)/dispasc.o: utils/dispasc.s
	$(AS) $(ASFLAGS) $< -o $@

$(BUILD_DIR)/dispasc.exe: $(BUILD_DIR)/dispasc.o utils/cfg1000.cfg
	$(LD) $(LDFLAGS) -C utils/cfg1000.cfg $(BUILD_DIR)/dispasc.o -o $@

$(BUILD_DIR)/disphex.o: utils/disphex.s
	$(AS) $(ASFLAGS) $< -o $@

$(BUILD_DIR)/disphex.exe: $(BUILD_DIR)/disphex.o utils/cfg1000.cfg
	$(LD) $(LDFLAGS) -C utils/cfg1000.cfg $(BUILD_DIR)/disphex.o -o $@

$(BUILD_DIR)/format.o: utils/format.s
	$(AS) $(ASFLAGS) $< -o $@

$(BUILD_DIR)/format.exe: $(BUILD_DIR)/format.o utils/cfg0800.cfg
	$(LD) $(LDFLAGS) -C utils/cfg0800.cfg $(BUILD_DIR)/format.o -o $@


utils: $(BUILD_DIR)/format.exe $(BUILD_DIR)/dispasc.exe $(BUILD_DIR)/disphex.exe $(BUILD_DIR)/diskmon.exe $(BUILD_DIR)/diskcopy.exe

rom: $(FIRMWARE_ROM)

all: rom utils

clean:
	rm -rf $(BUILD_DIR)

regress: rom utils
	diff $(FIRMWARE_ROM) $(REFERENCE_ROM)
	diff $(BUILD_DIR)/format.exe ../firmware/utils/FORMAT.EXE
	diff $(BUILD_DIR)/dispasc.exe ../firmware/utils/DISKASC.EXE
	diff $(BUILD_DIR)/disphex.exe ../firmware/utils/DISKHEX.EXE
	diff $(BUILD_DIR)/diskmon.exe ../firmware/utils/DISKMON.EXE
	diff $(BUILD_DIR)/diskcopy.exe ../firmware/utils/DISKCOPY.EXE

# a must!
love:
	@echo "Not war, eh?"

