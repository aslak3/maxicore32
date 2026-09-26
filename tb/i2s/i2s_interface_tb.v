module i2s_interface_tb;

    // Clock / reset
    reg clock = 0;
    reg reset = 1;

    // Bus interface signals
    reg read = 0, write = 0;
    reg [3:0] data_cs = 4'h0, rate_cs = 4'h0;
    reg status_cs = 0;
    reg [31:0] data_in = 32'h0;
    wire [31:0] data_out;
    wire data_out_valid;

    // I2S outputs
    wire lrclk, bclk, sd;

    // Instantiate the DUT
    i2s_interface dut (
        .reset(reset),
        .clock(clock),

        .read(read),
        .write(write),
        .data_cs(data_cs),
        .rate_cs(rate_cs),
        .status_cs(status_cs),

        .data_in(data_in),
        .data_out(data_out),
        .data_out_valid(data_out_valid),

        .lrclk(lrclk),
        .bclk(bclk),
        .sd(sd)
    );

    always #1 clock = ~clock;

    // ---------- Test stimulus ----------
    initial begin
        // Release reset
        #20 reset = 0;

        // 1. Write rates for all four channels (write must be high!)
        write   = 1;
        rate_cs = 4'b0001; data_in = {16'd1, 16'h0000};  // Channel 0 – 4 samples
        #10;
        // rate_cs = 4'b0010; data_in = {16'd8, 16'h0000};  // Channel 1 – 8 samples
        // #10;
        // rate_cs = 4'b0100; data_in = {16'd4, 16'h0000};  // Channel 2 – 4 samples
        // #10;
        // rate_cs = 4'b1000; data_in = {16'd8, 16'h0000};  // Channel 3 – 8 samples
        // #10;
        write   = 0; rate_cs = 4'b0000; data_in = 32'h0;  // Disable rate CS
        #10;

        // 2. Write data for all four channels (now that rates are set)
        write   = 1;
        data_cs = 4'b0001; data_in = {16'hff00, 16'h0000};  // Channel 0
        #10;
        // data_cs = 4'b0010; data_in = {16'h5678, 16'h0000};  // Channel 1
        // #10;
        // data_cs = 4'b0100; data_in = {16'h9ABC, 16'h0000};  // Channel 2
        // #10;
        // data_cs = 4'b1000; data_in = {16'hDEF0, 16'h0000};  // Channel 3
        // #10;
        write   = 0; data_cs = 4'b0000;
        #10;

        // 3. Poll status register until all finished bits are set
        status_cs = 1; read = 1;

        // Wait until all four finished bits are high
        wait (data_out[31] && data_out[30] && data_out[29] && data_out[28]);

        $display("All channels finished after %0t ns", $time);

        // 4. Read status register one more time for final values
        #10;
        $display("Final status: 0x%08X", data_out);
        $display("Finished bits: %b %b %b %b",
             data_out[31], data_out[30], data_out[29], data_out[28]);

        // 1. Write rates for all four channels (write must be high!)
        write   = 1;
        rate_cs = 4'b0001; data_in = {16'd1, 16'h0000};  // Channel 0 – 4 samples
        #10;
        // rate_cs = 4'b0010; data_in = {16'd8, 16'h0000};  // Channel 1 – 8 samples
        // #10;
        // rate_cs = 4'b0100; data_in = {16'd4, 16'h0000};  // Channel 2 – 4 samples
        // #10;
        // rate_cs = 4'b1000; data_in = {16'd8, 16'h0000};  // Channel 3 – 8 samples
        // #10;
        write   = 0; rate_cs = 4'b0000; data_in = 32'h0;  // Disable rate CS
        #10;

        // 2. Write data for all four channels (now that rates are set)
        write   = 1;
        data_cs = 4'b0001; data_in = {16'hbeef, 16'h0000};  // Channel 0
        #10;
        // data_cs = 4'b0010; data_in = {16'h5678, 16'h0000};  // Channel 1
        // #10;
        // data_cs = 4'b0100; data_in = {16'h9ABC, 16'h0000};  // Channel 2
        // #10;
        // data_cs = 4'b1000; data_in = {16'hDEF0, 16'h0000};  // Channel 3
        // #10;
        write   = 0; data_cs = 4'b0000;
        #10;

        // 3. Poll status register until all finished bits are set
        status_cs = 1; read = 1;

        // Wait until all four finished bits are high
        wait (data_out[31] && data_out[30] && data_out[29] && data_out[28]);

        $display("All channels finished after %0t ns", $time);

        // 4. Read status register one more time for final values
        #10;
        $display("Final status: 0x%08X", data_out);
        $display("Finished bits: %b %b %b %b",
             data_out[31], data_out[30], data_out[29], data_out[28]);



        // 5. Finish simulation
        $finish;
    end

    // Waveform dump
    initial begin
        $dumpfile("i2s_interface_tb.vcd");
        $dumpvars(0, i2s_interface_tb);
    end

endmodule