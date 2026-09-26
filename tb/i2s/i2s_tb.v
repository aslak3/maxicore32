module i2s_tb;
    reg clock;
    reg reset;
    reg [31:0] data;

    wire lrclk;
    wire bclk;
    wire sd;
    wire done;

    // Instantiate the i2s module
    i2s dut (
        .reset(reset),
        .clock(clock),

        .data(data),
        .done(done),

        .lrclk(lrclk),
        .bclk(bclk),
        .sd(sd)
    );

    // Clock generation
    always begin
        clock = 1'b0;
        #1;
        clock = 1'b1;
        #1;
    end

    initial begin
        // Initialize VCD file for gtkwave
        $dumpfile("i2s_tb.vcd");
        $dumpvars(0, i2s_tb);

        // Initialize signals
        reset = 1'b1;
        data  = 32'h0;

        // Hold reset for 100
        #100;
        reset = 1'b0;
        #10;

        data = 32'hdeadbeef;
        wait(done);
        #10;

        data = 32'h55555555;
        wait(done);
        #10;

        data = 32'hffff0000;
        wait(done);
        #10;

        wait(done);
        #10;

        // End simulation
        $finish;
    end
endmodule
