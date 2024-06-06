// General purpose preprocessor stuff for testbenches.

`define assert(test, message) \
    if (!(test)) begin \
        $display("ASSERTION FAILED in %m: test (%s)", message); \
        $fatal; \
    end else begin \
        $display("ASSERTION PASS in %m: test (%s)", message); \
    end

localparam test_period = 1;

`ifndef TB_NO_CLOCK
task pulse_clock;
    begin
        clock = 1;
        #test_period;

        clock = 0;
        #test_period;
    end
endtask
`endif
