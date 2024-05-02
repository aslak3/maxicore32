module maxicore32_tb;
    `include "tests.vh"

    reg reset;
    reg clock;

    reg [1:0] decoder_outputs;
    wire memory_cs = decoder_outputs[1];
    wire display_cs = decoder_outputs[0];
    wire [31:2] address;

    always @ (address[31:24]) begin
        case (address[31:24])
            8'h00: decoder_outputs = { 1'b1, 1'b0 }; 
            8'hff: decoder_outputs = { 1'b0, 1'b1 };
            default: begin
                decoder_outputs = { 1'b0, 1'b0 };
                $display("Something else selected");
            end
        endcase
    end

    wire [31:0] data_out;
    wire [31:0] ram_data_out;
    wire [3:0] data_strobes;
    wire read;
    wire write;

    memory memory (
        .clock(clock),
        .cs(memory_cs),
        .address(address),
        .data_in(data_out),
        .data_out(ram_data_out),
        .data_strobes(data_strobes),
        .read(read),
        .write(write)
    );

    wire dummy_led;
    led led (
        .clock(clock),
        .cs(display_cs),
        .write(write),
        .data_in(data_out),
        .led(dummy_led)
    );

    wire [31:0] data_in;
    wire bus_error;
    wire halted;
    wire [5:0] user;

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
        .halted(halted),
        .user(user)
    );

    wire [31:0] shifted_address = { address, 2'b00 };

    assign data_in = ram_data_out;

    integer dump_counter;

    initial begin
        reset = 1'b1;
        clock = 1'b0;

        #period;

        clock = 1'b1;

        #period;

        clock = 1'b0;

        #period;

        reset = 1'b0;

        forever begin
            clock = 1'b1;
            #period;

            clock = 1'b0;
            #period;

            $display("ADDRESS: %08x DATA_IN: %08x DATA_OUT: %08x DATA_STROBES: %04b READ: %d WRITE: %d",
                shifted_address, data_in, data_out, data_strobes, read, write);

            if (bus_error) begin
                $display("BUS ERROR");
            end
            if (halted) begin
                $display("++++++++HALTED++++++++");
            end
            if (bus_error || halted) begin
                $display("=== MEMORY DUMP ===");
                for (dump_counter = 0; dump_counter < 64; dump_counter++) begin
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
