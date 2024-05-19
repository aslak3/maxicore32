module tonegen_tb;
    `include "tests.vh"

    reg reset;
    reg clock;
    reg write;
    reg [31:0] duration;
    reg [31:0] period;
    reg tone_start;
    wire buzzer;
    wire playing;

    tonegen tonegen (
        .reset(reset),
        .clock(clock),
        .duration(duration),
        .period(period),
        .tone_start(tone_start),
        .buzzer(buzzer),
        .playing(playing)
    );

    integer i;

    initial begin
        $dumpfile("tonegen.vcd");
        $dumpvars;

        reset = 1'b0;
        clock = 1'b0;
        duration = 32'h0;
        period = 32'h0;
        tone_start = 1'b0;

        #test_period;

        reset = 1'b1;

        pulse_clock;

        reset = 1'b0;

        pulse_clock;

        period = 32'h04;
        duration = 32'h40;
        tone_start = 1'b1;

        pulse_clock;

        tone_start = 1'b0;

        pulse_clock;

        for (i = 0; i < 100; i++) begin
            pulse_clock;
        end
    end
endmodule
