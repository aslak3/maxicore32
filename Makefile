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

all: registers-register_file registers-program_counter

registers-register_file: registers.v registers_tb.v
	$(VERILATOR_LINT) --top-module register_file_tb $^
	$(IVERILOG) -s register_file_tb -o $@ $^
registers-program_counter: registers.v registers_tb.v
	$(VERILATOR_LINT) --top-module program_counter_tb $^
	$(IVERILOG) -s program_counter_tb -o $@ $^

registers-tests: registers-register_file registers-program_counter
	$(VVP) registers-register_file
	$(VVP) registers-program_counter

tests: registers-tests

maxicore32.json: registers.v
	$(YOSYS) -p 'synth_ice40 -top maxicore32 -json $@' -p 'read_verilog $^'

maxicore32.asc: maxicore32.json
	$(NEXTPNR) --up5k --package sg48 --pcf $(PIN_DEF) --json maxicore32.json --asc $@

maxicore32.bin: maxicore32.asc
	$(ICEPACK) $^ $@

clean:
	rm -vf registers-register_file registers-program_counter *.vcd *.json *.asc *.bin
