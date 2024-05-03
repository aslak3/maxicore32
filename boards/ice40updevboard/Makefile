include ../../Makefile
include ../../vga/Makefile
include ../../ps2/Makefile
include ../../tonegen/Makefile

YOSYS = yosys
PIN_DEF = constraints.pcf
DEVICE = up5k

NEXTPNR = nextpnr-ice40
ICEPACK = icepack
ICETIME = icetime
ICEPROG = iceprog

all: maxicore32.bin

REL_V_SRC=$(addprefix ../../, $(CORE_V_SRC)) $(addprefix ../../vga/, $(VGA_V_SRC)) \
	$(addprefix ../../ps2/, $(PS2_V_SRC)) $(addprefix ../../tonegen/, $(TONEGEN_V_SRC))

maxicore32.json: $(REL_V_SRC) ice40updevboard.v ../../maxicore32-ram-contents.txt
	$(VERILATOR_LINT) --top ice40updevboard -I../.. $(filter %.v,$^)
	$(YOSYS) -p 'read_verilog -sv $(filter %.v,$^); synth_ice40 -dsp -top ice40updevboard -json $@'

maxicore32.asc: maxicore32.json
	$(NEXTPNR) --freq 8 --up5k --package sg48 --pcf $(PIN_DEF) --json maxicore32.json --asc $@

maxicore32.bin: maxicore32.asc
	$(ICEPACK) $^ $@
