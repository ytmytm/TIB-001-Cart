
# configuration

# DD-001 device number
DEVNUM ?= 9

# buld part

AS = ca65
LD = ld65
ASFLAGS = -t none -I inc -I . -DDEVNUM=$(DEVNUM)
LDFLAGS = 

BUILD_DIR = build

SOURCES = TIB001.s

OBJS = $(SOURCES:.s=.o)
PREFIXED_OBJS = $(addprefix $(BUILD_DIR)/, $(OBJS))

FIRMWARE_ROM = $(BUILD_DIR)/tib001.bin
REFERENCE_ROM = ../firmware/rom-8000-9FFFp.bin

$(FIRMWARE_ROM): $(PREFIXED_OBJS) rom.cfg
	-mkdir -p $(BUILD_DIR)
	$(LD) $(LDFLAGS) -C rom.cfg $(PREFIXED_OBJS) -o $@

$(BUILD_DIR)/%.o: %.s
	@mkdir -p `dirname $@`
	$(AS) $(ASFLAGS) $< -o $@

rom: $(FIRMWARE_ROM)

all: rom

clean:
	rm -rf $(BUILD_DIR)

regress: rom
	diff $(FIRMWARE_ROM) $(REFERENCE_ROM)

# a must!
love:
	@echo "Not war, eh?"

