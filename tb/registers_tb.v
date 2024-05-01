`include "registers.vh"

module register_file_tb;
    `include "tests.vh"

    reg reset;
    reg clock;
    reg [3:0] write_index;
    reg write;
    reg [31:0] write_data;
    reg write_immediate;
    reg [15:0] write_immediate_data;
    reg [1:0] write_immediate_type;
    reg [3:0] read_reg1_index, read_reg2_index, read_reg3_index;
    wire [31:0] read_reg1_data, read_reg2_data, read_reg3_data;

    register_file dut (
        .clock(clock),
        .write_index(write_index),
        .write(write),
        .write_data(write_data),
        .write_immediate(write_immediate),
        .write_immediate_data(write_immediate_data),
        .write_immediate_type(write_immediate_type),
        .read_reg1_index(read_reg1_index),
        .read_reg2_index(read_reg2_index),
        .read_reg3_index(read_reg3_index),
        .read_reg1_data(read_reg1_data),
        .read_reg2_data(read_reg2_data),
        .read_reg3_data(read_reg3_data)
    );

    initial begin
        clock = 1'b0;
        write_index = 4'h0;
        write = 1'b0;
        write_data = 32'h0;
        write_immediate = 1'b0;
        write_immediate_data = 16'h0;
        write_immediate_type = IT_BOTTOM;
        read_reg1_index = 4'h0;
        read_reg2_index = 4'h1;
        read_reg3_index = 4'h2;
        #period;

        #period;

        write = 1'b1;
        write_index = 4'h2;
        write_data = 32'hdeadbeef;

        pulse_clock;

        `assert(read_reg1_data == 32'h0, "Reg write (r2) and r0 still 0");
        `assert(read_reg2_data == 32'h0, "Reg write (r2) and r1 still 0");
        `assert(read_reg3_data == 32'hdeadbeef, "Reg write (r2) r2 now deadbeef");

        write = 1'b0;
        write_immediate = 1'b1;
        write_immediate_data = 16'hdead;

        pulse_clock;

        `assert(read_reg3_data == 32'hdeaddead, "Reg write_immediate BOTTOM (r2) r2 now deaddead");

        write_immediate_type = IT_TOP;
        write_immediate_data = 16'hbeef;

        pulse_clock;

        `assert(read_reg3_data == 32'hbeefdead, "Reg write_immediate TOP (r2) r2 now beefdead");

        write_immediate_type = IT_UNSIGNED;
        write_immediate_data = 16'h1234;

        pulse_clock;

        `assert(read_reg3_data == 32'h00001234, "Reg write_immediate UNSIGNED (r2) r2 now 00001234");

        write_immediate_type = IT_SIGNED;
        write_immediate_data = 16'hffff;

        pulse_clock;

        `assert(read_reg3_data == 32'hffffffff, "Reg write_immediate SIGNED (r2) r2 now ffffffff")
    end
endmodule

module program_counter_tb;
    `include "tests.vh"

    reg reset;
    reg clock;
    reg jump, inc, branch;
    reg [31:0] jump_data;
    reg [15:0] branch_data;
    reg [31:0] read_data;

    program_counter dut (
        .reset(reset),
        .clock(clock),
        .jump(jump), .inc(inc),
        .jump_data(jump_data),
        .read_data(read_data)
    );

    initial begin
        reset = 0;
        clock = 0;
        jump = 0;
        inc = 0;
        jump_data = 32'h0;
        #period;

        reset = 1;
        #period;

        `assert(read_data == 32'h0, "PC resets");

        reset = 0;
        #period;

        inc = 1;
        pulse_clock;

        `assert(read_data == 32'h4, "PC Inc by 4");

        inc = 0;
        jump = 1;
        jump_data = 32'hdeadbeef;
        pulse_clock;

        `assert(read_data == 32'hdeadbeef, "PC jump");
    end

endmodule
