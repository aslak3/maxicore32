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
    reg [31:0] cpu_data_out = 32'h0;
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

    reg register_file_write;
    wire t_reg_index register_file_write_index;
    t_reg register_file_write_data;
    t_reg_index register_file_read_reg1_index, register_file_read_reg2_index, register_file_read_reg3_index;
    wire t_reg register_file_read_reg1_data, register_file_read_reg2_data, register_file_read_reg3_data;

    register_file register_file (
        .reset(reset),
        .clock(clock),

        .clear(1'b0), .write(register_file_write), .inc(1'b0), .dec(1'b0),
        .write_index(register_file_write_index),
        .incdec_index(4'h0),
        .write_data(register_file_write_data),
        .read_reg1_index(register_file_read_reg1_index),
        .read_reg2_index(register_file_read_reg2_index),
        .read_reg3_index(register_file_read_reg3_index),
        .read_reg1_data(register_file_read_reg1_data),
        .read_reg2_data(register_file_read_reg2_data),
        .read_reg3_data(register_file_read_reg3_data)
    );

    wire fetchstage0_block_fetch;
    wire [31:0] fetchstage0_outbound_instruction;

    fetchstage0 fetchstage0 (
        .reset(reset),
        .clock(clock),

        .block_fetch(fetchstage0_block_fetch),
        .mem_data(cpu_data_in),
        .inc_pc(program_counter_inc),
        .outbound_instruction(fetchstage0_outbound_instruction)
    );

    wire [31:0] memorystage1_outbound_instruction;

    memorystage1 memorystage1 (
        .reset(reset),
        .clock(clock),

        .inbound_instruction(fetchstage0_outbound_instruction),
        .outbound_instruction(memorystage1_outbound_instruction),
        .block_fetch(fetchstage0_block_fetch)
    );

    wire [31:0] registersstage2_outbound_instruction;

    registersstage2 registersstage2 (
        .reset(reset),
        .clock(clock),

        .inbound_instruction(memorystage1_outbound_instruction),
        .write_index(register_file_write_index),
        .write_data(register_file_write_data),
        .write(register_file_write),
        .outbound_instruction(registersstage2_outbound_instruction)
    );

    always @ (posedge reset, posedge clock) begin
        if (reset) begin
        end else begin
        end
    end

    // TODO: Muxes
    assign cpu_address = program_counter_read_data;
    assign cpu_cycle_width = CW_LONG;
    assign cpu_read = ~fetchstage0_block_fetch;
    assign cpu_write = 1'b0;
endmodule
