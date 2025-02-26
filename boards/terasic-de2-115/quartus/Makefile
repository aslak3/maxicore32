# A very crude makefile...

PROJECT=terasic-de2-115

default: all

all:
	quartus_map $(PROJECT)
	quartus_fit $(PROJECT) --part=EP4CE115F29C7
	quartus_asm $(PROJECT)
	quartus_sta $(PROJECT)

program_fpga:
	quartus_pgm --mode JTAG --operation p\;$(PROJECT).sof
