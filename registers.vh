`ifndef REGISTERS_VH
typedef reg [31:0] t_reg;
typedef t_reg t_regs [16];
typedef reg [3:0] t_reg_index;

typedef reg [1:0] t_immediate_type;
localparam  IT_TOP = 2'b00,
            IT_BOTTOM = 2'b01,
            IT_UNSIGNED = 2'b10,
            IT_SIGNED = 2'b11;

`define REGISTERS_VH 1
`endif
