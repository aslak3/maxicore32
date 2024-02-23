`include "alu.vh"
`include "registers.vh"

module alu
    (
        input t_alu_op op,
        input t_reg reg2, reg3,
        input carry_in,
        output t_reg result,
        output reg carry_out,
        output reg zero_out,
        output reg neg_out,
        output reg over_out
    );

    parameter [4:0] ADD =           { 1'b0, 4'h0 },
                    ADDC =          { 1'b0, 4'h1 },
                    SUB =           { 1'b0, 4'h2 },
                    SUBC =          { 1'b0, 4'h3 },
                    AND =           { 1'b0, 4'h4 },
                    OR =            { 1'b0, 4'h5 },
                    XOR =           { 1'b0, 4'h6 },
                    COMP =          { 1'b0, 4'h7 },
                    BIT =           { 1'b0, 4'h8 },
                    MULU =          { 1'b0, 4'h9 },
                    MULS =          { 1'b0, 4'ha },

                    INC =           { 1'b1, 4'h0 },
                    DEC =           { 1'b1, 4'h1 },
                    NOT =           { 1'b1, 4'h2 },
                    LOGIC_LEFT =    { 1'b1, 4'h3 },
                    LOGIC_RIGHT =   { 1'b1, 4'h4 },
                    ARITH_LEFT =    { 1'b1, 4'h5 },
                    ARITH_RIGHT =   { 1'b1, 4'h6 },
                    NEG =           { 1'b1, 4'h7 },
                    SWAP =          { 1'b1, 4'h8 },
                    TEST =          { 1'b1, 4'h9 },
                    SIGN_EXT_B =    { 1'b1, 4'ha },
                    SIGN_EXT_W =    { 1'b1, 4'hb };

    reg [32:0] temp_reg2;
    reg [32:0] temp_reg3;
    reg [32:0] temp_result;
    reg give_result;

    always @ (op, reg2, reg3, carry_in) begin
        temp_reg2 = { 1'b0, reg2 };
        temp_reg3 = { 1'b0, reg3 };
        temp_result = { 1'b0, 32'h0 };
        give_result = 1'b1;

        case (op)
            ADD:
                temp_result = temp_reg2 + temp_reg3;
            ADDC:
                temp_result = temp_reg2 + temp_reg3 + { 32'h0, carry_in };
            SUB:
                temp_result = temp_reg2 - temp_reg3;
            SUBC:
                temp_result = temp_reg2 - temp_reg3 - { 32'h0, carry_in };
            AND:
                temp_result = temp_reg2 & temp_reg3;
            OR:
                temp_result = temp_reg2 | temp_reg3;
            XOR:
                temp_result = temp_reg2 ^ temp_reg3;
            COMP: begin
                temp_result = temp_reg2 - temp_reg3;
                give_result = 1'b0;
            end
            BIT: begin
                temp_result = temp_reg2 & temp_reg3;
                give_result = 1'b0;
            end
            MULU:
                temp_result = temp_reg2[15:0] * temp_reg3[15:0];
            MULS:
                temp_result = $signed(temp_reg2[15:0]) * $signed(temp_reg3[15:0]);

            INC:
                temp_result = temp_reg2 + 1;
            DEC:
                temp_result = temp_reg2 - 1;
            NOT:
                temp_result = ~temp_reg2;
            LOGIC_LEFT:
                temp_result = temp_reg2 << 1;
            LOGIC_RIGHT:
                temp_result = { temp_reg2[0], 1'b0, temp_reg2[31:1] };
            ARITH_LEFT:
                temp_result = { temp_reg2[31:0], 1'b0 };
            ARITH_RIGHT:
                temp_result = { temp_reg2[0], temp_reg2[31], temp_reg2[31:1] };
            NEG:
                temp_result = ~temp_reg2 + { 31'b0, 1'b1 };
            SWAP:
                temp_result = { 1'b0, temp_reg2[15:0], temp_reg2[31:16] };
            SIGN_EXT_B:
                temp_result = { 1'b0, {24{ temp_reg2[7] }}, temp_reg2[7:0] };
            SIGN_EXT_W:
                temp_result = { 1'b0, {16{ temp_reg2[15] }}, temp_reg2[15:0] };

            default:
                temp_result = { 1'b0, 32'h0 };
        endcase

        if (give_result) begin
            result = temp_result[31:0];
        end else begin
            result = reg2;
        end

        carry_out = temp_result[32];

        if (temp_result[31:0] == 32'h0) begin
            zero_out = 1'b1;
        end else begin
            zero_out = 1'b0;
        end

        neg_out = temp_result[31];

	    // When adding then if sign of result is different to the sign of both the
		// operands then it is an overflow condition
        if (op == ADD || op == ADDC) begin
        	if (temp_reg3[31] != temp_result[31] && temp_reg2 [31] != temp_result[31]) begin
				over_out = 1'b1;
            end else begin
				over_out = 1'b0;
            end
        end 
        // Likewise for sub, but invert the reg3 sign for test as its a subtract
		else if (op == SUB || op == SUBC) begin
			if (temp_reg3[31] == temp_result[31] && temp_reg2[31] != temp_result[31]) begin
				over_out = 1'b1;
            end else begin
				over_out = 1'b0;
			end
        end
		// For arith shift reg3, if the sign changed then it is an overflow
		else if (op == ARITH_LEFT) begin
			if (temp_reg2[31] != temp_result[31]) begin
				over_out = 1'b1;
            end else begin
				over_out = 1'b0;
            end
        end else begin
			over_out = 1'b0;
        end
    end

endmodule
