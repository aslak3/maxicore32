`include "registers.vh"

module register_file_tb;
    `include "tests.vh"

    reg reset;
    reg clock;
    reg read_reg1, read_reg2, read_reg3;
    reg [3:0] read_reg1_index, read_reg2_index, read_reg3_index;
    wire read_reg1_valid, read_reg2_valid, read_reg3_valid;
    wire [31:0] read_reg1_data, read_reg2_data, read_reg3_data;
    reg [3:0] write_index;
    reg write;
    reg [31:0] write_data;
    reg write_immediate;
    reg [15:0] write_immediate_data;
    reg [1:0] write_immediate_type;

    register_file dut (
        .clock(clock),
        .write_index(write_index),
        .read_reg1(read_reg1),
        .read_reg2(read_reg2),
        .read_reg3(read_reg3),
        .read_reg1_index(read_reg1_index),
        .read_reg2_index(read_reg2_index),
        .read_reg3_index(read_reg3_index),
        .read_reg1_valid(read_reg1_valid),
        .read_reg2_valid(read_reg2_valid),
        .read_reg3_valid(read_reg3_valid),
        .read_reg1_data(read_reg1_data),
        .read_reg2_data(read_reg2_data),
        .read_reg3_data(read_reg3_data),
        .write(write),
        .write_data(write_data),
        .write_immediate(write_immediate),
        .write_immediate_data(write_immediate_data),
        .write_immediate_type(write_immediate_type)
    );

    initial begin
        clock = 1'b0;
        read_reg1 = 1'b0;
        read_reg2 = 1'b0;
        read_reg2 = 1'b0;
        read_reg1_index = 4'h0;
        read_reg2_index = 4'h1;
        read_reg3_index = 4'h2;
        write_index = 4'h0;
        write = 1'b0;
        write_data = 32'h0;
        write_immediate = 1'b0;
        write_immediate_data = 16'h0;
        write_immediate_type = IT_BOTTOM;
        
        #test_period;

        write = 1'b1;
        write_index = 4'h2;
        write_data = 32'hdeadbeef;

        pulse_clock;

        `assert(read_reg1_valid == 1'b0, "Reg write (r2) reg1 invalid");
        `assert(read_reg2_valid == 1'b0, "Reg write (r2) reg2 invalid");
        `assert(read_reg3_valid == 1'b0, "Reg write (r2) reg3 invalid");

        read_reg3 = 1'b1;
        read_reg3_index = 4'h2;

        pulse_clock;

        `assert(read_reg1_valid == 1'b0, "Reg write (r2) reg1 invalid");
        `assert(read_reg2_valid == 1'b0, "Reg write (r2) reg2 invalid");
        `assert(read_reg3_valid == 1'b1, "Reg write (r2) reg3 data now valid");
        `assert(read_reg3_data == 32'hdeadbeef, "Reg write (r2) reg2 now deadbeef");

        read_reg3 = 1'b0;

        pulse_clock;

        `assert(read_reg1_valid == 1'b0, "Reg write (r2) reg1 invalid");
        `assert(read_reg2_valid == 1'b0, "Reg write (r2) reg2 invalid");
        `assert(read_reg3_valid == 1'b0, "Reg write (r2) reg3 invalid again");

        write = 1'b0;
        write_immediate = 1'b1;
        write_immediate_data = 16'hdead;

        pulse_clock;
        
        read_reg3 = 1'b1;

        pulse_clock;

        `assert(read_reg3_valid == 1'b1, "Reg write (r2) reg3 data now valid");
        `assert(read_reg3_data == 32'hdeaddead, "Reg write_immediate BOTTOM (r2) r2 now deaddead");

        write_immediate_type = IT_TOP;
        write_immediate_data = 16'hbeef;

        pulse_clock;

        write_immediate = 1'b0;

        pulse_clock;

        `assert(read_reg3_valid == 1'b1, "Reg write (r2) reg3 data still valid");
        `assert(read_reg3_data == 32'hbeefdead, "Reg write_immediate TOP (r2) r2 now beefdead");

        write_immediate = 1'b1;
        write_immediate_type = IT_UNSIGNED;
        write_immediate_data = 16'h1234;

        pulse_clock;

        write_immediate = 1'b0;

        pulse_clock;

        `assert(read_reg3_valid == 1'b1, "Reg write (r2) reg3 data still valid");
        `assert(read_reg3_data == 32'h00001234, "Reg write_immediate UNSIGNED (r2) r2 now 00001234");

        write_immediate = 1'b1;
        write_immediate_type = IT_SIGNED;
        write_immediate_data = 16'hffff;

        pulse_clock;

        write_immediate = 1'b0;

        pulse_clock;

        `assert(read_reg3_valid == 1'b1, "Reg write (r2) reg3 data still valid");
        `assert(read_reg3_data == 32'hffffffff, "Reg write_immediate SIGNED (r2) r2 now ffffffff")
    end
endmodule


module program_counter_tb;
    `include "tests.vh"

    reg reset;
    reg clock;
    reg read;
    wire read_data_valid;
    wire [31:0] read_data;
    reg jump, inc, branch;
    reg [31:0] jump_data;
    reg [15:0] branch_data;

    program_counter dut (
        .reset(reset),
        .clock(clock),
        .read(read),
        .read_data_valid(read_data_valid),
        .read_data(read_data),
        .jump(jump), .inc(inc),
        .jump_data(jump_data)
    );

    initial begin
        reset = 1'b0;
        clock = 1'b0;
        read = 1'b0;
        jump = 1'b0;
        inc = 1'b0;
        jump_data = 32'h0;

        #test_period;

        reset = 1'b1;

        pulse_clock;

        reset = 1'b0;

        pulse_clock;

        `assert(read_data_valid == 1'b0, "Read data not valid");

        read = 1'b1;

        pulse_clock;

        reset = 1'b0;

        `assert(read_data_valid == 1'b1, "Read data now valid");
        `assert(read_data == 32'h0, "PC resets");

        pulse_clock;

        read = 1'b0;

        pulse_clock;

        `assert(read_data_valid == 1'b0, "Read data now not valid");

        inc = 1;

        pulse_clock;

        read = 1'b1;

        pulse_clock;

        `assert(read_data_valid == 1'b1, "Read data now valid");
        `assert(read_data == 32'h4, "PC Inc by 4");

        read = 1'b0;
        inc = 1'b0;
        jump = 1'b1;
        jump_data = 32'hdeadbeef;

        pulse_clock;

        read = 1'b1;
        jump = 1'b0;

        pulse_clock;

        `assert(read_data == 32'hdeadbeef, "PC jump");
    end

endmodule
