module palette_lookup
    (
        input [3:0] colour_index,
        output reg [15:0] rgb_out
    );

    reg [15:0] palette_mem [16];

    // Combinatorial lookup of colour value from index
    always @ (*) begin
        rgb_out = palette_mem[colour_index];
    end

    initial begin
        $readmemh("palette.txt", palette_mem);
    end
endmodule
