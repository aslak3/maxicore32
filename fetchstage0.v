`include "registers.vh"
`include "opcodes.vh"

module fetchstage0
    (
        input reset,
        input clock,

        input block_fetch,
        input [31:0] mem_data,
        output reg [31:0] outbound_instruction
    );

    wire t_opcode opcode = mem_data[31:27];

    always @ (posedge reset, posedge clock) begin
        if (reset) begin
            outbound_instruction <= { OPCODE_NOP, 27'h0 };
        end else begin
            case (opcode)
                OPCODE_HALT: begin
                    $display("STAGE0: HALT");
                    $fatal;
                end
                default: begin
                end
            endcase
            if (block_fetch == 1'b1) begin
                $display("STAGE0: Inserting NOP");
                outbound_instruction <= { OPCODE_NOP, 27'h0 };
            end else begin
                $display("STAGE0: Passing forward %08x", mem_data);
                outbound_instruction <= mem_data;
            end
        end
    end
endmodule
