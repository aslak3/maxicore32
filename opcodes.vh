`ifndef OPCODES_VH
typedef reg [4:0] t_opcode;

localparam t_opcode OPCODE_NOP      = 5'b00000;
localparam t_opcode OPCODE_HALT     = 5'b00001;
localparam t_opcode OPCODE_LOADI    = 5'b00010;
localparam t_opcode OPCODE_LOAD     = 5'b00011;
localparam t_opcode OPCODE_STORE    = 5'b00100;
localparam t_opcode OPCODE_ALUM     = 5'b00101;
localparam t_opcode OPCODE_ALU      = 5'b00110;

`define OPCODES_VH 1
`endif
