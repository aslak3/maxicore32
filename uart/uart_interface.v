// Provides a bus-compatible interface to the UART controller
// Handles both data and status register access

module uart_interface
    (
        input reset,                    // Synchronous reset
        input clock,                    // System clock

        // Bus control signals
        input read,                     // Read request
        input write,                    // Write request
        input data_cs,                  // Data register chip select
        input status_cs,                // Status register chip select
        input [31:0] data_in,           // Input data bus (8-bit UART data in upper byte)
        output reg [31:0] data_out,     // Output data bus
        output reg data_out_valid,      // Data output valid flag

        // UART signals
        output tx,                      // Transmit line
        input rx                        // Receive line
    );

    // Status flags
    reg rx_ready = 1'b0;                // Indicates received data is available
    reg framing_error = 1'b0;           // UART framing error flag

    // Sequential logic: handle reset, reads, writes, and status updates
    always @ (posedge clock) begin
        if (reset == 1'b1) begin
            // Clear all status flags on reset
            rx_ready <= 1'b0;
            framing_error <= 1'b0;
            trigger <= 1'b0;
        end else begin
            // Clear flags when status register is read
            if (read == 1'b1) begin
                if (data_cs == 1'b1) begin
                    rx_ready <= 1'b0;
                    framing_error <= 1'b0;
                end
            end

            // Default: clear write trigger
            trigger <= 1'b0;

            // Handle data write: extract TX byte from upper byte of data_in
            if (write == 1'b1) begin
                if (data_cs == 1'b1) begin
                    write_data <= data_in[31:24];
                    trigger <= 1'b1;                // Strobe UART to transmit
                end
            end

            // Update RX ready flag from UART
            if (rx_ready_set == 1'b1) begin
                rx_ready <= 1'b1;
            end

            // Update framing error flag from UART
            if (framing_error_set == 1'b1) begin
                framing_error <= 1'b1;
            end
        end
    end

    // Combinatorial logic: multiplex status or data onto output based on chip select
    always @ (*) begin
        if (status_cs == 1'b1) begin
            // Status register: { rx_ready, framing_error, tx_ready, 5'b00000, 24'h000000 }
            data_out = { rx_ready, framing_error, tx_ready, 5'b00000, 24'h000000 };
        end else if (data_cs == 1'b1) begin
            // Data register: received byte in upper 8 bits
            data_out = { read_data, 24'h0000000 };
        end else begin
            // Default: output zeros
            data_out = { 32'h0 };
        end
    end

    // Valid flag: asserted when reading status or data
    assign data_out_valid = read && (status_cs || data_cs) ? 1'b1 : 1'b0;

    // Internal signals for communication with UART controller
    reg trigger;                       // Write trigger pulse to UART
    reg [7:0] write_data;              // Data to transmit to UART
    reg [7:0] read_data;               // Data received from UART
    reg framing_error_set;             // UART signals framing error detected
    reg tx_ready;                      // UART signals transmitter is ready
    reg rx_ready_set;                  // UART signals data received and ready to read

    // Instantiate UART controller
    uart #(
    )
    uart (
        .reset(reset),
        .clock(clock),

        .trigger(trigger),               // Pulse to transmit write_data
        .write_data(write_data),         // 8-bit TX data
        .read_data(read_data),           // 8-bit RX data
        .framing_error_set(framing_error_set),  // RX framing error indicator
        .tx_ready(tx_ready),             // TX ready indicator
        .rx_ready_set(rx_ready_set),     // RX data available indicator
        .tx(tx),                         // UART TX output
        .rx(rx)                          // UART RX input
    );
endmodule
