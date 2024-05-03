module tonegen
    (
        input reset,
        input clock,
        input write,
        input duration_cs,
        input period_cs,
        input [31:0] data_in,
        output reg sounder
    );

    reg [31:0] duration_counter = 32'h0;
    reg [31:0] period_counter = 32'h0;
    reg [31:0] start_period_counter = 32'h0;

    always @ (posedge clock) begin
        if (reset) begin
            duration_counter <= 32'h0;
            period_counter <= 32'h0;
            start_period_counter <= 32'h0;
            sounder <= 1'b0;
        end else begin
            if (write) begin
                if (duration_cs) begin
                    duration_counter <= data_in;
                end

                if (period_cs) begin
                    period_counter <= data_in;
                    start_period_counter <= data_in;
                end
            end

            if (duration_counter != 32'h0) begin
                if (period_counter == 32'h0) begin
                    sounder <= ~sounder;
                    period_counter <= start_period_counter;
                end else begin
                    period_counter <= period_counter - 32'h1;
                end

                duration_counter <= duration_counter - 32'h1;
            end else begin
                sounder <= 1'b0;
            end
        end
    end
endmodule
