`include "registers.vh"

module register_file
    (
        input   reset,
        input   clock,
        input   t_reg_index write_index,
        input   write,
        input   t_reg write_data,
        input   write_immediate,
        input   [15:0] write_immediate_data,
        input   [1:0] write_immediate_type,
        input   t_reg_index read_reg1_index, read_reg2_index, read_reg3_index,
        output  t_reg read_reg1_data, read_reg2_data, read_reg3_data
    );

    t_regs register_file;

    assign read_reg1_data = register_file[read_reg1_index];
    assign read_reg2_data = register_file[read_reg2_index];
    assign read_reg3_data = register_file[read_reg3_index];

    wire [31:0] foo;

    always @ (posedge reset, posedge clock) begin
        if (reset) begin
            for (int i = 0; i < 16; i++) begin
                register_file[i] = 32'h0;
            end
        end else if (clock) begin
            if (write) begin
                $display("Writing %08x into reg %01x", write_data, write_index);
                register_file[write_index] <= write_data;
            end else if (write_immediate) begin
                $display("Writing immediate %04x type %02b into reg %01x", write_immediate_data,
                    write_immediate_type, write_index);
                case (write_immediate_type)
                    IT_BOTTOM:
                        register_file[write_index][15:0] <= write_immediate_data;
                    IT_TOP:
                        register_file[write_index][31:16] <= write_immediate_data;
                    IT_UNSIGNED:
                        register_file[write_index] <= { 16'h0, write_immediate_data };
                    IT_SIGNED:
                        register_file[write_index] <= { { 16 { write_immediate_data[15] }}, write_immediate_data };
                endcase
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
        input   t_reg jump_data,
        output  t_reg read_data
    );

    t_reg program_counter;

    assign read_data = program_counter;

    always @ (posedge reset, posedge clock) begin
        if (reset) begin
            program_counter <= 32'h0;
        end else if (clock) begin
            if (jump) begin
                $display("Jumping to %08x", jump_data);
                program_counter <= jump_data;
            end else if (inc) begin
                program_counter <= program_counter + 4;
            end
        end
    end

endmodule
