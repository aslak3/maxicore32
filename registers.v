`include "registers.vh"

module registers
    (
        input   reset,
        input   clock,
        input   clear, write, inc, dec,
        input   t_reg_index write_index, incdec_index,
        input   t_reg write_data,
        input   t_reg_index read_reg1_index, read_reg2_index, read_reg3_index,
        output  t_reg reg1_data, reg2_data, reg3_data
    );

    t_regs register_file;

    assign reg1_data = register_file[read_reg1_index];
    assign reg2_data = register_file[read_reg2_index];
    assign reg3_data = register_file[read_reg3_index];

    always @ (posedge reset, posedge clock) begin
        if (reset) begin
            for (int i = 0; i < 16; i++) begin
                register_file[i] = 32'h0;
            end
        end else if (clock) begin
            if (clear) begin
                register_file[write_index] = 32'h0;
            end else if (write) begin
                register_file[write_index] <= write_data;
            end
            if (inc) begin
                register_file[incdec_index] += 4;
            end else if (dec) begin
                register_file[incdec_index] -= 4;
            end
        end
    end
endmodule
