`define assert(test, message) \
    if (!(test)) begin \
        $display("ASSERTION FAILED in %m: test (%s)", message); \
        $fatal; \
    end else begin \
        $display("ASSERTION PASS in %m: test (%s)", message); \
    end

localparam period = 1;

task pulse_clock;
    begin
        clock = 1;
        #period;

        clock = 0;
        #period;
    end
endtask