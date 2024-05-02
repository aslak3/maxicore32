module led
    (
        input clock,
        input cs,
        input write,
        input [31:0] data_in,
        output reg led
    );

    always @ (posedge clock) begin
        if (cs) begin
            if (write) begin
                $display("LED DATA: %08x", data_in);
                led <= data_in[0];
            end
        end
    end
endmodule
