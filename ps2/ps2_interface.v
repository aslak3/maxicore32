module ps2_interface
    (
        input clock,
        input read,
        input status_cs,
        input scancode_cs,
        output reg [31:0] data_out,
        output reg data_out_valid,

        inout ps2_clock,
        inout ps2_data        
    );

    always @ (*) begin
        if (status_cs) begin
            data_out = { scancode_ready, parity_error, 6'b000000, 24'h000000 };
        end else if (scancode_cs) begin
            data_out = { rx_scancode, 24'h0000000 };
        end else begin
            data_out = { 32'h0 };
        end
    end

    assign data_out_valid = read && (status_cs || scancode_cs) ? 1'b1 : 1'b0;

    reg scancode_ready = 1'b0;
    always @ (posedge clock) begin
        if (read) begin
            if (scancode_cs) begin
                scancode_ready <= 1'b0;
            end
        end

        if (scancode_ready_set) begin
            scancode_ready <= 1'b1;
        end
    end

    wire edge_found;
	ps2_edge_finder ps2_edge_finder (
		.clock(clock),
		.edge_found(edge_found),
		.ps2_clock(ps2_clock)
	);

    wire [7:0] rx_scancode;
    wire scancode_ready_set;
    wire parity_error;
    ps2_rx_shifter ps2_rx_shifter (
		.clock(clock),
		.edge_found(edge_found),
		.rx_scancode(rx_scancode),
		.scancode_ready_set(scancode_ready_set),
		.parity_error(parity_error),
		.ps2_data(ps2_data)
	);
endmodule