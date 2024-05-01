module char_rom
    (
        input clock,
        input [6:0] char_index,
        input [2:0] row_index,
        output reg [7:0] dout
    );

    reg [7:0] char_mem [1024];
    reg [7:0] data_reg;

    always @(posedge clock) begin
        dout <= char_mem[{char_index, row_index}]; // Output register controlled by clock.
    end

    initial begin
        $readmemh("IBM_PC_V1_8x8.txt", char_mem);
    end
endmodule
