// This is the normal state to enable a display; you cannot enable both of these options
`define ENABLE_VGA 1
// Enable this and disable the above when programming the 8 levels into the EEPROM
// `define ENABLE_LEVELS_ROM 1

module ice40updevboard
    (
        input       clock,

        output      h_sync,
        output      v_sync,
        output reg  [3:0] red,
        output reg  [3:0] green,
        output reg  [3:0] blue,
        output      n_vga_blank,
        output reg  vga_clock,

        output      buzzer,
        output      [2:0] leds,

        inout       ps2a_clock,
        inout       ps2a_data,

        inout       scl,
        inout       sda,

        // For tracing signals; usually plumed into the processor
        output      [5:0] user
    );

    // Unused bits should be compiled away
    reg [15:0] clock_counter = 16'h0;
    always @ (posedge clock) begin
        clock_counter <= clock_counter + 16'h01;
    end

    // From 50Mhz/2 to 50Mhz/256; current fMax is just under 12MHz, but /4 seems fine.
    wire cpu_clock = clock_counter[1];

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
        .led(leds[0])
    );

    wire [31:0] data_in;
    wire bus_error;
    wire halted;

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

    vga_clock_gen vga_clock_gen (
        .clock(clock),
        .vga_clock(vga_clock)
    );

`ifdef ENABLE_VGA
    vga vga (
        .vga_clock(vga_clock),
        .h_sync(h_sync),
        .v_sync(v_sync),
        .n_vga_blank(n_vga_blank),
        .red(red),
        .green(green),
        .blue(blue),

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
        .scl(scl),
        .sda(sda)
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
        .ps2_clock(ps2a_clock),
        .ps2_data(ps2a_data)
    );

    wire [31:0] tonegen_data_out;
    wire tonegen_data_out_valid;
    tonegen_interface tonegen_interface (
        .reset(reset),
        .clock(cpu_clock),
        .read(read),
        .write(write),
        .duration_cs(tonegen_duration_cs),
        .period_cs(tonegen_period_cs),
        .status_cs(tonegen_status_cs),
        .data_in(data_out),
        .data_out(tonegen_data_out),
        .data_out_valid(tonegen_data_out_valid),
        .buzzer(buzzer)
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
        .user(user)
    );

    // On my "beta" board these are active low.
    assign leds[1] = ~bus_error;
    assign leds[2] = ~halted;
endmodule
