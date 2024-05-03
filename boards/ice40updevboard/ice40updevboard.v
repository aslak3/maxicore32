module ice40updevboard
    (
        input clock,

        output h_sync,
        output v_sync,
        output reg [3:0] red,
        output reg [3:0] green,
        output reg [3:0] blue,
        output n_vga_blank,
        output vga_clk,

        output buzzer,
        output [2:0] leds,

        inout ps2a_clock,
        inout ps2a_data,

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
    reg led_cs = 1'b0;
    reg ps2_status_cs = 1'b0;
    reg ps2_scancode_cs = 1'b0;
    reg tonegen_duration_cs = 1'b0;
    reg tonegen_period_cs = 1'b0;
    
    wire [31:2] address;
    wire [7:0] high_byte_address = address[31:24];
    wire [7:0] low_byte_address = { address[7:2], 2'b00 };

    always @ (*) begin
        memory_cs = 1'b0;
        map_cs = 1'b0;
        led_cs = 1'b0;
        ps2_status_cs = 1'b0;
        ps2_scancode_cs = 1'b0;
        tonegen_duration_cs = 1'b0;
        tonegen_period_cs = 1'b0;

        case (high_byte_address)
            8'h00: memory_cs = 1'b1;   // Program RAM
            8'h01: map_cs = 1'b1;      // Map RAM
            8'h02: begin
                case (low_byte_address)
                    8'h00: led_cs = 1'b1;
                    8'h04: ps2_status_cs = 1'b1;
                    8'h08: ps2_scancode_cs = 1'b1;
                    8'h0c: tonegen_duration_cs = 1'b1;
                    8'h10: tonegen_period_cs = 1'b1;
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

    led led (
        .clock(cpu_clock),
        .write(write),
        .cs(led_cs),
        .data_in(data_out),
        .led(leds[0])
    );

    tonegen tonegen (
        .reset(reset),
        .clock(cpu_clock),
        .write(write),
        .duration_cs(tonegen_duration_cs),
        .period_cs(tonegen_period_cs),
        .data_in(data_out),
        .sounder(buzzer)
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

    // Asserting onto databus
    always @ (*)  begin
        if (memory_cs) begin
            data_in = ram_data_out;
        end else if (map_cs) begin
            data_in = map_data_out;
        end else if (ps2_status_cs) begin
            data_in = { ps2_scancode_ready, ps2_parity_error, 6'b000000, 24'h000000 };
        end else if (ps2_scancode_cs) begin
            data_in = { ps2_rx_scancode, 24'h0000000 };
        end else begin
            data_in = 32'h0;
        end
    end

    reg ps2_scancode_ready = 1'b0;
    always @ (posedge clock) begin
        if (ps2_scancode_cs) begin
            ps2_scancode_ready <= 1'b0;
        end

        if (ps2_scancode_ready_set) begin
            ps2_scancode_ready <= 1'b1;
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

    assign leds[1] = ~ps2_scancode_ready_set;
    assign leds[2] = ~halted;

    wire vga_clock;

    vga_clock_gen vga_clock_gen (
        .clock(clock),
        .vga_clock(vga_clock)
    );
    assign vga_clk = vga_clock;

    reg h_visible;
    reg v_visible;
    reg [9:0] h_count;
    reg [9:0] v_count;
    reg [9:0] frame_count;
    vga_sync vga_sync (
        .clock(vga_clock),
        .h_sync(h_sync),
        .v_sync(v_sync),
        .h_visible(h_visible),
        .v_visible(v_visible),
        .h_count(h_count),
        .v_count(v_count),
        .frame_count(frame_count)
    );
    wire [9:0] viewable_h_count = h_count - 10'd16;

    reg [5:0] proc_row_index = 6'b0;
    reg [5:0] proc_col_index = 6'b0;

    wire proc_clock = v_visible;
    reg proc_read = 1'b0;
    reg proc_write = 1'b0;
    reg [7:0] proc_out = 8'h0;
    wire [7:0] proc_in;

    wire [7:0] tile_index;
    map_ram map_ram (
        .a_clock(vga_clock),
        .a_read(v_visible & viewable_h_count[4:0] == 5'b11111),
        .a_row_index(v_count[9:5]),
        .a_col_index(h_count[9:5]),
        .a_out(tile_index),
        .b_clock(cpu_clock),
        .b_cs(map_cs),
        .b_read(read),
        .b_write(write),
        .b_row_index(address[11:7]),
        .b_col_index(address[6:2]),
        .b_in(data_out[31:24]),
        .b_out(map_data_out[31:24])
    );

    wire [16*4-1:0] tile_data;
    tile_rom tile_rom (
        .clock(vga_clock),
        .read(v_visible),
        .tile_index(tile_index[5:0]),
        .row_index(v_count[4:1]),
        .dout(tile_data)
    );

    reg [3:0] color_index;
    always @ (posedge vga_clock) begin
        if (h_visible == 1 && v_visible == 1) begin
            color_index <= tile_data[4*viewable_h_count[4:1]+:4];
        end
    end

    wire [15:0] rgb_data;
    palette_rom palette_rom (
        .clock(vga_clock),
        .read(1'b1),
        .color_index(color_index),
        .rgb_out(rgb_data)
    );

    always @ (posedge vga_clock) begin
        if (h_visible == 1 && v_visible == 1) begin
            red <= rgb_data[11:8];
            green <= rgb_data[7:4];
            blue <= rgb_data[3:0];
        end else begin
            red <= 4'h0;
            green <= 4'h0;
            blue <= 4'h0;
        end
    end

    assign n_vga_blank = 1;

    wire ps2_edge_found;
	ps2_edge_finder ps2_edge_finder (
		.clock(cpu_clock),
		.edge_found(ps2_edge_found),
		.ps2_clock(ps2a_clock)
	);

    wire [7:0] ps2_rx_scancode;
    wire ps2_scancode_ready_set;
    wire ps2_parity_error;
    ps2_rx_shifter ps2_rx_shifter (
		.clock(cpu_clock),
		.edge_found(ps2_edge_found),
		.rx_scancode(ps2_rx_scancode),
		.scancode_ready_set(ps2_scancode_ready_set),
		.parity_error(ps2_parity_error),
		.ps2_data(ps2a_data)
	);
endmodule
