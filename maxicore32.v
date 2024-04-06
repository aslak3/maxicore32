`include "registers.vh"
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
        output bus_error
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

    wire fetchstage0_memory_access_cycle;
    wire [31:0] fetchstage0_outbound_instruction;

    fetchstage0 fetchstage0 (
        .reset(reset),
        .clock(clock),

        .block_fetch(fetchstage0_memory_access_cycle),
        .mem_data(cpu_data_in),
        .outbound_instruction(fetchstage0_outbound_instruction)
    );

    wire [31:0] memorystage1_outbound_instruction;
    wire memory_read, memory_write;

    memorystage1 memorystage1 (
        .reset(reset),
        .clock(clock),

        .inbound_instruction(fetchstage0_outbound_instruction),
        .outbound_instruction(memorystage1_outbound_instruction),
        .memory_access_cycle(fetchstage0_memory_access_cycle),
        .memory_read(memory_read),
        .memory_write(memory_write),
        .reg_address_index(register_file_read_reg2_index),
        .reg_data_index(register_file_read_reg1_index)
    );

    wire [31:0] registersstage2_outbound_instruction;

    registersstage2 registersstage2 (
        .reset(reset),
        .clock(clock),

        .inbound_instruction(memorystage1_outbound_instruction),
        .data_in(cpu_data_in),
        .write_index(register_file_write_index),
        .write(register_file_write),
        .write_data(register_file_write_data),
        .write_immediate(register_file_write_immediate),
        .write_immediate_data(register_file_write_immediate_data),
        .write_immediate_type(register_file_write_immediate_type),
        .outbound_instruction(registersstage2_outbound_instruction)
    );

    always @ (posedge reset, posedge clock) begin
        if (reset) begin
        end else begin
        end
    end

    assign cpu_address = fetchstage0_memory_access_cycle == 1'b0 ?
        program_counter_read_data :
        register_file_read_reg2_data;
    assign cpu_data_out = fetchstage0_memory_access_cycle == 1'b0 ?
        32'h0 :
        register_file_read_reg1_data;
    assign cpu_cycle_width = CW_LONG;
    assign cpu_read = fetchstage0_memory_access_cycle == 1'b0 ?
        1'b1 :
        memory_read;
    assign cpu_write = fetchstage0_memory_access_cycle == 1'b0 ?
        1'b0 :
        memory_write;

    assign program_counter_inc = ~fetchstage0_memory_access_cycle;

endmodule
