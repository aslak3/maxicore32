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

ALL_TESTBENCHES = registers-register_file_tb registers-program_counter_tb alu_tb businterface_tb \
	maxicore32_tb tonegen_tb i2c_controller_tb

CORE_V_SRC = maxicore32.v businterface.v registers.v alu.v agu.v \
	memorystage1.v registersstage2.v \
	memory.v led.v

all-testbenches: $(ALL_TESTBENCHES)

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
memorystage1_tb: memorystage1.v.v tb/memorystage1_tb.v
	$(VERILATOR_LINT) --top memorystage1_tb $^
	$(IVERILOG) -s memorystage1_tb -o $@ $^
registersstage2_tb: registersstage2.v.v tb/registersstage2_tb.v
	$(VERILATOR_LINT) --top registersstage2_tb $^
	$(IVERILOG) -s registersstage2_tb -o $@ $^

maxicore32_tb: $(CORE_V_SRC) tb/maxicore32_tb.v maxicore32-ram-contents.txt
	$(VERILATOR_LINT) --top maxicore32_tb $(filter %.v,$^)
	$(IVERILOG) -s maxicore32_tb -o $@ $(filter %.v,$^)

tonegen_tb: tonegen/tonegen.v tb/tonegen/tonegen_tb.v
	$(VERILATOR_LINT) --top tonegen_tb $^
	$(IVERILOG) -s tonegen_tb -o $@ $^
i2c_controller_tb: i2c_controller/i2c_controller.v tb/i2c_controller/i2c_controller_tb.v
	$(VERILATOR_LINT) --top i2c_controller_tb $^
	$(IVERILOG) -s i2c_controller_tb -o $@ $^

maxicore32-ram-contents.txt: asm/test.asm asm/maxicore32def.inc
	(cd asm && \
	customasm maxicore32def.inc test.asm -f binary -o t && \
	truncate -s 2048 t) && \
	xxd -c 4 -ps asm/t > maxicore32-ram-contents.txt

tests: $(ALL_TESTBENCHES)
	set -e; for T in $^; do $(VVP) $$T; done

clean:
	rm -vf $(ALL_TESTBENCHES) businterface_tb *.vcd *.json *.asc *.bin asm/t maxicore32-ram-contents.txt
