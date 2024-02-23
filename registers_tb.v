module register_file_tb;
    `include "tests.vh"

    reg reset;
    reg clock;
    reg clear, write, inc, dec;
    t_reg_index write_index, incdec_index;
    t_reg write_data;
    t_reg_index read_reg1_index, read_reg2_index, read_reg3_index;
    t_reg read_reg1_data, read_reg2_data, read_reg3_data;

    register_file dut (
        .reset(reset),
        .clock(clock),
        .clear(clear), .write(write), .inc(inc), .dec(dec),
        .write_index(write_index),
        .incdec_index(incdec_index),
        .write_data(write_data),
        .read_reg1_index(read_reg1_index),
        .read_reg2_index(read_reg2_index),
        .read_reg3_index(read_reg3_index),
        .read_reg1_data(read_reg1_data),
        .read_reg2_data(read_reg2_data),
        .read_reg3_data(read_reg3_data)
    );

    initial begin
        reset = 0;
        clock = 0;
        write = 0;
        clear = 0;
        inc = 0;
        dec = 0;
        write_index = 4'h0;
        incdec_index = 4'h0;
        write_data = 32'h0;
        read_reg1_index = 4'h0;
        read_reg2_index = 4'h1;
        read_reg3_index = 4'h2;
        #period;

        reset = 1;
        #period;

        `assert(read_reg1_data == 32'h0, "Reg r0 resets");
        `assert(read_reg2_data == 32'h0, "Reg r1 resets");
        `assert(read_reg3_data == 32'h0, "Reg r2 resets");

        reset = 0;
        #period;

        inc = 1;
        incdec_index = 4'h1;
    
        pulse_clock;

        `assert(read_reg1_data == 32'h0, "Reg inc by 4 (r1) r0 still 0");
        `assert(read_reg2_data == 32'h4, "Reg inc by 4 (r1) r1 now 4");
        `assert(read_reg3_data == 32'h0, "Reg inc by 4 (r1) r2 still 0");

        write = 1;
        write_index = 4'h2;
        write_data = 32'hdeadbeef;

        pulse_clock;

        `assert(read_reg1_data == 32'h0, "Reg write (r2) and Inc by 4 (r1) r0 still 0");
        `assert(read_reg2_data == 32'h8, "Reg write (r2) and Inc by 4 (r1) r1 now 8");
        `assert(read_reg3_data == 32'hdeadbeef, "Reg write (r2) and Inc by 4 (r1) r2 now deadbeef");

        write = 0;
        clear = 1;

        pulse_clock;

        `assert(read_reg1_data == 32'h0, "Reg clear (r2) and Inc by 4 (r1) r0 still 0");
        `assert(read_reg2_data == 32'hc, "Reg clear (r2) and Inc by 4 (r1) r1 now c");
        `assert(read_reg3_data == 32'h0, "Reg clear (r2) and Inc by 4 (r1) r2 now 0");

        clear = 0;
        inc = 0;
        dec = 1;

        pulse_clock;

        `assert(read_reg1_data == 32'h0, "Reg dec by 4 (r1) r0 still 0");
        `assert(read_reg2_data == 32'h8, "Reg dec by 4 (r1) r1 now 8");
        `assert(read_reg3_data == 32'h0, "Reg dec by 4 (r1) r2 still 0");
    end
endmodule

module program_counter_tb;
    `include "tests.vh"

    reg reset;
    reg clock;
    reg write, inc;
    t_reg write_data;
    t_reg read_data;

    program_counter dut (
        .reset(reset),
        .clock(clock),
        .write(write), .inc(inc),
        .write_data(write_data),
        .read_data(read_data)
    );

    initial begin
        reset = 0;
        clock = 0;
        write = 0;
        inc = 0;
        write_data = 32'h0;
        #period;

        reset = 1;
        #period;

        `assert(read_data == 32'h0, "PC resets");

        reset = 0;
        #period;

        inc = 1;
        pulse_clock;

        `assert(read_data == 32'h4, "PC Inc by 4");

        write = 1;
        write_data = 32'hdeadbeef;
        pulse_clock;

        `assert(read_data == 32'hdeadbeef, "PC write");
    end

endmodule
