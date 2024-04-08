`ifndef ALU_VH
typedef reg [4:0] t_alu_op;

localparam t_alu_op OP_ADD =                { 1'b0, 4'h0 },
                    OP_ADDC =               { 1'b0, 4'h1 },
                    OP_SUB =                { 1'b0, 4'h2 },
                    OP_SUBC =               { 1'b0, 4'h3 },
                    OP_AND =                { 1'b0, 4'h4 },
                    OP_OR =                 { 1'b0, 4'h5 },
                    OP_XOR =                { 1'b0, 4'h6 },
                    OP_COMP =               { 1'b0, 4'h7 },
                    OP_BIT =                { 1'b0, 4'h8 },
                    OP_MULU =               { 1'b0, 4'h9 },
                    OP_MULS =               { 1'b0, 4'ha },

                    OP_NOT =                { 1'b1, 4'h0 },
                    OP_LOGIC_LEFT =         { 1'b1, 4'h1 },
                    OP_LOGIC_RIGHT =        { 1'b1, 4'h2 },
                    OP_ARITH_LEFT =         { 1'b1, 4'h3 },
                    OP_ARITH_RIGHT =        { 1'b1, 4'h4 },
                    OP_NEG =                { 1'b1, 4'h5 },
                    OP_SWAP =               { 1'b1, 4'h6 },
                    OP_TEST =               { 1'b1, 4'h7 },
                    OP_SIGN_EXT_B =         { 1'b1, 4'h8 },
                    OP_SIGN_EXT_W =         { 1'b1, 4'h9 };

`define ALU_VH 1
`endif
