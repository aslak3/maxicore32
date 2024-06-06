module vga
    (
        input vga_clock,
        output h_sync,
        output v_sync,
        output n_vga_blank,
        output reg [3:0] red,
        output reg [3:0] green,
        output reg [3:0] blue,

        input cpu_clock,
        input read,
        input write,
        input [31:2] address,
        input map_cs,
        input scroll_cs,
        input status_cs,
        input [31:0] data_in,
        output [31:0] map_data_out
    );

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
    wire [4:0] internal_tile_count = 5'b00000 - viewable_h_count[4:0];

    wire [7:0] map_tile_index;
    // This is the byte address (not tile address) of the top left tile, 5 bits for row and 5 for column
    reg [11:2] scroll = 10'b0000000000;
    // This is the dual ported map RAM, port a is for reading by the VGA generator, and port b is the
    // processor, which is read and write via two copies of the map, since the iCE40 does not have true
    // dual port block RAM.
    map_ram map_ram (
        .a_clock(vga_clock),
        // Scanning beam is in vertical visual range, we are not in the top tile row (for status row),
        // and we are the right most position of the tile
        .a_read(v_visible && v_count[9:5] != 5'b00000 && viewable_h_count[4:0] == 5'b11111),
        // Subtract one because of the status row
        .a_row_index(scroll[11:7] + v_count[9:5] - 5'b1),
        .a_col_index(scroll[6:2] + h_count[9:5]),
        .a_out(map_tile_index),
        .b_clock(cpu_clock),
        .b_cs(map_cs),
        .b_read(read),
        .b_write(write),
        // To simplify hardware: each byte wide tile is presented at a long address
        .b_row_index(address[11:7]),
        .b_col_index(address[6:2]),
        .b_in(data_in[31:24]),
        .b_out(map_data_out[31:24])
    );

    wire [7:0] status_tile_index;
    status_ram status_ram (
        .a_clock(vga_clock),
        // Scanning beam is in vertical visual range, we are the top tile row, and we are at the right most
        // position of the tile
        .a_read(v_visible && v_count[9:5] == 5'b00000 && viewable_h_count[4:0] == 5'b11111),
        .a_col_index(h_count[9:5]),
        .a_out(status_tile_index),
        .b_clock(cpu_clock),
        .b_cs(status_cs),
        // Processor cannot read-back, which saves some block RAM
        .b_write(write),
        .b_col_index(address[6:2]),
        .b_in(data_in[31:24])
    );

    // Mux between the main view and the status line
    wire [7:0] tile_index = v_count[9:5] != 5'b00000 ? map_tile_index : status_tile_index;

    always @ (posedge cpu_clock) begin
        if (write) begin
            if (scroll_cs) begin
                scroll = data_in[11:2];
            end
        end
    end

    // tile_data is a row of tile, ie 16*4 bits per pixel bits
    wire [16*4-1:0] tile_data;
    tile_rom tile_rom (
        .clock(vga_clock),
        .read(v_visible),
        .tile_index(tile_index[5:0]),
        .row_index(v_count[4:1]),
        .dout(tile_data)
    );

    wire [15:0] rgb_data;
    palette_lookup palette_lookup (
        // Extract the colour index from the tile data row using the current horizontal pixel coordinate within the
        // tile. This is a combinational ROM.
        .colour_index(tile_data[4*internal_tile_count[4:1]+:4]),
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
endmodule

module vga_clock_gen
    (
        input clock,
        output vga_clock
    );

    reg t = 0;

    always @ (posedge clock) begin
        t = ~t;
    end

    assign vga_clock = t;
endmodule

module vga_sync
    (
        input clock,
        output reg h_sync,
        output reg v_sync,
        output h_visible,
        output v_visible,
        output [9:0] h_count,
        output [9:0] v_count,
        output [9:0] frame_count
    );

    reg [9:0] h;
    reg [9:0] v;
    reg [9:0] frame;
	always @ (posedge clock) begin
		// Scanning beam path
		if (h < 800) begin
		    h <= h + 1;
        end else begin
			h <= 0;
			if (v < 525) begin
			    v <= v + 1;
            end else begin
				v <= 0;
			    frame <= frame + 1;
			end
		end

		// AKA H sync
		if (h > 640 + 16 + 16 && h <= 640 + 16 + 96 - 16) begin
			h_sync <= 0;
        end else begin
			h_sync <= 1;
        end

		// AKA V sync
		if (v >= 480 + 10 && v < 480 + 10 + 2) begin
			v_sync <= 0;
        end else begin
			v_sync <= 1;
		end
    end

    assign h_visible = h > 16 && h <= 640 + 16 ? 1 : 0;
    assign v_visible = v < 480 ? 1 : 0;

    assign h_count = h;
    assign v_count = v;
    assign frame_count = frame;
endmodule
