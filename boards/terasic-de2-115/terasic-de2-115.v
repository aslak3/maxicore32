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

    // Memory selects
    reg memory_cs = 1'b0;
    reg map_cs = 1'b0;
    reg status_cs = 1'b0;
    reg levels_cs = 1'b0; // This is the EEPROM source data

    // IO selects
    reg led_cs = 1'b0;
    reg ps2_status_cs = 1'b0;
    reg ps2_scancode_cs = 1'b0;
    reg tonegen_duration_cs = 1'b0;
    reg tonegen_period_cs = 1'b0;
    reg tonegen_status_cs = 1'b0;
    reg scroll_cs = 1'b0;
    reg i2c_address_cs = 1'b0;
    reg i2c_read_cs = 1'b0;
    reg i2c_write_cs = 1'b0;
    reg i2c_control_cs = 1'b0;

    // High byte: the device "class", Low byte: used to select IO device registers
    wire [31:2] address;
    wire [7:0] high_byte_address = address[31:24];
    wire [7:0] low_byte_address = { address[7:2], 2'b00 };

    always @ (*) begin
        memory_cs = 1'b0;
        map_cs = 1'b0;
        status_cs = 1'b0;
        levels_cs = 1'b0;
        led_cs = 1'b0;
        ps2_status_cs = 1'b0;
        ps2_scancode_cs = 1'b0;
        tonegen_duration_cs = 1'b0;
        tonegen_period_cs = 1'b0;
        tonegen_status_cs = 1'b0;
        scroll_cs = 1'b0;
        i2c_address_cs = 1'b0;
        i2c_read_cs = 1'b0;
        i2c_write_cs = 1'b0;
        i2c_control_cs = 1'b0;

        case (high_byte_address)
            8'h00: memory_cs = 1'b1;    // Program RAM
            8'h01: map_cs = 1'b1;       // Map RAM
            8'h02: status_cs = 1'b1;    // Status map RAM
            8'h03: levels_cs = 1'b1;    // 8 levels used for I2C EEPROM programming
            8'h0f: begin
                // IO devices
                case (low_byte_address)
                    8'h00: led_cs = 1'b1;
                    8'h04: ps2_status_cs = 1'b1;
                    8'h08: ps2_scancode_cs = 1'b1;
                    8'h0c: tonegen_duration_cs = 1'b1;
                    8'h10: tonegen_period_cs = 1'b1;
                    8'h14: tonegen_status_cs = 1'b1;
                    8'h18: scroll_cs = 1'b1;
                    8'h1c: i2c_address_cs = 1'b1;
                    8'h20: i2c_read_cs = 1'b1;
                    8'h24: i2c_write_cs = 1'b1;
                    8'h28: i2c_control_cs = 1'b1;
                    default: begin
                    end
                endcase
            end
            default: begin
            end
        endcase
    end

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

    reg reset = 1'b0;
    reg [7:0] reset_counter;
    always @ (posedge cpu_clock) begin
        if (reset_counter != 8'hff) begin
            reset <= 1'b1;
            reset_counter <= reset_counter + 8'h01;
        end else begin
            reset <= 1'b0;
        end
    end

    // Asserting onto databus (processor reads)
    wire [31:0] ps2_data_out;
    wire ps2_data_out_valid;
    wire [31:0] tonegen_data_out;
    wire tonegen_data_out_valid;
    wire [31:0] i2c_data_out;
    wire i2c_data_out_valid;
    always @ (*)  begin
        if (memory_cs) begin
            data_in = ram_data_out;
        end else if (map_cs) begin
            data_in = map_data_out;
        end else if (levels_cs) begin
            data_in = levels_data_out;
        end else if (ps2_data_out_valid) begin
            data_in = ps2_data_out;
        end else if (tonegen_data_out_valid) begin
            data_in = tonegen_data_out;
        end else if (i2c_data_out_valid) begin
            data_in = i2c_data_out;
        end else begin
            data_in = 32'h0;
        end
    end

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

	wire buzzer;
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

endmodule
