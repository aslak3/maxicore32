module led
    (
        input reset,
        input clock,

        input write,
        input cs,
        input [31:0] data_in,
        output reg [2:0] leds
    );

    always @ (posedge clock) begin
        if (reset == 1'b1) begin
            leds <= 3'b111;
        end else begin
            if (write) begin
                if (cs) begin
                    $display("LED DATA: %08x", data_in);
                    leds <= data_in[26:24];
                end
            end
        end
    end
endmodule
