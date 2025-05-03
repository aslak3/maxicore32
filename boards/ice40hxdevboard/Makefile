include ../../Makefile
include ../../glue/Makefile
include ../../video/Makefile
include ../../ps2/Makefile
include ../../i2c/Makefile
include ../../tonegen/Makefile
include ../../uart/Makefile

include ../../levels_rom/Makefile

YOSYS = yosys
PIN_DEF = constraints.pcf
DEVICE = hx4k

NEXTPNR = nextpnr-ice40
ICEPACK = icepack
ICETIME = icetime
ICEPROG = iceprog

all: ../../levels_rom/levels.txt maxicore32.bin

REL_V_SRC=$(addprefix ../../, $(CORE_V_SRC)) $(addprefix ../../glue/, $(GLUE_V_SRC)) \
	$(addprefix ../../video/, $(VIDEO_V_SRC)) $(addprefix ../../ps2/, $(PS2_V_SRC)) \
	$(addprefix ../../i2c/, $(I2C_V_SRC)) $(addprefix ../../tonegen/, $(TONEGEN_V_SRC)) \
	$(addprefix ../../uart/, $(UART_V_SRC)) \
	$(addprefix ../../levels_rom/, $(LEVELS_ROM_V_SRC))

maxicore32.json: $(REL_V_SRC) ice40hxdevboard.v constraints.pcf ../../maxicore32-ram-contents.txt
	$(VERILATOR_LINT) -DVERILATOR=1 --top ice40hxdevboard -I../.. $(filter %.v,$^)
	$(YOSYS) -p 'read_verilog -sv $(filter %.v,$^); synth_ice40 -top ice40hxdevboard -json $@'

maxicore32.asc: maxicore32.json
	$(NEXTPNR) --freq 8 --$(DEVICE) --package tq144 --pcf $(PIN_DEF) --json maxicore32.json --asc $@

maxicore32.bin: maxicore32.asc
	$(ICEPACK) $^ $@
