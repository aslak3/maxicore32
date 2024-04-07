`include "registers.vh"
`include "alu.vh"
`include "businterface.vh"

module maxicore32
    (
        input reset,
        input clock,

        output [31:2] address,
        input [31:0] data_in,
        output [31:0] data_out,
        output [3:0] data_strobes,
        output read,
        output write,
        output bus_error,
        output reg halted
    );

    wire [31:0] cpu_address;
    wire t_cycle_width cpu_cycle_width;
    wire [31:0] cpu_data_out;
    wire [31:0] cpu_data_in;
    wire cpu_read, cpu_write;

    businterface businterface (
        .cpu_address(cpu_address),
        .cpu_cycle_width(cpu_cycle_width),
        .cpu_data_out(cpu_data_out),
        .cpu_data_in(cpu_data_in),
        .cpu_read(cpu_read), .cpu_write(cpu_write),

        .businterface_address(address),
        .businterface_data_in(data_in),
        .businterface_data_out(data_out),
        .businterface_data_strobes(data_strobes),
        .businterface_bus_error(bus_error),
        .businterface_read(read), .businterface_write(write)
    );

    reg program_counter_jump = 1'b0;
    wire program_counter_inc;
    reg program_counter_branch = 1'b0;
    reg [31:0] program_counter_jump_data = 32'h0;
    reg [15:0] program_counter_branch_data = 16'h0;
    wire [31:0] program_counter_read_data;

    program_counter program_counter (
        .reset(reset),
        .clock(clock),

        .jump(program_counter_jump),
        .inc(program_counter_inc),
        .branch(program_counter_branch),
        .jump_data(program_counter_jump_data),
        .branch_data(program_counter_branch_data),
        .read_data(program_counter_read_data)
    );

    wire t_reg_index register_file_write_index;
    wire register_file_write;
    t_reg register_file_write_data;
    wire register_file_write_immediate;
    wire [15:0] register_file_write_immediate_data;
    t_immediate_type register_file_write_immediate_type;
    t_reg_index register_file_read_reg1_index, register_file_read_reg2_index, register_file_read_reg3_index;
    wire t_reg register_file_read_reg1_data, register_file_read_reg2_data, register_file_read_reg3_data;

    register_file register_file (
        .reset(reset),
        .clock(clock),

        .write_index(register_file_write_index),
        .write(register_file_write),
        .write_data(register_file_write_data),
        .write_immediate(register_file_write_immediate),
        .write_immediate_data(register_file_write_immediate_data),
        .write_immediate_type(register_file_write_immediate_type),
        .read_reg1_index(register_file_read_reg1_index),
        .read_reg2_index(register_file_read_reg2_index),
        .read_reg3_index(register_file_read_reg3_index),
        .read_reg1_data(register_file_read_reg1_data),
        .read_reg2_data(register_file_read_reg2_data),
        .read_reg3_data(register_file_read_reg3_data)
    );

    t_alu_op alu_op;
    t_reg alu_reg2, alu_reg3;
    reg alu_carry_in;
    wire t_reg alu_result;
    wire alu_carry_out, alu_zero_out, alu_neg_out, alu_over_out;

    alu alu (
        .op(alu_op),
        .reg2(alu_reg2), .reg3(alu_reg3),
        .carry_in(alu_carry_in),
        .result(alu_result),
        .carry_out(alu_carry_out), .zero_out(alu_zero_out),
        .neg_out(alu_neg_out), .over_out(alu_over_out)
    );

    wire fetchstage0_memory_access_cycle;
    wire fetchstage0_halting;
    wire [31:0] fetchstage0_outbound_instruction;

    fetchstage0 fetchstage0 (
        .reset(reset),
        .clock(clock),

        .mem_data(cpu_data_in),
        .outbound_instruction(fetchstage0_outbound_instruction),
        .block_fetch(fetchstage0_memory_access_cycle),
        .halting(fetchstage0_halting)
    );

    wire [31:0] memorystage1_outbound_instruction;
    wire memory_read, memory_write;
    wire t_cycle_width memory_cycle_width;
    wire [15:0] memory_offset;

    memorystage1 memorystage1 (
        .reset(reset),
        .clock(clock),

        .inbound_instruction(fetchstage0_outbound_instruction),
        .outbound_instruction(memorystage1_outbound_instruction),
        .memory_access_cycle(fetchstage0_memory_access_cycle),
        .memory_read(memory_read),
        .memory_write(memory_write),
        .memory_cycle_width(memory_cycle_width),
        .memory_offset(memory_offset),
        .reg_data_index(register_file_read_reg1_index),
        .reg_address_index(register_file_read_reg2_index),
        .reg_operand_index(register_file_read_reg3_index),
        .alu_op(alu_op)
    );

    wire [31:0] registersstage2_outbound_instruction;
    wire t_reg registerstage2_write_data;
    wire registerstage2_alu_cycle;
    wire t_reg registerstage2_alu_result_latched;

    registersstage2 registersstage2 (
        .reset(reset),
        .clock(clock),

        .inbound_instruction(memorystage1_outbound_instruction),
        .outbound_instruction(registersstage2_outbound_instruction),
        .data_in(cpu_data_in),
        .write_index(register_file_write_index),
        .write(register_file_write),
        .write_data(registerstage2_write_data),
        .write_immediate(register_file_write_immediate),
        .write_immediate_data(register_file_write_immediate_data),
        .write_immediate_type(register_file_write_immediate_type),
        .alu_cycle(registerstage2_alu_cycle),
        .alu_result(alu_result),
        .alu_result_latched(registerstage2_alu_result_latched)
    );

    reg [1:0] halting_counter;

    always @ (posedge reset, posedge clock) begin
        if (reset) begin
            halting_counter <= 2'b00;
            halted <= 1'b0;
        end else begin
            if (fetchstage0_halting) begin
                if (halting_counter != 2'b11) begin
                    halting_counter <= halting_counter + 2'b01;
                end else begin
                    $display("End HALT state reached");
                    halted <= 1'b1;
                end
            end
        end
    end

    assign cpu_address = fetchstage0_memory_access_cycle == 1'b0 ?
        program_counter_read_data :
        alu_result;
    assign cpu_data_out = fetchstage0_memory_access_cycle == 1'b0 ?
        32'h0 :
        register_file_read_reg1_data;
    assign cpu_read = fetchstage0_memory_access_cycle == 1'b0 ?
        1'b1 :
        memory_read;
    assign cpu_write = fetchstage0_memory_access_cycle == 1'b0 ?
        1'b0 :
        memory_write;
    assign cpu_cycle_width = fetchstage0_memory_access_cycle == 1'b0 ?
        CW_LONG :
        memory_cycle_width;

    assign program_counter_inc = fetchstage0_memory_access_cycle == 1'b0 ?
        1'b1 :
        1'b0;

    assign register_file_write_data = registerstage2_alu_cycle == 1'b0 ?
        registerstage2_write_data :
        registerstage2_alu_result_latched;

    assign alu_reg2 = register_file_read_reg2_data;
    assign alu_reg3 = fetchstage0_memory_access_cycle == 1'b0 ?
        register_file_read_reg3_data :
        {{ 16 { memory_offset[15] }}, memory_offset };
endmodule
