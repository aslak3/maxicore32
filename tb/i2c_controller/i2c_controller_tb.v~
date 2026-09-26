module i2c_controller_tb;
	reg i2c_clock;
	reg i2c_reset;
	reg i2c_trigger;
	reg i2c_restart;
	reg i2c_last_byte;
	reg [6:0] i2c_address;
	reg i2c_read_write;
	reg [7:0] i2c_write_data;
	reg [7:0] i2c_read_data;
	reg i2c_ack_error;
	reg i2c_busy;
	reg i2c_scl;
	reg i2c_sda;

    i2c_controller dut (
		.clock(i2c_clock),
		.reset(i2c_reset),
		.trigger(i2c_trigger),
		.restart(i2c_restart),
		.last_byte(i2c_last_byte),
		.address(i2c_address),
		.read_write(i2c_read_write),
		.write_data(i2c_write_data),
		.read_data(i2c_read_data),
		.ack_error(i2c_ack_error),
		.busy(i2c_busy),
		.scl(i2c_scl),
		.sda(i2c_sda)
	);

    initial i2c_clock = 1'b0;

    always #1 i2c_clock = ~i2c_clock;

    initial begin
        $dumpfile("i2c_controller.vcd");
        $dumpvars;

		// Reset sequence
		i2c_reset = 1'b1;
		i2c_trigger = 1'b0;
		i2c_restart = 1'b0;
		
        #2;

		// Write two bytes
		i2c_reset = 1'b0;
		i2c_address = 7'b1101000;
		i2c_read_write = 1'b0;
		i2c_write_data = 8'h00;
		i2c_last_byte = 1'b0;
		i2c_trigger = 1'b1;

        #2;

		i2c_trigger = 1'b0;

		wait (~i2c_busy);
		#100;

		i2c_write_data = 8'h0f;
		i2c_trigger = 1'b1;
		i2c_last_byte = 1'b0;
		#2;
		i2c_trigger = 1'b0;

		wait (~i2c_busy);
    	#100

		i2c_write_data = 8'haa;
		i2c_trigger = 1'b1;
		i2c_last_byte = 1'b0;
		#2;
		i2c_trigger = 1'b0;

		wait (~i2c_busy);
		#100;

		// Read after restart
		i2c_read_write = 1'b1;
		i2c_write_data = 8'h00;
		i2c_last_byte = 1'b0;
		i2c_trigger = 1'b1;
		i2c_restart = 1'b1;
		#2;
		i2c_trigger = 1'b0;
		i2c_restart = 1'b0;

		wait (~i2c_busy);
		#100;

		i2c_trigger = 1'b1;
		#2;
		i2c_trigger = 1'b0;

		wait (~i2c_busy);
		#100;

		i2c_trigger = 1'b1;
		i2c_last_byte = 1'b1;
		#100;
		i2c_trigger = 1'b0;

		wait (~i2c_busy);
		#100;

		$display("+++All good");
        $finish;
	end

    always @ (i2c_scl, i2c_sda, i2c_busy) begin
		$display("SCL %d: SDA: %d Busy: %d", i2c_scl, i2c_sda, i2c_busy);
	end
endmodule