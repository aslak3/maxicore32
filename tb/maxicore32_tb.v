module maxicore32_tb;
    `include "tests.vh"

    reg reset;
    reg clock;

    wire [31:2] address;
    wire [31:0] ram_data_in;
    wire [31:0] ram_data_out;
    wire [3:0] data_strobes;
    wire read;
    wire write;

    memory memory (
        .clock(clock),
        .address(address),
        .data_in(ram_data_in),
        .data_out(ram_data_out),
        .data_strobes(data_strobes),
        .read(read),
        .write(write)
    );

    wire [31:0] data_in;
    wire [31:0] data_out;
    wire bus_error;
    wire halted;

    maxicore32 dut (
        .reset(reset),
        .clock(clock),

        .address(address),
        .data_in(data_in),
        .data_out(data_out),
        .data_strobes(data_strobes),
        .read(read),
        .write(write),
        .bus_error(bus_error),
        .halted(halted)
    );

    assign data_in = ram_data_out;
    assign ram_data_in = data_out;

    integer dump_counter;

    initial begin
        reset = 1'b1;
        clock = 1'b1;

        #period;

        reset = 1'b0;
        #period;

        forever begin
            clock = 1'b0;
            #period;

            clock = 1'b1;
            #period;

            $display("ADDRESS: %08x DATA_IN: %08x DATA_OUT: %08x DATA_STROBES: %04b READ: %d WRITE: %d",
                address << 2, data_in, data_out, data_strobes, read, write);

            if (bus_error == 1'b1) begin
                $display("BUS ERROR");
                $fatal;
            end
            if (halted == 1'b1) begin
                $display("HALTED");
                for (dump_counter = 0; dump_counter < 32; dump_counter++) begin
                    $display("%d = %08x", dump_counter * 4, memory.contents[dump_counter]);
                end
                $fatal;
            end
        end
    end
endmodule
