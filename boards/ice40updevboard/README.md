# iCE40UPDevBoard

This is the integration of this project with another of mine, an [iCE40UP5 devboard](https://github.com/aslak3/ICE40UPDevBoard). Since this softcore project had this development board in mind, all hardware is supported except for the Real Time Clock and button.

The usage of the LEDs is as follows:

LED0: Attached to the processor
LED1: Bus error
LED2: Halt

The toolling required is [yosys](https://github.com/YosysHQ/yosys), [nextpnr](https://github.com/YosysHQ/nextpnr) and [icepack](https://github.com/YosysHQ/icestorm). Additioanlly, [Verilator](https://www.veripool.org/verilator/) is used for linting.
