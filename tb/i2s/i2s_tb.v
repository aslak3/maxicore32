// Claude :/

`timescale 1ns / 1ps

module i2s_tb;
    reg clock;
    reg reset;
    reg [15:0] data;
    reg trigger;

    wire ws;
    wire bclk;
    wire sd;
    wire running;

    // Instantiate the i2s module
    i2s uut (
        .reset(reset),
        .clock(clock),
        .data(data),
        .trigger(trigger),
        .ws(ws),
        .bclk(bclk),
        .sd(sd),
        .running(running)
    );

    // Clock generation
    always begin
        clock = 1'b0;
        #1 clock = 1'b1;
        #1;
    end

    initial begin
        // Initialize VCD file for gtkwave
        $dumpfile("i2s_waveform.vcd");
        $dumpvars(0, i2s_tb);

        // Initialize signals
        reset = 1'b1;
        data = 16'h0000;
        trigger = 1'b0;

        // Hold reset for 100 ns
        #100;
        reset = 1'b0;
        #20;

        // Send first 16-bit value: 0xAA55
        data = 16'hAA55;
        trigger = 1'b1;
        #20;
        trigger = 1'b0;

        // Wait for transmission to complete (approx. 32 clock cycles + margin)
        //#(256*64 + 500);
        wait (running == 1'b0);
        #200;

        // Send second 16-bit value: 0x5555
        data = 16'h5555;
        trigger = 1'b1;
        #20;
        trigger = 1'b0;

        // Wait for transmission to complete
        wait (running == 1'b0);
        #200;

        // Send third 16-bit value: 0xFFFF
        data = 16'hFFFF;
        trigger = 1'b1;
        #20;
        trigger = 1'b0;

        // Wait for transmission to complete
        wait (running == 1'b0);
        #200;

        // End simulation
        $finish;
    end

endmodule
