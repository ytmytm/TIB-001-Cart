
# configuration

# DD-001 device number
DEVNUM ?= 7

# build part

BUILD_DIR = build

AS = ca65
LD = ld65
ASFLAGS = -t none -I inc -I . -DDEVNUM=$(DEVNUM)
LDFLAGS = -m $(BUILD_DIR)/mapfile.map

SOURCES = TIB001.s

INC = inc/dd001-mem.inc inc/dd001-sym.inc inc/fat12.inc inc/geosmac.inc

OBJS = $(SOURCES:.s=.o)
PREFIXED_OBJS = $(addprefix $(BUILD_DIR)/, $(OBJS))

FIRMWARE_ROM = $(BUILD_DIR)/tib001.bin
REFERENCE_ROM = ../firmware/rom-8000-9FFFp.bin

$(FIRMWARE_ROM): $(PREFIXED_OBJS) $(INC) rom.cfg
	-mkdir -p $(BUILD_DIR)
	$(LD) $(LDFLAGS) -C rom.cfg $(PREFIXED_OBJS) -o $@
	cat $(FIRMWARE_ROM) $(REFERENCE_ROM) > $(BUILD_DIR)/tib001-16k.bin

$(BUILD_DIR)/%.o: %.s
	@mkdir -p `dirname $@`
	$(AS) $(ASFLAGS) $< -o $@

# reference utilities
$(BUILD_DIR)/diskmon.o: utils/diskmon.s
	$(AS) $(ASFLAGS) $< -o $@

$(BUILD_DIR)/diskmon.prg: $(BUILD_DIR)/diskmon.o utils/cfgbasic.cfg
	$(LD) $(LDFLAGS) -C utils/cfgbasic.cfg $(BUILD_DIR)/diskmon.o -o $@

$(BUILD_DIR)/diskcopy.o: utils/diskcopy.s
	$(AS) $(ASFLAGS) $< -o $@

$(BUILD_DIR)/diskcopy.prg: $(BUILD_DIR)/diskcopy.o utils/cfgbasic.cfg
	$(LD) $(LDFLAGS) -C utils/cfgbasic.cfg $(BUILD_DIR)/diskcopy.o -o $@

$(BUILD_DIR)/dispasc.o: utils/dispasc.s
	$(AS) $(ASFLAGS) $< -o $@

$(BUILD_DIR)/dispasc.prg: $(BUILD_DIR)/dispasc.o utils/cfgbasic.cfg
	$(LD) $(LDFLAGS) -C utils/cfgbasic.cfg $(BUILD_DIR)/dispasc.o -o $@

$(BUILD_DIR)/disphex.o: utils/disphex.s
	$(AS) $(ASFLAGS) $< -o $@

$(BUILD_DIR)/disphex.prg: $(BUILD_DIR)/disphex.o utils/cfgbasic.cfg
	$(LD) $(LDFLAGS) -C utils/cfgbasic.cfg $(BUILD_DIR)/disphex.o -o $@

$(BUILD_DIR)/format.o: utils/format.s
	$(AS) $(ASFLAGS) $< -o $@

$(BUILD_DIR)/format.prg: $(BUILD_DIR)/format.o utils/cfgbasic.cfg
	$(LD) $(LDFLAGS) -C utils/cfgbasic.cfg $(BUILD_DIR)/format.o -o $@


utils: $(BUILD_DIR)/format.prg $(BUILD_DIR)/dispasc.prg $(BUILD_DIR)/disphex.prg $(BUILD_DIR)/diskmon.prg $(BUILD_DIR)/diskcopy.prg

rom: $(FIRMWARE_ROM)

all: rom utils

clean:
	rm -rf $(BUILD_DIR)

# a must!
love:
	@echo "Not war, eh?"

