/* verilator lint_off MULTITOP */

module i2s
    (
        input       reset,
        input       clock,

        input       [31:0] data,    // 32-bit input data (16 bits for Left, 16 bits for Right)
        output      done,           // High on the last bit of the I2S data stream

        output      lrclk,          // Left/Right clock (Word Select)
        output      bclk,           // Bit clock
        output      sd              // Serial data output
    );

    reg [7:0] divider_counter;     // Counter for generating the bit clock frequency
    reg [5:0] bit_counter;         // Counter to track the current bit being transmitted (0-63)
    reg [31:0] latched_data;       // Buffer to hold the input data during transmission
    reg got_data;

    reg left_right;                // Represents the current channel (0 for Left, 1 for Right)
    reg bit_clock;                 // The generated bit clock signal
    reg serial_data;               // The actual serial data stream

    always @ (posedge clock) begin
        if (reset) begin
            // Reset all internal state machines and counters
            divider_counter <= 8'd0;
            bit_counter <= 6'd0;
            bit_clock <= 1'b0;
            serial_data <= 1'b0;
            got_data <= 1'b0;
            latched_data <= 32'h0;
        end else begin
            // Increment the divider to control the transmission speed
            divider_counter <= divider_counter + 8'd1;

            // Check for a specific divider value to trigger bit processing
            // This value determines the sampling rate (e.g., 48kHz)
            if (divider_counter[2:0] == 3'b111) begin
                // Generate bit clock and update serial data
                bit_clock <= ~bit_counter[0];
                left_right <= bit_counter[5];

                // Extract the bit from the latched data based on the current bit position
                // Note: This logic uses bit_counter[5:1] to index into the 32-bit word
                serial_data <= latched_data[bit_counter[5:1]];

                // Decrement the bit counter
                bit_counter <= bit_counter - 6'b000001;

                // If all bits have been transmitted, start again
                if (bit_counter == 6'b111111) begin
                    $display("Got: %x", data);
                    latched_data <= data;
                    got_data <= 1'b1;
                    divider_counter <= 8'd0;
                    // bit_counter <= 6'b111111; // Start from the most significant bit
                end

                // Reset divider counter for the next bit
                divider_counter <= 8'd0;
            end
        end
    end

    // Drive the output pins with the internal signals
    assign lrclk = got_data & left_right;
    assign bclk = got_data & bit_clock;
    assign sd = got_data & serial_data;
    assign done = got_data & (divider_counter == 8'd0 && bit_counter == 6'b100000);
endmodule
