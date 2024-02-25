`ifndef BUSINTERFACE_H
typedef reg [1:0] t_cycle_width;

localparam  CW_BYTE = 2'b00,
            CW_WORD = 2'b01,
            CW_LONG = 2'b10,
            CW_NULL = 2'b11;

`define BUSINTERFACE_H 1
`endif
