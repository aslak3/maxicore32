module palette_rom
    (
        input clock,
        input read,
        input [3:0] color_index,
        output reg [15:0] rgb_out
    );

    reg [15:0] palette_mem [16];

    always @(posedge clock) begin
        if (read) begin
            rgb_out <= palette_mem[color_index]; // Output register controlled by clock.
        end
    end

    initial begin
        $readmemh("palette.txt", palette_mem);
    end
endmodule
