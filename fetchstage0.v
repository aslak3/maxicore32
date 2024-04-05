`include "registers.vh"
`include "opcodes.vh"

module fetchstage0
    (
        input reset,
        input clock,

        input block_fetch,
        input [31:0] mem_data,
        output reg inc_pc,
        output reg [31:0] outbound_instruction
    );

    always @ (posedge reset, posedge clock) begin
        if (reset) begin
            outbound_instruction <= { OPCODE_NOP, 27'h0 };
            inc_pc <= 1'b0;
        end else begin
            if (block_fetch == 1'b1) begin
                $display("STAGE0: Inserting NOP");
                inc_pc <= 1'b0;
                outbound_instruction <= { OPCODE_NOP, 27'h0 };
            end else begin
                $display("STAGE0: Passing forward %08x", mem_data);
                inc_pc <= 1'b1;
                outbound_instruction <= mem_data;
            end
        end
    end
endmodule
