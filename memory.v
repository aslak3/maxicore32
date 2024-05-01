module memory
    (
        input       clock,

        input       cs,
        input       [31:2] address,
        input       [31:0] data_in,
        output reg  [31:0] data_out,
        input       [3:0] data_strobes,
        input       read,
        input       write
    );

    wire [9:0] low_byte_address = address [11:2];

    reg [31:0] contents [1024];

    initial begin
        $readmemh("maxicore32-ram-contents.txt", contents);
    end

    always @ (negedge clock) begin
        if (cs) begin
            if (write) begin
                if (data_strobes [3]) begin
                    contents[low_byte_address][31:24] <= data_in[31:24];
                end
                if (data_strobes [2]) begin
                    contents[low_byte_address][23:16] <= data_in[23:16];
                end
                if (data_strobes [1]) begin
                    contents [low_byte_address][15:8] <= data_in[15:8];
                end
                if (data_strobes [0]) begin
                    contents [low_byte_address][7:0] <= data_in[7:0];
                end
            end

            if (read) begin
                data_out <= contents[low_byte_address];
            end
        end
    end
endmodule
