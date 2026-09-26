// PS/2 interface – provides status and scancode registers
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

    // Combinational logic to drive the 32‑bit data bus based on
    // the selected register.  The status register contains
    // ready and parity error bits; the scancode register
    // contains the last received scancode.
    always @ (*) begin
        if (status_cs) begin
            data_out = { scancode_ready, parity_error, 6'b000000, 24'h000000 };
        end else if (scancode_cs) begin
            data_out = { rx_scancode, 24'h0000000 };
        end else begin
            data_out = { 32'h0 };
        end
    end

    // Data is valid when a read is performed on either
    // the status or scancode register.
    assign data_out_valid = read && (status_cs || scancode_cs) ? 1'b1 : 1'b0;

    // scancode_ready indicates that a new scancode is available.
    reg scancode_ready = 1'b0;
    always @ (posedge clock) begin
        if (read) begin
            if (scancode_cs) begin
                scancode_ready <= 1'b0; // clear on read
            end
        end

        if (scancode_ready_set) begin
            scancode_ready <= 1'b1;
        end
    end

    // Detect edges on the PS/2 clock line.
    wire edge_found;
    ps2_edge_finder ps2_edge_finder (
        .clock(clock),
        .edge_found(edge_found),
        .ps2_clock(ps2_clock)
    );

    // Shift in the scancode bits and detect parity.
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