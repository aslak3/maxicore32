module display
    (
        input clock,
        input cs,
        input write,
        input [15:0] low_address,
        input [31:0] data_in,
        output reg led
    );

    always @ (negedge clock) begin
        if (cs) begin
            if (write) begin
                led <= data_in[0];
            end
        end
    end
endmodule

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
        output reg [5:0] user
    );

    reg [7:0] clock_counter = 8'h0;
    always @ (posedge clock) begin
        clock_counter <= clock_counter + 8'h01;
    end
    wire cpu_clock = clock_counter[1];

    reg [2:0] decoder_outputs;
    wire memory_cs = decoder_outputs[2];
    wire map_cs = decoder_outputs[1];
    wire display_cs = decoder_outputs[0];
    wire [31:2] address;

    always @ (*) begin
        case (address[31:24])
            8'h00: decoder_outputs = 3'b100;
            8'h01: decoder_outputs = 3'b010;
            8'hff: decoder_outputs = 3'b001;
            default: begin
                decoder_outputs = 3'b000;
            end
        endcase
    end

    wire [31:0] data_out;
    wire [31:0] ram_data_out;
    wire [31:0] map_data_out;
    wire [3:0] data_strobes;
    wire read;
    wire write;

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

    wire [15:0] low_address = { address[15:2], 2'b00 };
    display display (
        .clock(cpu_clock),
        .cs(display_cs),
        .write(write),
        .low_address(low_address),
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

    always @ (*)  begin
        case ({memory_cs, map_cs, display_cs})
            3'b100: data_in = ram_data_out;
            3'b010: data_in = map_data_out;
            default: data_in = 32'h0;
        endcase
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

    assign leds[1] = ~reset;
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
        .clock(cpu_clock),
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

    assign buzzer = 0;
    assign n_vga_blank = 1;
endmodule
