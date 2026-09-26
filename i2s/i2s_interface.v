/* verilator lint_off MULTITOP */

// Channels are Left: 0, 1; Right: 2, 3

module i2s_interface
    (
        input       reset,
        input       clock,

        // Bus interface signals
        input       read,               // Bus read signal
        input       write,              // Bus write signal
        input       [3:0] data_cs,      // Data chip select for each channel
        input       [3:0] rate_cs,      // Rate chip select for each channel
        input       status_cs,          // Status chip select
        input       [31:0] data_in,     // Data input from bus
        output reg  [31:0] data_out,    // Data output to bus
        output      data_out_valid,     // Data valid signal for bus read

        // I2S output signals
        output      lrclk,              // Left/Right clock
        output      bclk,               // Bit clock
        output      sd                  // Serial data
    );

    // Per channel data
    reg [15:0] rate [3:0];              // Sample rate for each channel
    reg signed [15:0] data [3:0];              // What's currently being played on each channel
    reg [15:0] rate_countdown [3:0];    // Count own for repeats of data transmission
    reg [3:0] finished;

    // Data for all channels
    reg done;                           // Set on the last bit of I2S data

    // Handle bus read requests for status/data
    always @ (*) begin
        if (status_cs) begin
            data_out = {
                finished[0], finished[1], finished[2], finished[3],
                4'b0000, 24'h000000
            };
        end else begin
            data_out = 32'h0;
        end
    end

    // Assert data_out_valid when a valid read occurs on the status register
    assign data_out_valid = read && status_cs ? 1'b1 : 1'b0;

    // Handle bus write requests and data buffering
    always @ (posedge clock) begin
        if (reset) begin
            for (int i = 0; i < 4; i++) begin
                data[i] <= 16'sd0; // Signed
                finished[i] <= 1'b1;
            end
        end

        // Handle data write from the bus
        for (int i = 0; i < 4; i++) begin
            if (write) begin
                if (data_cs[i]) begin
                    $display("Write: %d %x", i, data_in[31:16]);
                    data[i] <= data_in[31:16];
                    rate_countdown[i] <= rate[i];
                    finished[i] <= 1'b0;
                end
                if (rate_cs[i]) begin
                    rate[i] <= data_in[31:16];
                end
            end

            if (done) begin
                if (rate_countdown[i] != 16'd1) begin
                    rate_countdown[i] <= rate_countdown[i] - 16'd1;
                end else begin
                    finished[i] <= 1'b1;
                end
            end
        end
    end

    // Simple average for mixing two channels;
    wire signed [16:0] channel_l_total = ( data[0] + data[1] );
    wire signed [16:0] channel_r_total = ( data[2] + data[3] );
    wire [31:0] mixed_data = { channel_l_total [16:1], channel_r_total [16:1] };
    // wire [31:0] mixed_data = { data[0], data[0] };

    // Instantiate the underlying I2S peripheral
    i2s i2s
    (
        .reset(reset),
        .clock(clock),

        .data(mixed_data),
        .done(done),

        .lrclk(lrclk),
        .bclk(bclk),
        .sd(sd)
    );
endmodule
