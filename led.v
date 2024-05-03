module led
    (
        input clock,
        input write,
        input cs,
        input [31:0] data_in,
        output reg led
    );

    always @ (posedge clock) begin
        if (write) begin
            if (cs) begin
                $display("LED DATA: %08x", data_in);
                led <= data_in[0];
            end
        end
    end
endmodule
