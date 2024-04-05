`include "registers.vh"
`include "opcodes.vh"

module memorystage1
    (
        input reset,
        input clock,

        input [31:0] inbound_instruction,
        output reg [31:0] outbound_instruction,
        output reg block_fetch
    );

    wire t_opcode opcode = inbound_instruction[31:27];

    always @ (posedge reset, posedge clock) begin
        if (reset) begin
            block_fetch <= 1'b0;
            outbound_instruction <= { OPCODE_NOP, 27'h0 };
        end else begin
            case (opcode)
                OPCODE_LOAD: begin
                    $display("STAGE1: OPCODE_LOAD - blocking fetch as we need the bus");
                    block_fetch <= 1'b1;
                end
                OPCODE_STORE: begin
                    block_fetch <= 1'b1;
                end
                default: begin
                    block_fetch <= 1'b0;
                end
            endcase

            $display("STAGE1: Passing forward %08x", inbound_instruction);
            outbound_instruction <= inbound_instruction;
        end
    end
endmodule
