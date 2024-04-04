`include "registers.vh"
`include "opcodes.vh"

module fetchstage0
    (
        input reset,
        input clock,

        input insert_nop,
        input [31:0] mem_data,
        output reg inc_pc,
        output reg [31:0] outbound_instruction
    );

    always @ (posedge reset, posedge clock) begin
        if (reset) begin
            outbound_instruction <= { OPCODE_NOP, 27'h0 };
        end else begin
            if (insert_nop == 1'b1) begin
                $display("Inserting NOP");
                inc_pc <= 1'b0;
                outbound_instruction <= { OPCODE_NOP, 27'h0 };
            end else begin
                inc_pc <= 1'b1;
                outbound_instruction <= mem_data;
            end
        end
    end
endmodule
