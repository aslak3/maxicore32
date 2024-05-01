module tile_rom
    (
        input clock,
        input read,
        input [5:0] tile_index, // Only 12*4 = 48
        input [3:0] row_index,
        output reg [4*16-1:0] dout
    );

    reg [4*16-1:0] tile_mem [16 * 12*4];

    always @(posedge clock) begin
        if (read) begin
            dout <= tile_mem[{tile_index, row_index}]; // Output register controlled by clock.
        end
    end

    initial begin
        $readmemh("tiles.txt", tile_mem);
    end
endmodule
