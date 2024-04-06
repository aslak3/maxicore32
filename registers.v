`include "registers.vh"

module register_file
    (
        input   reset,
        input   clock,
        input   clear, write, inc, dec,
        input   t_reg_index write_index, incdec_index,
        input   t_reg write_data,
        input   t_reg_index read_reg1_index, read_reg2_index, read_reg3_index,
        output  t_reg read_reg1_data, read_reg2_data, read_reg3_data
    );

    t_regs register_file;

    assign read_reg1_data = register_file[read_reg1_index];
    assign read_reg2_data = register_file[read_reg2_index];
    assign read_reg3_data = register_file[read_reg3_index];

    always @ (posedge reset, posedge clock) begin
        if (reset) begin
            for (int i = 0; i < 16; i++) begin
                register_file[i] = 32'h0;
            end
        end else if (clock) begin
            if (clear) begin
                register_file[write_index] <= 32'h0;
            end else if (write) begin
                $display("Writing %08x into reg %01x", write_data, write_index);
                register_file[write_index] <= write_data;
            end
            if (inc) begin
                register_file[incdec_index] <= register_file[incdec_index] + 4;
            end else if (dec) begin
                register_file[incdec_index] <= register_file[incdec_index] - 4;
            end
        end
    end
endmodule

module program_counter
    (
        input   reset,
        input   clock,
        input   jump,
        input   inc,
        input   branch,
        input   t_reg jump_data,
        input   [15:0] branch_data,
        output  t_reg read_data
    );

    t_reg program_counter;

    assign read_data = program_counter;

    always @ (posedge reset, posedge clock) begin
        if (reset) begin
            program_counter <= 32'h0;
        end else if (clock) begin
            if (jump) begin
                program_counter <= jump_data;
            end else if (inc) begin
                program_counter <= program_counter + 4;
            end else if (branch) begin
                program_counter <= program_counter + { {16{branch_data[15]}}, branch_data[15:0]};
            end
        end
    end

endmodule
