`include "alu.vh"
`include "registers.vh"

module alu_tb;
    `define TB_NO_CLOCK 1
    `include "tests.vh" // For period only
    t_alu_op op;
    t_reg reg2, reg3;
    reg carry_in;
    wire t_reg result;
    wire carry_out, zero_out, neg_out, over_out;

    alu dut (
        .op(op),
        .reg2(reg2), .reg3(reg3),
        .carry_in(carry_in),
        .result(result),
        .carry_out(carry_out), .zero_out(zero_out), .neg_out(neg_out), .over_out(over_out)
    );

    task run_test
        (
            input t_alu_op test_op,
            input t_reg test_reg2, test_reg3,
            input test_carry_in,
            input t_reg exp_result,
            input exp_carry_out, exp_zero_out, exp_neg_out, exp_over_out
        );
        begin
            op = test_op;
            reg2 = test_reg2;
            reg3 = test_reg3;
            carry_in = test_carry_in;

            #period

            $display("Op: %02x Reg2: %08x Reg3: %08x CarryIn: %d", test_op, test_reg2, test_reg3, test_carry_in);
            $display("Result: %08x Carry: %d Zero: %d Neg: %d Over: %d",
                result, carry_out, zero_out, neg_out, over_out);

            if (exp_result != result) begin
                $display("Result got %08x, expected %0832", result, exp_result); $fatal;
            end
            if (exp_carry_out != carry_out) begin
                $display("Carry got %d, expected %d", carry_out, exp_carry_out); $fatal;
            end
            if (exp_zero_out != zero_out) begin
                $display("Zero got %d, expected %d", zero_out, exp_zero_out); $fatal;
            end
            if (exp_neg_out != neg_out) begin
                $display("Neg got %d, expected %d", neg_out, exp_neg_out); $fatal;
            end
            if (exp_over_out != over_out) begin
                $display("Overut got %d, expected %d", over_out, exp_over_out); $fatal;
            end
        end
    endtask

    initial begin
        // One destination, one operand
        run_test(OP_ADD,            32'h00000001, 32'h00000002, 1'b0, 32'h00000003, 1'b0, 1'b0, 1'b0, 1'b0);
        run_test(OP_ADDC,           32'h00000001, 32'h00000002, 1'b0, 32'h00000003, 1'b0, 1'b0, 1'b0, 1'b0);
        run_test(OP_ADDC,           32'h00000001, 32'h00000002, 1'b1, 32'h00000004, 1'b0, 1'b0, 1'b0, 1'b0);
        run_test(OP_ADD,            32'hffffffff, 32'h00000001, 1'b0, 32'h00000000, 1'b1, 1'b1, 1'b0, 1'b0);
        run_test(OP_ADD,            32'h40000000, 32'h40000000, 1'b0, 32'h80000000, 1'b0, 1'b0, 1'b1, 1'b1);
        run_test(OP_ADDC,           32'hffffffff, 32'h00000000, 1'b1, 32'h00000000, 1'b1, 1'b1, 1'b0, 1'b0);
        run_test(OP_ADDC,           32'h80000000, 32'h7fffffff, 1'b0, 32'hffffffff, 1'b0, 1'b0, 1'b1, 1'b0);
        run_test(OP_ADDC,           32'h7ffffffe, 32'h00000001, 1'b1, 32'h80000000, 1'b0, 1'b0, 1'b1, 1'b1);

        run_test(OP_SUB,            32'h00000001, 32'h00000002, 1'b0, 32'hffffffff, 1'b1, 1'b0, 1'b1, 1'b0);
        run_test(OP_SUBC,           32'h00000001, 32'h00000002, 1'b0, 32'hffffffff, 1'b1, 1'b0, 1'b1, 1'b0);
        run_test(OP_SUBC,           32'h00000001, 32'h00000002, 1'b1, 32'hfffffffe, 1'b1, 1'b0, 1'b1, 1'b0);
        run_test(OP_SUB,            32'hffffffff, 32'h00000001, 1'b0, 32'hfffffffe, 1'b0, 1'b0, 1'b1, 1'b0);
        run_test(OP_SUB,            32'h80000000, 32'h00000001, 1'b0, 32'h7fffffff, 1'b0, 1'b0, 1'b0, 1'b1);
        run_test(OP_SUBC,           32'hffffffff, 32'h00000000, 1'b1, 32'hfffffffe, 1'b0, 1'b0, 1'b1, 1'b0);
        run_test(OP_SUBC,           32'hffffffff, 32'hffffffff, 1'b1, 32'hffffffff, 1'b1, 1'b0, 1'b1, 1'b0);
        run_test(OP_SUBC,           32'hffffffff, 32'hffffffff, 1'b0, 32'h00000000, 1'b0, 1'b1, 1'b0, 1'b0);
        run_test(OP_SUBC,           32'h00000000, 32'h80000000, 1'b0, 32'h80000000, 1'b1, 1'b0, 1'b1, 1'b1);
        run_test(OP_SUBC,           32'h00000000, 32'h7fffffff, 1'b0, 32'h80000001, 1'b1, 1'b0, 1'b1, 1'b0);

        run_test(OP_AND,            32'h80808080, 32'hff00ff00, 1'b0, 32'h80008000, 1'b0, 1'b0, 1'b1, 1'b0);
        run_test(OP_AND,            32'h08800880, 32'hff00ff00, 1'b0, 32'h08000800, 1'b0, 1'b0, 1'b0, 1'b0);
        run_test(OP_AND,            32'h80808080, 32'h08080808, 1'b0, 32'h00000000, 1'b0, 1'b1, 1'b0, 1'b0);

        run_test(OP_OR,             32'h80808080, 32'hff00ff00, 1'b0, 32'hff80ff80, 1'b0, 1'b0, 1'b1, 1'b0);
        run_test(OP_OR,             32'h08800880, 32'hff00ff00, 1'b0, 32'hff80ff80, 1'b0, 1'b0, 1'b1, 1'b0);
        run_test(OP_OR,             32'h80808080, 32'h08080808, 1'b0, 32'h88888888, 1'b0, 1'b0, 1'b1, 1'b0);
        run_test(OP_OR,             32'h00000000, 32'h00000000, 1'b0, 32'h00000000, 1'b0, 1'b1, 1'b0, 1'b0);
        run_test(OP_OR,             32'h10001000, 32'h00010001, 1'b0, 32'h10011001, 1'b0, 1'b0, 1'b0, 1'b0);

        run_test(OP_XOR,            32'h80808080, 32'hff00ff00, 1'b0, 32'h7f807f80, 1'b0, 1'b0, 1'b0, 1'b0);
        run_test(OP_XOR,            32'h08800880, 32'hff00ff00, 1'b0, 32'hf780f780, 1'b0, 1'b0, 1'b1, 1'b0);
        run_test(OP_XOR,            32'h80808080, 32'h08080808, 1'b0, 32'h88888888, 1'b0, 1'b0, 1'b1, 1'b0);
        run_test(OP_XOR,            32'h00000000, 32'h00000000, 1'b0, 32'h00000000, 1'b0, 1'b1, 1'b0, 1'b0);
        run_test(OP_XOR,            32'h10001000, 32'h00010001, 1'b0, 32'h10011001, 1'b0, 1'b0, 1'b0, 1'b0);

        run_test(OP_COMP,           32'h00000002, 32'h00000001, 1'b0,  32'h00000002, 1'b0, 1'b0, 1'b0, 1'b0);
        run_test(OP_COMP,           32'h00000001, 32'h00000002, 1'b0,  32'h00000001, 1'b1, 1'b0, 1'b1, 1'b0);
        run_test(OP_COMP,           32'h00000001, 32'h00000001, 1'b0,  32'h00000001, 1'b0, 1'b1, 1'b0, 1'b0);
        run_test(OP_COMP,           32'h80000000, 32'h00000000, 1'b0,  32'h80000000, 1'b0, 1'b0, 1'b1, 1'b0);

        run_test(OP_BIT,            32'hff00ff00, 32'h80808080, 1'b0, 32'hff00ff00, 1'b0, 1'b0, 1'b1, 1'b0);
        run_test(OP_BIT,            32'hff00ff00, 32'h08800880, 1'b0, 32'hff00ff00, 1'b0, 1'b0, 1'b0, 1'b0);
        run_test(OP_BIT,            32'h08080808, 32'h80808080, 1'b0, 32'h08080808, 1'b0, 1'b1, 1'b0, 1'b0);

        run_test(OP_MULU,           32'h00000004, 32'h00001000, 1'b0,  32'h00004000, 1'b0, 1'b0, 1'b0, 1'b0);
        run_test(OP_MULU,           32'h0000ffff, 32'h00000000, 1'b0,  32'h00000000, 1'b0, 1'b1, 1'b0, 1'b0);
        run_test(OP_MULU,           32'h00000000, 32'h00000001, 1'b0,  32'h00000000, 1'b0, 1'b1, 1'b0, 1'b0);
        run_test(OP_MULU,           32'h0000ffff, 32'h0000ffff, 1'b0,  32'hfffe0001, 1'b0, 1'b0, 1'b1, 1'b0);

        run_test(OP_MULS,           32'h0000ffff, 32'h00000001, 1'b0,  32'hffffffff, 1'b0, 1'b0, 1'b1, 1'b0); // -1 * 1 = -1
        run_test(OP_MULS,           32'h0000ffff, 32'h0000ffff, 1'b0,  32'h00000001, 1'b0, 1'b0, 1'b0, 1'b0); // -1 * -1 = 1
        run_test(OP_MULS,           32'h00000001, 32'h00000001, 1'b0,  32'h00000001, 1'b0, 1'b0, 1'b0, 1'b0); // 1 * 1 = 1
        run_test(OP_MULS,           32'h00007fff, 32'h00007fff, 1'b0,  32'h3fff0001, 1'b0, 1'b0, 1'b0, 1'b0);
        run_test(OP_MULS,           32'h00007fff, 32'h00008000, 1'b0,  32'hc0008000, 1'b0, 1'b0, 1'b1, 1'b0);

        // no operand
        run_test(OP_NOT,            32'h80808080, 32'h00000000, 1'b0, 32'h7f7f7f7f, 1'b0, 1'b0, 1'b0, 1'b0);
        run_test(OP_NOT,            32'hffffffff, 32'h00000000, 1'b0, 32'h00000000, 1'b0, 1'b1, 1'b0, 1'b0);
        run_test(OP_NOT,            32'h00000000, 32'h00000000, 1'b0, 32'hffffffff, 1'b0, 1'b0, 1'b1, 1'b0);

        run_test(OP_LOGIC_LEFT,     32'h80808080, 32'h00000000, 1'b0, 32'h01010100, 1'b1, 1'b0, 1'b0, 1'b0);
        run_test(OP_LOGIC_LEFT,     32'hffffffff, 32'h00000000, 1'b0, 32'hfffffffe, 1'b1, 1'b0, 1'b1, 1'b0);
        run_test(OP_LOGIC_LEFT,     32'h00000000, 32'h00000000, 1'b0, 32'h00000000, 1'b0, 1'b1, 1'b0, 1'b0);
        run_test(OP_LOGIC_LEFT,     32'h00000001, 32'h00000000, 1'b0, 32'h00000002, 1'b0, 1'b0, 1'b0, 1'b0);

        run_test(OP_LOGIC_RIGHT,    32'h80808080, 32'h00000000, 1'b0, 32'h40404040, 1'b0, 1'b0, 1'b0, 1'b0);
        run_test(OP_LOGIC_RIGHT,    32'hffffffff, 32'h00000000, 1'b0, 32'h7fffffff, 1'b1, 1'b0, 1'b0, 1'b0);
        run_test(OP_LOGIC_RIGHT,    32'h00000000, 32'h00000000, 1'b0, 32'h00000000, 1'b0, 1'b1, 1'b0, 1'b0);

        run_test(OP_ARITH_LEFT,     32'h80808080, 32'h00000000, 1'b0, 32'h01010100, 1'b1, 1'b0, 1'b0, 1'b1);
        run_test(OP_ARITH_LEFT,     32'hffffffff, 32'h00000000, 1'b0, 32'hfffffffe, 1'b1, 1'b0, 1'b1, 1'b0);
        run_test(OP_ARITH_LEFT,     32'h00000000, 32'h00000000, 1'b0, 32'h00000000, 1'b0, 1'b1, 1'b0, 1'b0);
        run_test(OP_ARITH_LEFT,     32'h00000001, 32'h00000000, 1'b0, 32'h00000002, 1'b0, 1'b0, 1'b0, 1'b0);

        run_test(OP_ARITH_RIGHT,    32'h80808080, 32'h00000000, 1'b0, 32'hc0404040, 1'b0, 1'b0, 1'b1, 1'b0);
        run_test(OP_ARITH_RIGHT,    32'hffffffff, 32'h00000000, 1'b0, 32'hffffffff, 1'b1, 1'b0, 1'b1, 1'b0);
        run_test(OP_ARITH_RIGHT,    32'h00000000, 32'h00000000, 1'b0, 32'h00000000, 1'b0, 1'b1, 1'b0, 1'b0);

        run_test(OP_NEG,            32'h00000001, 32'h00000000, 1'b0,  32'hffffffff, 1'b1, 1'b0, 1'b1, 1'b0);
        run_test(OP_NEG,            32'hffffffff, 32'h00000000, 1'b0,  32'h00000001, 1'b1, 1'b0, 1'b0, 1'b0);
        run_test(OP_NEG,            32'h00000000, 32'h00000000, 1'b0,  32'h00000000, 1'b0, 1'b1, 1'b0, 1'b0);

        run_test(OP_TEST,           32'h00000001, 32'h00000000, 1'b0,  32'h00000001, 1'b0, 1'b0, 1'b0, 1'b0);
        run_test(OP_TEST,           32'hffffffff, 32'h00000000, 1'b0,  32'hffffffff, 1'b0, 1'b0, 1'b1, 1'b0);
        run_test(OP_TEST,           32'h00000000, 32'h00000000, 1'b0,  32'h00000000, 1'b0, 1'b1, 1'b0, 1'b0);
    end
endmodule
