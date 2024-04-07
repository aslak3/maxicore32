`include "registers.vh"
`include "businterface.vh"
`include "opcodes.vh"
`include "alu.vh"

module registersstage2
    (
        input reset,
        input clock,

        input [31:0] inbound_instruction,
        output reg [31:0] outbound_instruction,
        input [31:0] data_in,
        output reg [3:0] write_index,
        output reg write,
        output t_reg write_data,
        output reg write_immediate,
        output reg [15:0] write_immediate_data,
        output t_immediate_type write_immediate_type,
        output reg alu_cycle,
        input t_reg alu_result,
        output t_reg alu_result_latched,
        input halting
    );

    wire t_opcode opcode = inbound_instruction[31:27];

    always @ (posedge reset, posedge clock) begin
        if (reset) begin
            outbound_instruction <= { OPCODE_NOP, 27'h0 };
            write_index <= 4'h0;
            write_immediate_type <= IT_UNSIGNED;
            write_immediate_data <= 16'h0;
            write <= 1'b0;
            alu_cycle <= 1'b0;
        end else begin
            case (opcode)
                OPCODE_LOADI: begin
                    $display("STAGE2: OPCODE_LOADI - Immediate load");
                    write_index <= inbound_instruction[23:20];
                    write_immediate_type <= inbound_instruction[26:25];
                    write_immediate_data <= inbound_instruction[15:0];
                    write_immediate <= 1'b1;
                    write <= 1'b0;
                    alu_cycle <= 1'b0;
                end
                OPCODE_LOAD: begin
                    $display("STAGE2: OPCODE_LOAD - Memory load");
                    write_index <= inbound_instruction[23:20];
                    write <= 1'b1;
                    // Sign and zero extend the data for the register.
                    case (inbound_instruction[26:25])
                        CW_BYTE: begin
                            if (inbound_instruction[24]) begin
                                write_data <= {{ 24 { data_in[7] }}, data_in[7:0] };
                            end else begin
                                write_data <= { 24'h0, data_in[7:0] };
                            end
                        end
                        CW_WORD: begin
                            if (inbound_instruction[24]) begin
                                write_data <= {{ 16 { data_in[15] }}, data_in[15:0] };
                            end else begin
                                write_data <= { 16'h0, data_in[15:0] };
                            end
                        end
                        default: begin
                            write_data <= data_in;
                        end
                    endcase
                    write_immediate <= 1'b0;
                    alu_cycle <= 1'b0;
                end
                OPCODE_ALUM: begin
                    $display("STAGE2: OPCODE_ALUM");
                    write_index <= inbound_instruction[23:20];
                    write <= 1'b1;
                    alu_cycle <= 1'b1;
                    alu_result_latched <= alu_result;
                end
                OPCODE_ALU: begin
                    $display("STAGE2: OPCODE_ALU");
                    write_index <= inbound_instruction[23:20];
                    write <= 1'b1;
                    alu_cycle <= 1'b1;
                    alu_result_latched <= alu_result;
                end
                default: begin
                    write <= 1'b0;
                    write_immediate <= 1'b0;
                end
            endcase

            $display("STAGE2: Passing forward %08x", inbound_instruction);
            outbound_instruction <= inbound_instruction;

            if (halting) begin
                $display("STAGE2: Halting");
                $fatal;
            end
        end
    end
endmodule
