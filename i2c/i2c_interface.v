module i2c_interface
    (
        input reset,
        input clock,
        input read,
        input write,
        input address_cs,
        input read_cs,
        input write_cs,
        input control_cs,
        input [31:0] data_in,
        output reg [31:0] data_out,
        output reg data_out_valid,

        inout scl,
        inout sda
    );

    reg i2c_trigger;
	reg i2c_restart;
	reg i2c_last_byte;
	reg [6:0] i2c_address;
	reg i2c_read_write;
	reg [7:0] i2c_write_data;
	reg [7:0] i2c_read_data;
	reg i2c_ack_error;
	reg i2c_busy;

    always @ (*) begin
        if (read_cs) begin
            data_out = { i2c_read_data, 24'h000000 };
        end else if (control_cs) begin
            data_out = { i2c_busy, i2c_ack_error, 6'b000000, 24'h000000 };
        end else begin
            data_out = 32'h0;
        end
    end

    assign data_out_valid = read_cs || control_cs ? 1'b1 : 1'b0;

    always @ (posedge clock) begin
        i2c_trigger <= 1'b0;
        i2c_restart <= 1'b0;

        if (write) begin
            if (address_cs) begin
                i2c_read_write <= data_in[31];
                i2c_address <= data_in[30:24];
                i2c_trigger <= 1'b1;
                i2c_restart <= 1'b1;
            end else if (read_cs) begin
                i2c_trigger <= 1'b1;
            end else if (write_cs) begin
                i2c_write_data <= data_in[31:24];
                i2c_trigger <= 1'b1;
            end else if (control_cs) begin
                i2c_last_byte <= data_in[31];
            end
        end
    end
    
    i2c_controller i2c_controller (
		.clock(clock),
		.reset(reset),
		.trigger(i2c_trigger),
		.restart(i2c_restart),
		.last_byte(i2c_last_byte),
		.address(i2c_address),
		.read_write(i2c_read_write),
		.write_data(i2c_write_data),
		.read_data(i2c_read_data),
		.ack_error(i2c_ack_error),
		.busy(i2c_busy),
		.scl(scl),
		.sda(sda)
	);
endmodule