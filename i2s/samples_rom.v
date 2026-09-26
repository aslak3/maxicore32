module samples_rom
    (
        input clock,
        input cs,
        input read,
        input [31:2] address,
        output reg [7:0] dout
    );

    reg [7:0] samples_mem [2 ** 13];

    wire [12:0] low_address = address [14:2];

    always @(posedge clock) begin
        if (cs) begin
            if (read) begin
                dout <= samples_mem[low_address]; // Output register controlled by clock.
            end
        end
    end

    initial begin
        $readmemh("samples.txt", samples_mem);
    end
endmodule

