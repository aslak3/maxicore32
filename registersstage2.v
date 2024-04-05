`include "registers.vh"
`include "opcodes.vh"

module registersstage2
    (
        input reset,
        input clock,

        input [31:0] inbound_instruction,
        output reg [31:0] outbound_instruction
    );

    wire t_opcode opcode = inbound_instruction[31:27];

    always @ (posedge reset, posedge clock) begin
        if (reset) begin
            outbound_instruction <= { OPCODE_NOP, 27'h0 };
        end else begin
            case (opcode)
                OPCODE_LOADI: begin
                    $display("STAGE2: OPCODE_LOADI - Immediate load");
                end
                default: begin
                end
            endcase

            $display("STAGE2: Passing forward %08x", inbound_instruction);
            outbound_instruction <= inbound_instruction;
        end
    end
endmodule
