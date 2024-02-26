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

ALL_TESTBENCHES = registers-register_file_tb registers-program_counter_tb alu_tb businterface_tb

all: $(ALL_TESTBENCHES)

registers-register_file_tb: registers.v tb/registers_tb.v
	$(VERILATOR_LINT) --top-module register_file_tb $^
	$(IVERILOG) -s register_file_tb -o $@ $^
registers-program_counter_tb: registers.v tb/registers_tb.v
	$(VERILATOR_LINT) --top-module program_counter_tb $^
	$(IVERILOG) -s program_counter_tb -o $@ $^
alu_tb: alu.v tb/alu_tb.v
	$(VERILATOR_LINT) --top alu_tb $^
	$(IVERILOG) -s alu_tb -o $@ $^
businterface_tb: businterface.v tb/businterface_tb.v
	$(VERILATOR_LINT) --top businterface_tb $^
	$(IVERILOG) -s businterface_tb -o $@ $^

tests: $(ALL_TESTBENCHES)
	for T in $^; do $(VVP) $$T; done

maxicore32.json: registers.v
	$(YOSYS) -p 'synth_ice40 -top maxicore32 -json $@' -p 'read_verilog $^'

maxicore32.asc: maxicore32.json
	$(NEXTPNR) --up5k --package sg48 --pcf $(PIN_DEF) --json maxicore32.json --asc $@

maxicore32.bin: maxicore32.asc
	$(ICEPACK) $^ $@

clean:
	rm -vf $(ALL_TESTBENCHES) businterface_tb *.vcd *.json *.asc *.bin
