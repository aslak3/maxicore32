/* verilator lint_off MULTITOP */

module i2s
    (
        input       reset,
        input       clock,

        input       [31:0] data,
        input       trigger,
        output      running,

        output      lrclk,
        output      bclk,
        output      sd
    );

    reg [7:0] divider_counter;
    reg counter_top, previous_counter_top;
    reg divider_running = 1'b0;
    reg [5:0] bit_counter;
    reg [31:0] latched_data; // Left and Right, each 16 bits

    reg left_right;
    reg bit_clock;
    reg serial_data;

    always @ (posedge clock) begin
        if (reset) begin
            divider_running <= 1'b0;
            divider_counter <= 8'd0;
            counter_top <= 1'b0;
            previous_counter_top <= 1'b0;
            left_right <= 1'b0;
            bit_clock <= 1'b0;
            serial_data <= 1'b0;
        end else begin
            if (trigger) begin
                latched_data <= data;
                divider_counter <= 8'd0;
                divider_running <= 1'b1;
                bit_counter <= 6'b111111;
            end else begin
                if (divider_running) begin
                    divider_counter <= divider_counter + 8'd1;
                    previous_counter_top <= counter_top;
                    counter_top <= divider_counter[4];

                    // if (divider_counter[2:0] == 3'b111) begin // 48.9Khz
                    if (divider_counter[5:0] == 6'b100011) begin
                        bit_clock <= ~bit_counter[0];
                        left_right <= bit_counter[5];
                        serial_data <= latched_data[bit_counter[5:1]];
                        bit_counter <= bit_counter - 6'b000001;

                        if (bit_counter == 6'b000000) begin
                            divider_running <= 1'b0;
                        end
                        divider_counter <= 8'd0;
                    end
                end
            end
        end
    end

    assign lrclk = left_right;
    assign bclk = bit_clock;
    assign sd = serial_data;
    assign running = divider_running;
endmodule
