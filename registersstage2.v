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
        input [31:0] inbound_address,
        output reg [31:0] outbound_address,
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
        output reg jump,
        output reg alu_carry_in,
        input alu_carry_out, alu_zero_out, alu_neg_out, alu_over_out
    );

    wire t_opcode opcode = inbound_instruction[31:27];
    wire t_alu_condition alu_condition = inbound_instruction[15:12];
    reg alu_carry_result, alu_zero_result, alu_neg_result, alu_over_result;
    reg cond_true;

    always @ (alu_carry_result, alu_zero_result, alu_neg_result, alu_over_result, alu_condition) begin
        case (alu_condition)
            COND_AL:
                cond_true = 1'b1;
            COND_EQ:
                cond_true = alu_zero_result;
            COND_NE:
                cond_true = ~alu_zero_result;
            COND_CS:
                cond_true = alu_carry_result;
            COND_CC:
                cond_true = ~alu_carry_result;
            COND_MI:
                cond_true = alu_neg_result;
            COND_PL:
                cond_true = ~alu_neg_result;
            COND_VS:
                cond_true = alu_over_result;
            COND_VC:
                cond_true = ~cond_true <= alu_over_result;
            COND_HI:
                cond_true = ~cond_true <= alu_carry_result & ~cond_true <= alu_zero_result;
            COND_LS:
                cond_true = cond_true <= alu_carry_result | cond_true <= alu_zero_result;
            COND_GE:
                cond_true = ~(cond_true <= alu_neg_result ^ cond_true <= alu_over_result);
            COND_LT:
                cond_true = cond_true <= alu_neg_result ^ cond_true <= alu_over_result;
            COND_GT:
                cond_true = ~cond_true <= alu_zero_result &
                    ~(cond_true <= alu_neg_result ^ cond_true <= alu_over_result);
            COND_LE:
                cond_true = cond_true <= alu_zero_result |
                    (cond_true <= alu_neg_result ^ cond_true <= alu_over_result);
            default:
                cond_true = 1'b0;
        endcase
    end

    always @ (posedge reset, posedge clock) begin
        if (reset) begin
            outbound_instruction <= { OPCODE_NOP, 27'h0 };
            write_index <= 4'h0;
            write_immediate_type <= IT_UNSIGNED;
            write_immediate_data <= 16'h0;
            write <= 1'b0;
            alu_cycle <= 1'b0;;
            jump <= 1'b0;
        end else begin
            alu_cycle <= 1'b0;
            jump <= 1'b0;
            write <= 1'b0;
            write_immediate <= 1'b0;

            case (opcode)
                OPCODE_LOADI: begin
                    $display("STAGE2: OPCODE_LOADI - Immediate load");
                    write_index <= inbound_instruction[23:20];
                    write_immediate_type <= inbound_instruction[26:25];
                    write_immediate_data <= inbound_instruction[15:0];
                    write_immediate <= 1'b1;
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
                end
                OPCODE_ALUMI: begin
                    $display("STAGE2: OPCODE_ALUMI");
                end
                OPCODE_ALU: begin
                    $display("STAGE2: OPCODE_ALU");
                end
                OPCODE_BRANCH: begin
                    if (cond_true) begin
                        $display("STAGE2: OPCODE_BRANCH: Branch being taken");
                        alu_cycle <= 1'b0;
                        alu_result_latched <= alu_result;
                        jump <= 1'b1;
                        if (inbound_instruction[24]) begin
                            $display("STAGE_OPCODE_BRANCH: Saving PC");
                            write_index <= inbound_instruction[23:20];
                            write_data <= inbound_address;
                            write <= 1'b1;
                        end
                    end else begin
                        $display("STAGE2: OPCODE_BRANCH: Branch NOT being taken");
                    end
                end
                OPCODE_JUMP: begin
                    if (cond_true) begin
                        $display("STAGE2: OPCODE_JUMP: Branch being taken");
                        alu_cycle <= 1'b0;
                        alu_result_latched <= alu_result;
                        jump <= 1'b1;
                        if (inbound_instruction[24]) begin
                            $display("STAGE_OPCODE_JUMP: Saving PC");
                            write_index <= inbound_instruction[23:20];
                            write_data <= inbound_address;
                            write <= 1'b1;
                        end
                    end else begin
                        $display("STAGE2: OPCODE_JUMP: Branch NOT being taken");
                    end
                end
                default: begin
                end
            endcase

            case (opcode)
                OPCODE_ALUM,
                OPCODE_ALUMI,
                OPCODE_ALU: begin
                    $display("ZERO IS NOW %01b", alu_zero_out);
                    alu_carry_result <= alu_carry_out;
                    alu_zero_result <= alu_zero_out;
                    alu_neg_result <= alu_neg_out;
                    alu_over_result <= alu_over_out;
                    alu_carry_in <= alu_carry_out;
                    alu_result_latched <= alu_result;
                    alu_cycle <= 1'b1;
                    write_index <= inbound_instruction[23:20];
                    write <= 1'b1;
                end
                default: begin
                end
            endcase

            $display("STAGE2: Passing forward %08x", inbound_instruction);
            outbound_instruction <= inbound_instruction;
            outbound_address <= inbound_address;
        end
    end
endmodule
