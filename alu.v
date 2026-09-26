`include "alu.vh"
`include "registers.vh"

// This module implements a wide range of arithmetic and logical
// operations defined by the instruction set.  The operations are
// selected by the 5‑bit opcode `op` and the operands are supplied
// in `reg2` and `reg3`.  The result is written to the `result`
// register and several status flags are updated.
//
// The ALU is clock‑synchronous and resets all outputs to zero on
// the active‑high `reset` signal.

module alu
    (
        input reset,
        input clock,
        input [4:0] op,
        input [31:0] reg2, reg3,
        input carry_in,
        output reg [31:0] result,
        output reg carry_out, zero_out, neg_out, over_out
    );

    // Extend operands to 33 bits to capture carry out of 32‑bit ops.
    wire [32:0] temp_reg2 = { 1'b0, reg2 };
    wire [32:0] temp_reg3 = { 1'b0, reg3 };
    // The lower 5 bits of reg3 are used as the shift amount.
    wire [4:0] shift_amount = reg3[4:0];
    // Temporary storage for the 33‑bit result of an operation.
    reg [32:0] temp_result;
    // Temporary storage for 16‑bit multiplication results.
    reg [31:0] temp_mul_result;
    // Flag indicating whether the computed result should be written
    // to the output register.  Some operations (e.g., TEST, COMP)
    // only affect flags and do not write a new value.
    reg give_result;

    always @ (posedge clock) begin
        if (reset) begin
            result <= 32'h0;
            carry_out <= 1'b0;
            zero_out <= 1'b0;
            neg_out <= 1'b0;
            over_out <= 1'b0;
        end else begin
            $display("ALU: op: %02x reg2: %08x reg3: %08x", op, reg2, reg3);
            temp_result = { 1'b0, 32'h0 };
            temp_mul_result = 32'h0;
            give_result = 1'b1;

            case (op)
                // Basic arithmetic
                OP_ADD:                     temp_result = temp_reg2 + temp_reg3;
                OP_ADDC:                    temp_result = temp_reg2 + temp_reg3 + { 32'h0, carry_in };
                OP_SUB:                     temp_result = temp_reg2 - temp_reg3;
                OP_SUBC:                    temp_result = temp_reg2 - temp_reg3 - { 32'h0, carry_in };
                // Logical operations
                OP_AND:                     temp_result = temp_reg2 & temp_reg3;
                OP_OR:                      temp_result = temp_reg2 | temp_reg3;
                OP_XOR:                     temp_result = temp_reg2 ^ temp_reg3;
                // Comparison / test – no result written
                OP_COMP: begin
                    temp_result = temp_reg2 - temp_reg3;
                    give_result = 1'b0;
                end
                OP_BIT: begin
                    temp_result = temp_reg2 & temp_reg3;
                    give_result = 1'b0;
                end
                // Unsigned multiplication of lower 16 bits
                OP_MULU: begin
                    temp_mul_result = temp_reg2[15:0] * temp_reg3[15:0];
                    temp_result = { 1'b0, temp_mul_result };
                end
                // Signed multiplication of lower 16 bits
                OP_MULS: begin
                    temp_mul_result = $signed(temp_reg2[15:0]) * $signed(temp_reg3[15:0]);
                    temp_result = { 1'b0, temp_mul_result };
                end
                // Logical shifts
                OP_LOGIC_LEFT:              temp_result = temp_reg2 << shift_amount;
                OP_LOGIC_RIGHT: begin
                    temp_result[31:0] = reg2 >> shift_amount;
                    temp_result[32] = reg2[shift_amount - 5'b00001];
                end
                // Arithmetic shifts – same shift but overflow handled later
                OP_ARITH_LEFT:              temp_result = temp_reg2 << shift_amount;
                OP_ARITH_RIGHT: begin
                    temp_result[31:0] = $signed(reg2) >>> shift_amount;
                    temp_result[32] = reg2[shift_amount - 5'b00001];
                end
                // Unary operations
                OP_NOT:                     temp_result = ~{ 1'b1, temp_reg2[31:0] };
                OP_NEG:                     temp_result = ~temp_reg2 + { 31'b0, 1'b1 };
                OP_SWAP:                    temp_result = { 1'b0, temp_reg2[15:0], temp_reg2[31:16] };
                OP_TEST: begin
                    temp_result = temp_reg2;
                    give_result = 1'b0;
                end
                // Sign / zero extension
                OP_SIGN_EXT_B:              temp_result = { 1'b0, {24{ temp_reg2[7] }}, temp_reg2[7:0] };
                OP_SIGN_EXT_W:              temp_result = { 1'b0, {16{ temp_reg2[15] }}, temp_reg2[15:0] };
                OP_UNSIGN_EXT_B:            temp_result = { 1'b0, 24'h000000, temp_reg2[7:0] };
                OP_UNSIGN_EXT_W:            temp_result = { 1'b0, 16'h0000, temp_reg2[15:0] };
                OP_COPY:                    temp_result = temp_reg2;
                // Default – no operation
                default:                     temp_result = { 1'b0, 32'h0 };
            endcase

            // Write the computed result to the output register if the
            // operation is one that produces a value.  For operations
            // that only affect status flags (e.g., TEST, COMP) the
            // original operand is written back.
            if (give_result) begin
                result <= temp_result[31:0];
            end else begin
                result <= reg2;
            end

            // Carry out is the 33rd bit of the intermediate result.
            carry_out <= temp_result[32];

            // Zero flag – set if the 32‑bit result is zero.
            if (temp_result[31:0] == 32'h0) begin
                zero_out <= 1'b1;
            end else begin
                zero_out <= 1'b0;
            end

            // Negative flag – sign bit of the result.
            neg_out <= temp_result[31];

            // Overflow detection – set when the sign of the result
            // differs from the expected sign based on the operands.
            if (op == OP_ADD || op == OP_ADDC) begin
                // Add: overflow if operands have same sign and result has opposite sign.
                if (temp_reg3[31] != temp_result[31] && temp_reg2[31] != temp_result[31]) begin
                    over_out <= 1'b1;
                end else begin
                    over_out <= 1'b0;
                end
            end
            // Subtract: overflow if operands have opposite signs and result sign matches the subtrahend.
            else if (op == OP_SUB || op == OP_SUBC) begin
                if (temp_reg3[31] == temp_result[31] && temp_reg2[31] != temp_result[31]) begin
                    over_out <= 1'b1;
                end else begin
                    over_out <= 1'b0;
                end
            end
            // Arithmetic left shift: overflow if sign changes.
            else if (op == OP_ARITH_LEFT) begin
                if (temp_reg2[31] != temp_result[31]) begin
                    over_out <= 1'b1;
                end else begin
                    over_out <= 1'b0;
                end
            end else begin
                over_out <= 1'b0;
            end
        end
    end

endmodule
