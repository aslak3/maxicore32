module maxicore32_tb;
    `include "tests.vh"

    reg reset;
    reg clock;

    wire [31:2] address;
    reg[31:0] data_in;
    wire [31:0] data_out;
    wire [3:0] data_strobes;
    wire read;
    wire write;
    wire bus_error;

    maxicore32 dut (
        .reset(reset),
        .clock(clock),

        .address(address),
        .data_in(data_in),
        .data_out(data_out),
        .data_strobes(data_strobes),
        .read(read),
        .write(write),
        .bus_error(bus_error)
    );

    initial begin
        reset = 1'b0;
        clock = 1'b0;

        data_in = 32'h0;

        #period;

        reset = 1'b1;
        #period;

        reset = 1'b0;
        #period;

        forever begin
            clock = 1'b1;
            #period;

            clock = 1'b0;
            #period;

            $display("ADDRESS: %08x DATA_IN: %08x DATA_OUT: %08x DATA_STROBES: %04b",
                address << 2, data_in, data_out, data_strobes);

            if (bus_error == 1'b1) begin
                $display("BUS ERROR");
                $fatal;
            end
        end
    end
endmodule