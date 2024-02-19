`define assert(test, message) \
        if (!(test)) begin \
            $display("ASSERTION FAILED in %m: test (%s)", message); \
            $finish; \
        end else begin \
            $display("ASSERTION PASS in %m: test (%s)", message); \
        end

module tb;
    reg reset;
    reg clock;
    reg clear, write, inc, dec;
    t_reg_index write_index, incdec_index;
    t_reg write_data;
    t_reg_index read_reg1_index, read_reg2_index, read_reg3_index;
    t_reg reg1_data, reg2_data, reg3_data;

    localparam period = 1;

    registers dut (
        .reset(reset),
        .clock(clock),
        .clear(clear), .write(write), .inc(inc), .dec(dec),
        .write_index(write_index),
        .incdec_index(incdec_index),
        .write_data(write_data),
        .read_reg1_index(read_reg1_index),
        .read_reg2_index(read_reg2_index),
        .read_reg3_index(read_reg3_index),
        .reg1_data(reg1_data),
        .reg2_data(reg2_data),
        .reg3_data(reg3_data)
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

        `assert(reg1_data == 32'h0, "r0 resets");
        `assert(reg2_data == 32'h0, "r1 resets");
        `assert(reg3_data == 32'h0, "r2 resets");

        reset = 0;
        #period;

        inc = 1;
        incdec_index = 4'h1;
        clock = 1;
        #period;

        clock = 0;
        #period;

        `assert(reg1_data == 32'h0, "Inc by 4 (r1) r0 still 0");
        `assert(reg2_data == 32'h4, "Inc by 4 (r1) r1 now 4");
        `assert(reg3_data == 32'h0, "Inc by 4 (r1) r2 still 0");

        write = 1;
        write_index = 4'h2;
        write_data = 32'hdeadbeef;

        clock = 1;
        #period;

        clock = 0;
        #period;

        `assert(reg1_data == 32'h0, "Write (r2) and Inc by 4 (r1) r0 still 0");
        `assert(reg2_data == 32'h8, "Write (r2) and Inc by 4 (r1) r1 now 8");
        `assert(reg3_data == 32'hdeadbeef, "Write (r2) and Inc by 4 (r1) r2 now deadbeef");

        write = 0;
        clear = 1;

        clock = 1;
        #period;

        clock = 0;
        #period;

        `assert(reg1_data == 32'h0, "Clear (r2) and Inc by 4 (r1) r0 still 0");
        `assert(reg2_data == 32'hc, "Clear (r2) and Inc by 4 (r1) r1 now c");
        `assert(reg3_data == 32'h0, "Clear (r2) and Inc by 4 (r1) r2 now 0");

        clear = 0;
        inc = 0;
        dec = 1;

        clock = 1;
        #period;

        clock = 0;
        #period;

        `assert(reg1_data == 32'h0, "Dec by 4 (r1) r0 still 0");
        `assert(reg2_data == 32'h8, "Dec by 4 (r1) r1 now 8");
        `assert(reg3_data == 32'h0, "Dec by 4 (r1) r2 still 0");
    end
endmodule