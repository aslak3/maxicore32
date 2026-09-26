// Detects falling and rising edges on the PS/2 clock line.
module ps2_edge_finder
    (
        input clock,
        output reg edge_found,
        input ps2_clock
    );

    // Shift register to capture the last 8 samples of the clock
    reg [7:0] edge_finder = 8'h00;

	always @ (posedge clock) begin
        // Shift the incoming clock signal in
        edge_finder <= { edge_finder[6:0], ps2_clock };
        // Detect a falling edge (high to low transition)
        if (edge_finder == 8'hf0) begin
            edge_found <= 1'b0;
        end else if (edge_finder == 8'h0f) begin
            edge_found <= 1'b1; // rising edge
        end
	end
endmodule

// State machine for receiving a PS/2 scancode
localparam
    RX_START = 0,
    RX_BYTE = 1,
    RX_ODD_PARITY = 2,
    RX_STOP = 3;

// Shifts in the scancode bits and checks parity.
module ps2_rx_shifter
    (
        input clock,
        input edge_found,
        output reg [7:0] rx_scancode,
        output reg scancode_ready_set,
        output reg parity_error,
        input ps2_data                  // PS/2 data pin
    );

    // Buffer to assemble the 8‑bit scancode
    reg [7:0] byte_buffer;
    // Counter for bits received (0‑7)
    reg [2:0] bit_shift_counter;        // 0..7 bit count
    // Parity accumulator (odd parity)
    reg parity_check = 1'b0;
    // Counter to detect a timeout if no edges occur
    reg [15:0] scancode_rx_counter;
    // Current state of the receiver FSM
    integer state = RX_START;
    // Holds the previous edge_found value for edge detection
    reg last_edge_found;

    always @ (posedge clock) begin
        // Store previous edge state for detecting falling edges
        last_edge_found <= edge_found;
        scancode_ready_set <= 1'b0;

        if (scancode_rx_counter == 16'hffff) begin
            state <= RX_START;
        end

        scancode_rx_counter <= scancode_rx_counter + 16'h0001;

        // Detect a falling edge on the PS/2 clock
        if (~edge_found && last_edge_found) begin
            scancode_rx_counter <= 16'h0000;

            case (state)
                RX_START: begin
                    // Reset for a new byte
                    parity_error <= 1'b0;
                    bit_shift_counter <= 3'b000;
                    byte_buffer <= 8'h00;
                    parity_check <= 1'b1; // start with odd parity
                    state <= RX_BYTE;
                end

                RX_BYTE: begin
                    // Accumulate parity and shift in data bit
                    parity_check <= parity_check ^ ps2_data;
                    byte_buffer[bit_shift_counter] <= ps2_data;
                    if (bit_shift_counter == 3'b111) begin
                        state <= RX_ODD_PARITY;
                    end
                    bit_shift_counter <= bit_shift_counter + 3'b001;
                end

                RX_ODD_PARITY: begin
                    // Verify even parity: parity_check should equal inverse of data bit
                    if (parity_check == ~ps2_data) begin
                        parity_error <= 1'b0;
                    end else begin
                        parity_check <= 1'b1;
                    end
                    rx_scancode <= byte_buffer;
                    state <= RX_STOP;
                end

                RX_STOP: begin
                    scancode_ready_set <= 1'b1;
                    state <= RX_START;
                end
            endcase
        end
    end
endmodule