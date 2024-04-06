`include "registers.vh"
`include "opcodes.vh"

module registersstage2
    (
        input reset,
        input clock,

        input [31:0] inbound_instruction,
        input [31:0] data_in,
        output reg [3:0] write_index,
        output reg write,
        output t_reg write_data,
        output reg write_immediate,
        output reg [15:0] write_immediate_data,
        output t_immediate_type write_immediate_type,
        output reg [31:0] outbound_instruction
    );

    wire t_opcode opcode = inbound_instruction[31:27];

    always @ (posedge reset, posedge clock) begin
        if (reset) begin
            outbound_instruction <= { OPCODE_NOP, 27'h0 };
            write_index <= 4'h0;
            write_immediate_type <= IT_UNSIGNED;
            write_immediate_data <= 16'h0;
            write <= 1'b0;
        end else begin
            case (opcode)
                OPCODE_LOADI: begin
                    $display("STAGE2: OPCODE_LOADI - Immediate load");
                    write_index <= inbound_instruction[23:20];
                    write_immediate_type <= inbound_instruction[25:24];
                    write_immediate_data <= inbound_instruction[15:0];
                    write_immediate <= 1'b1;
                    write <= 1'b0;
                end
                OPCODE_LOAD: begin
                    $display("STAGE2: OPCODE_LOAD - Memory load");
                    write_index <= inbound_instruction[23:20];
                    write <= 1'b1;
                    write_data <= data_in;
                    write_immediate <= 1'b0;
                end
                default: begin
                    write <= 1'b0;
                    write_immediate <= 1'b0;
                end
            endcase

            $display("STAGE2: Passing forward %08x", inbound_instruction);
            outbound_instruction <= inbound_instruction;
        end
    end
endmodule
