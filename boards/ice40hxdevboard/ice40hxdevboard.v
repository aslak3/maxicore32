// This is the normal state to enable a display; you cannot enable both of these options
// `define ENABLE_VIDEO 1
// Enable this and disable the above when programming the 8 levels into the EEPROM
// `define ENABLE_LEVELS_ROM 1

module ice40hxdevboard
    (
        input       clock,

        output      buzzer,
        output      [2:0] leds,

        // input       [3:0] buttons,

        inout       ps2a_clock,
        inout       ps2a_data,

        inout       scl,
        inout       sda,

        // For tracing signals; usually plumed into the processor
        output      [7:0] user,

        inout       [25:0] exp,
        inout       [1:0] expcbsel,

        inout       [15:0] sdramd,
        output      [12:0] sdrama,
        output      n_sdramcs,
        output      sdramcke,
        output      sdramclk,
        output      sdramdqml,
        output      sdramdqmh,
        output      n_sdramwe,
        output      n_sdramcas,
        output      n_sdramras,

        input       uart_rx,
        output      uart_tx,
        input       uart_dtr
    );

    assign sdramd = 16'h1234;
    assign sdrama = 13'b0;

    assign n_sdramcs = 1'b1;
    assign sdramcke = 1'b0;
    assign sdramclk = 1'b0;
    assign sdramdqml = 1'b0;
    assign sdramdqmh = 1'b0;
    assign n_sdramwe = 1'b1;
    assign n_sdramcas = 1'b1;
    assign n_sdramras = 1'b1;

    // Unused bits should be compiled away
    reg [31:0] clock_counter = 32'h0;
    always @ (posedge clock) begin
        clock_counter <= clock_counter + 32'h1;
    end

    // assign leds = clock_counter[25:23];

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
    wire uart_data_cs;
    wire uart_status_cs;

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
        .i2c_control_cs(i2c_control_cs),
        .uart_data_cs(uart_data_cs),
        .uart_status_cs(uart_status_cs)
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
        .reset(reset),
        .clock(cpu_clock),

        .write(write),
        .cs(led_cs),
        .data_in(data_out),
        .leds(leds)
    );

    reg [31:0] data_in;
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
        .uart_data_out_valid(uart_data_out_valid),
        .uart_data_out(uart_data_out),

        .data_in(data_in)
    );

    wire video_clock;
    wire h_sync, v_sync;
    wire data_enable;
    wire [7:0] red;
    wire [7:0] green;
    wire [7:0] blue;

`ifdef ENABLE_VIDEO
    video video (
        .clock(clock),
        .video_clock(video_clock),
        .h_sync(h_sync),
        .v_sync(v_sync),
        .data_enable(data_enable),
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

    assign exp[7] = video_clock;
    assign exp[10] = h_sync;
    assign exp[11] = v_sync;
    assign exp[25] = data_enable;

    assign exp[17] = red[2];
    assign exp[2] = red[3];
    assign exp[16] = red[4];
    assign exp[1] = red[5];
    assign exp[15] = red[6];
    assign exp[0] = red[7];

    assign exp[20] = green[2];
    assign exp[5] = green[3];
    assign exp[19] = green[4];
    assign exp[4] = green[5];
    assign exp[18] = green[6];
    assign exp[3] = green[7];

    assign exp[9] = blue[2];
    assign exp[23] = blue[3];
    assign exp[8] = blue[4];
    assign exp[22] = blue[5];
    assign exp[21] = blue[6];
    assign exp[6] = blue[7];

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

    wire [31:0] uart_data_out;
    wire uart_data_out_valid;
    uart_interface uart_interface (
        .reset(reset),
        .clock(cpu_clock),

        .read(read),
        .write(write),

        .data_cs(uart_data_cs),
        .status_cs(uart_status_cs),
        .data_in(data_out),
        .data_out(uart_data_out),
        .data_out_valid(uart_data_out_valid),

        .tx(uart_tx),
        .rx(uart_rx)
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
        .halted(halted)
    );
endmodule

module pll #(
        parameter DIVR = 0,
        parameter DIVF = 0,
        parameter DIVQ = 0
    )
    (
        input in_clock,
        output out_clock,
        output locked
    );

    wire internal_clock;

`ifndef VERILATOR
    SB_PLL40_CORE #(
        .FEEDBACK_PATH("SIMPLE"),

        .DIVR(DIVR),
        .DIVF(DIVF),
        .DIVQ(DIVQ),

        .FILTER_RANGE(3'b001)   // FILTER_RANGE = 1
    ) uut (
        .LOCK(locked),
        .RESETB(1'b1),
        .BYPASS(1'b0),
        .REFERENCECLK(in_clock),
        .PLLOUTCORE(out_clock)
    );
`endif
endmodule
