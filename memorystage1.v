`include "registers.vh"
`include "opcodes.vh"
`include "businterface.vh"
`include "alu.vh"

module memorystage1
    (
        input reset,
        input clock,

        input [31:0] inbound_instruction,
        output reg [31:0] outbound_instruction,
        output reg memory_access_cycle,
        output reg memory_read,
        output reg memory_write,
        output t_cycle_width memory_cycle_width,
        output reg [15:0] alu_immediate,
        output reg [3:0] reg_address_index,
        output reg [3:0] reg_data_index,
        output reg [3:0] reg_operand_index,
        output t_alu_op alu_op,
        output reg alu_immediate_cycle,
        output reg branch_cycle,
        output reg jump_cycle
    );

    wire t_opcode opcode = inbound_instruction[31:27];

    always @ (posedge reset, posedge clock) begin
        if (reset) begin
            memory_access_cycle <= 1'b0;
            outbound_instruction <= { OPCODE_NOP, 27'h0 };
            alu_immediate_cycle <= 1'b0;
        end else begin
            memory_access_cycle <= 1'b0;
            alu_immediate_cycle <= 1'b0;
            branch_cycle <= 1'b0;
            jump_cycle <= 1'b0;

            case (opcode)
                OPCODE_LOAD: begin
                    $display("STAGE1: OPCODE_LOAD - blocking fetch as we need the bus");
                    memory_access_cycle <= 1'b1;
                    memory_read <= 1'b1;
                    memory_write <= 1'b0;
                    alu_op <= { OP_ADD };
                    alu_immediate <= inbound_instruction[15:0];
                    alu_immediate_cycle <= 1'b1;
                end
                OPCODE_STORE: begin
                    $display("STAGE1: OPCODE_STORE - blocking fetch as we need the bus");
                    memory_access_cycle <= 1'b1;
                    memory_read <= 1'b0;
                    memory_write <= 1'b1;
                    alu_op <= { OP_ADD };
                    alu_immediate <= inbound_instruction[15:0];
                    alu_immediate_cycle <= 1'b1;
                end
                OPCODE_ALUM: begin
                    $display("STAGE1: OPCODE_ALUM");
                    alu_op <= { 1'b0, inbound_instruction[15:12] };
                    alu_immediate_cycle <= 1'b0;
                end
                OPCODE_ALUMI: begin
                    $display("STAGE1: OPCODE_ALUMI");
                    alu_op <= { 1'b0, inbound_instruction[15:12] };
                    alu_immediate <= { inbound_instruction[26],
                        inbound_instruction[26:24], inbound_instruction[11:0] };
                    alu_immediate_cycle <= 1'b1;
                end
                OPCODE_ALU: begin
                    $display("STAGE1: OPCODE_ALU");
                    alu_op <= { 1'b1, inbound_instruction[15:12] };
                    alu_immediate_cycle <= 1'b0;
                end
                OPCODE_BRANCH: begin
                    $display("STAGE1: OPCODE_BRANCH");
                    alu_op <= { OP_ADD };
                    alu_immediate <= {
                        inbound_instruction[19:16], inbound_instruction[11:0] };
                    alu_immediate_cycle <= 1'b1;
                    branch_cycle <= 1'b1;
                end
                OPCODE_JUMP: begin
                    $display("STAGE1: OPCODE_JUMP");
                    jump_cycle <= 1'b1;
                end
                default: begin
                    memory_read <= 1'b0;
                    memory_write <= 1'b0;
                end
            endcase

            memory_cycle_width <= inbound_instruction[26:25];

            reg_address_index <= inbound_instruction[19:16];
            reg_data_index <= inbound_instruction[23:20];
            reg_operand_index <= inbound_instruction[11:8];

            $display("STAGE1: Passing forward %08x", inbound_instruction);
            outbound_instruction <= inbound_instruction;
        end
    end
endmodule
