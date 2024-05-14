module levels_rom
    (
        input       clock,

        input       cs,
        input       [31:2] address,
        output reg  [7:0] data_out,
        input       read
    );

    wire [12:0] low_address = address [14:2];

    reg [7:0] contents [32 * 32 * 8];

    initial begin
        $readmemh("levels.txt", contents);
    end

    always @ (negedge clock) begin
        if (cs) begin
            if (read) begin
                data_out <= contents[low_address];
            end
        end
    end
endmodule
