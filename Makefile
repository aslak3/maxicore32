IVERILOG = iverilog -g 2012 -g io-range-error -Wall
VVP = vvp

YOSYS = yosys
PIN_DEF = constraints.pcf
DEVICE = up5k

NEXTPNR = nextpnr-ice40
ICEPACK = icepack
ICETIME = icetime
ICEPROG = iceprog

VERILATOR_LINT = verilator --lint-only --timing

# Configuration
BITS_PER_PIXEL = 23


all: registers

registers: registers.v registers_tb.v
	$(VERILATOR_LINT) $^
	$(IVERILOG) -o $@ $^

registers-tests: registers
	$(VVP) registers

tests: registers-tests

maxicore32.json: registers.v
	$(YOSYS) -p 'synth_ice40 -top maxicore32 -json $@' -p 'read_verilog $^'

maxicore32.asc: maxicore32.json
	$(NEXTPNR) --up5k --package sg48 --pcf $(PIN_DEF) --json maxicore32.json --asc $@

maxicore32.bin: maxicore32.asc
	$(ICEPACK) $^ $@

clean:
	rm -vf registers *.vcd *.json *.asc *.bin
