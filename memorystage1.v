`include "registers.vh"
`include "opcodes.vh"

module memorystage1
    (
        input reset,
        input clock,

        input [31:0] inbound_instruction,
        output reg [31:0] outbound_instruction,
        output reg memory_access_cycle,
        output reg memory_read,
        output reg memory_write,
        output reg [3:0] reg_address_index,
        output reg [3:0] reg_data_index
    );

    wire t_opcode opcode = inbound_instruction[31:27];

    always @ (posedge reset, posedge clock) begin
        if (reset) begin
            memory_access_cycle <= 1'b0;
            outbound_instruction <= { OPCODE_NOP, 27'h0 };
        end else begin
            case (opcode)
                OPCODE_LOAD: begin
                    $display("STAGE1: OPCODE_LOAD - blocking fetch as we need the bus");
                    memory_access_cycle <= 1'b1;
                    memory_read <= 1'b1;
                    memory_write <= 1'b0;
                end
                OPCODE_STORE: begin
                    $display("STAGE1: OPCODE_STORE - blocking fetch as we need the bus");
                    memory_access_cycle <= 1'b1;
                    memory_read <= 1'b0;
                    memory_write <= 1'b1;
                end
                default: begin
                    memory_read <= 1'b0;
                    memory_write <= 1'b0;
                    memory_access_cycle <= 1'b0;
                end
            endcase

            reg_address_index <= inbound_instruction[19:16];
            reg_data_index <= inbound_instruction[23:20];

            $display("STAGE1: Passing forward %08x", inbound_instruction);
            outbound_instruction <= inbound_instruction;
        end
    end
endmodule
