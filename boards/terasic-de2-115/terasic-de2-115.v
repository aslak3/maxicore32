// This is the normal state to enable a display; you cannot enable both of these options
`define ENABLE_VGA 1
// Enable this and disable the above when programming the 8 levels into the EEPROM
// `define ENABLE_LEVELS_ROM 1

module terasicde2115
    (
        input       CLOCK_50,

        output      VGA_HS,
        output      VGA_VS,
        output reg  [7:0] VGA_R,
        output reg  [7:0] VGA_G,
        output reg  [7:0] VGA_B,
        output      VGA_BLANK_N,
        output reg  VGA_CLK,

        output      [17:0] LEDR,

        inout       PS2_CLK,
        inout       PS2_DAT,

        inout       EEP_I2C_SCLK,
        inout       EEP_I2C_SDAT,

        // For tracing signals; usually plumed into the processor
        output      [7:0] LEDG
    );

    // Unused bits should be compiled away
    reg [15:0] clock_counter = 16'h0;
    always @ (posedge CLOCK_50) begin
        clock_counter <= clock_counter + 16'h01;
    end

    // From 50Mhz/2 to 50Mhz/256; current fMax is just under 12MHz, but /4 seems fine.
    wire cpu_clock = clock_counter[2];

    // High byte: the device "class", Low byte: used to select IO device registers
    wire [31:2] address;

    // Memory selects
    wire memory_cs;
    wire map_cs;
    wire status_cs;
    wire levels_cs;  // This is the EEPROM source data

    // IO selects
    wire led_cs;
    wire ps2_status_cs;
    wire ps2_scancode_cs;
    wire tonegen_duration_cs;
    wire tonegen_period_cs;
    wire tonegen_status_cs;
    wire scroll_cs;
    wire i2c_address_cs;
    wire i2c_read_cs;
    wire i2c_write_cs;
    wire i2c_control_cs;

    addr_decode addr_decode (
        .address(address),
        .memory_cs(memory_cs),
        .map_cs(map_cs),
        .status_cs(status_cs),
        .levels_cs(levels_cs),
        .led_cs(led_cs),
        .ps2_status_cs(ps2_status_cs),
        .ps2_scancode_cs(ps2_scancode_cs),
        .tonegen_duration_cs(tonegen_duration_cs),
        .tonegen_period_cs(tonegen_period_cs),
        .tonegen_status_cs(tonegen_status_cs),
        .scroll_cs(scroll_cs),
        .i2c_address_cs(i2c_address_cs),
        .i2c_read_cs(i2c_read_cs),
        .i2c_write_cs(i2c_write_cs),
        .i2c_control_cs(i2c_control_cs)
    );

    // Outputs (egress) from various modules
    wire [31:0] data_out; // Processor
    wire [3:0] data_strobes;
    wire read;
    wire write;
    // Outputs from memories
    wire [31:0] ram_data_out;
    wire [31:0] map_data_out;
    wire [31:0] levels_data_out;

    // This is the program memory
    memory memory (
        .clock(cpu_clock),
        .cs(memory_cs),
        .address(address),
        .data_in(data_out),
        .data_out(ram_data_out),
        .data_strobes(data_strobes),
        .read(read),
        .write(write)
    );

`ifdef ENABLE_LEVELS_ROM
    levels_rom levels_rom (
        .clock(cpu_clock),
        .cs(levels_cs),
        .address(address),
        .data_out(levels_data_out[31:24]),
        .read(read)
    );
`endif

    led led (
        .clock(cpu_clock),
        .write(write),
        .cs(led_cs),
        .data_in(data_out),
        .led(LEDR[0])
    );

    reg [31:0] data_in;
    wire bus_error;
    wire halted;

    // Asserting onto databus (processor reads)
    data_in_mux data_in_mux (
        .memory_cs(memory_cs),
        .ram_data_out(ram_data_out),
        .map_cs(map_cs),
        .map_data_out(map_data_out),
        .levels_cs(levels_cs),
        .levels_data_out(levels_data_out),

        .ps2_data_out_valid(ps2_data_out_valid),
        .ps2_data_out(ps2_data_out),
        .tonegen_data_out_valid(tonegen_data_out_valid),
        .tonegen_data_out(tonegen_data_out),
        .i2c_data_out_valid(i2c_data_out_valid),
        .i2c_data_out(i2c_data_out),

        .data_in(data_in)
    );
   
    assign LEDG[7:6] = 2'b0;

    // On my "beta" board these are active low.
    assign LEDR[1] = bus_error;
    assign LEDR[2] = halted;
    assign LEDR[17:3] = 15'b0;

    vga_clock_gen vga_clock_gen (
        .clock(CLOCK_50),
        .vga_clock(VGA_CLK)
    );

`ifdef ENABLE_VGA
    vga vga (
        .vga_clock(VGA_CLK),
        .h_sync(VGA_HS),
        .v_sync(VGA_VS),
        .n_vga_blank(VGA_BLANK_N),
        .red(VGA_R[7:4]),
        .green(VGA_G[7:4]),
        .blue(VGA_B[7:4]),

        .cpu_clock(cpu_clock),
        .read(read),
        .write(write),
        .address(address),
        .map_cs(map_cs),
        .scroll_cs(scroll_cs),
        .status_cs(status_cs),
        .data_in(data_out),
        .map_data_out(map_data_out)
    );
`endif

    assign VGA_R[3:0] = 4'h0;
    assign VGA_G[3:0] = 4'h0;
    assign VGA_B[3:0] = 4'h0;

    wire reset;
    reset_gen reset_gen (
        .clock(cpu_clock),
        .reset(reset)
    );

    wire [31:0] i2c_data_out;
    wire i2c_data_out_valid;
    i2c_interface i2c_interface (
        .clock(cpu_clock),
        .reset(reset),
        .read(read),
        .write(write),
        .address_cs(i2c_address_cs),
        .read_cs(i2c_read_cs),
        .write_cs(i2c_write_cs),
        .control_cs(i2c_control_cs),
        .data_in(data_out),
        .data_out(i2c_data_out),
        .data_out_valid(i2c_data_out_valid),
        .scl(EEP_I2C_SCLK),
        .sda(EEP_I2C_SDAT)
    );

    wire [31:0] ps2_data_out;
    wire ps2_data_out_valid;
    ps2_interface ps2_interface (
        .clock(cpu_clock),
        .read(read),
        .status_cs(ps2_status_cs),
        .scancode_cs(ps2_scancode_cs),
        .data_out(ps2_data_out),
        .data_out_valid(ps2_data_out_valid),
        .ps2_clock(PS2_CLK),
        .ps2_data(PS2_DAT)
    );

    // Signals that have no "prefix" are for the processor, eg. data_in, data_out
    maxicore32 maxicore32 (
        .reset(reset),
        .clock(cpu_clock),
        .address(address),
        .data_in(data_in),
        .data_out(data_out),
        .data_strobes(data_strobes),
        .read(read),
        .write(write),
        .bus_error(bus_error),
        .halted(halted),
        .user(LEDG[5:0])
    );

endmodule
