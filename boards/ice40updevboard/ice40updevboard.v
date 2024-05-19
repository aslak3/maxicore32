`define ENABLE_VGA 1
// `define ENABLE_LEVELS_ROM 1

module ice40updevboard
    (
        input clock,

        output h_sync,
        output v_sync,
        output reg [3:0] red,
        output reg [3:0] green,
        output reg [3:0] blue,
        output n_vga_blank,
        output reg vga_clock,

        output buzzer,
        output [2:0] leds,

        inout ps2a_clock,
        inout ps2a_data,

        inout scl,
        inout sda,

        output [5:0] user
    );

    reg [15:0] clock_counter = 16'h0;
    always @ (posedge clock) begin
        clock_counter <= clock_counter + 16'h01;
    end

    // From 50Mhz/2 to 50Mhz/256; current fMax is just under 12MHz, but /4 seems fine.
    wire cpu_clock = clock_counter[2];

    reg memory_cs = 1'b0;
    reg map_cs = 1'b0;
    reg status_cs = 1'b0;
    reg levels_cs = 1'b0;
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
            8'h02: status_cs = 1'b1;
            8'h03: levels_cs = 1'b1;    // 8 levels used for I2C EEPROM programming
            8'h0f: begin
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

    wire [31:0] data_out;
    wire [31:0] ram_data_out;
    wire [31:0] map_data_out;
    wire [31:0] levels_data_out;
    wire [3:0] data_strobes;
    wire read;
    wire write;

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

    // Asserting onto databus (reads)
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
