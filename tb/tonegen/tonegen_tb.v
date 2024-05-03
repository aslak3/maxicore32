module tonegen_tb;
    `include "tests.vh"

    reg reset;
    reg clock;
    reg write;
    reg duration_cs;
    reg period_cs;
    reg [31:0] data_in;
    wire sounder;

    tonegen dut (
        .reset(reset),
        .clock(clock),
        .write(write),
        .duration_cs(duration_cs),
        .period_cs(period_cs),
        .data_in(data_in),
        .sounder(sounder)
    );

    integer i;

    initial begin
        $dumpfile("tonegen.vcd");
        $dumpvars;

        reset = 1'b0;
        clock = 1'b0;
        write = 1'b0;
        duration_cs = 1'b0;
        period_cs = 1'b0;
        data_in = 32'h0;

        #period;

        reset = 1'b1;

        pulse_clock;

        reset = 1'b0;

        pulse_clock;

        data_in = 32'h04;
        period_cs = 1'b1;
        write = 1'b1;

        pulse_clock;

        period_cs = 1'b0;
        write = 1'b0;

        pulse_clock;

        data_in = 32'h40;
        duration_cs = 1'b1;
        write = 1'b1;

        pulse_clock;

        duration_cs = 1'b0;
        write = 1'b0;

        pulse_clock;

        for (i = 0; i < 100; i++) begin
            pulse_clock;
        end
    end
endmodule
