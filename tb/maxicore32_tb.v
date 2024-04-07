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

            if (bus_error) begin
                $display("BUS ERROR");
            end
            if (halted) begin
                $display("++++++++HALTED++++++++");
            end
            if (bus_error || halted) begin
                $display("=== MEMORY DUMP ===");
                for (dump_counter = 0; dump_counter < 32; dump_counter++) begin
                    $display("%0d =\t%08x", dump_counter * 4, memory.contents[dump_counter]);
                end
                $display("=== REGISTERS ===");
                $display("PC =\t%08x", dut.program_counter.program_counter);
                for (dump_counter = 0; dump_counter < 16; dump_counter += 4) begin
                    $display("r%0d =\t%08x\tr%0d =\t%08x\tr%0d =\t%08x\tr%0d =\t%08x",
                        dump_counter + 0, dut.register_file.register_file[dump_counter + 0],
                        dump_counter + 1, dut.register_file.register_file[dump_counter + 1],
                        dump_counter + 2, dut.register_file.register_file[dump_counter + 2],
                        dump_counter + 3, dut.register_file.register_file[dump_counter + 3]
                    );
                end
                $display("=== ERROR OUTPUTS ===");
                $display("Bus Error = %01b\tHalted = %01b", bus_error, halted);
                $fatal;
            end
        end
    end
endmodule
