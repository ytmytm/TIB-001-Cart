
AS = ca65
LD = ld65
ASFLAGS = -t none -I inc -I .
LDFLAGS = 

SOURCES = TIB001.s

OBJS = $(SOURCES:.s=.o)

BUILD_DIR = build

FIRMWARE_ROM = $(BUILD_DIR)/tib001.bin
REFERENCE_ROM = ../firmware/rom-8000-9FFFp.bin

$(FIRMWARE_ROM): $(OBJS) rom.cfg
	-mkdir -p $(BUILD_DIR)
	$(LD) $(LDFLAGS) -C rom.cfg $(OBJS) -o $@

rom: $(FIRMWARE_ROM)

all: rom

clean:
	rm -rf $(BUILD_DIR) $(OBJS)

regress: rom
	diff $(FIRMWARE_ROM) $(REFERENCE_ROM)

# a must!
love:
	@echo "Not war, eh?"

