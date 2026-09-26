localparam
    STATE_IDLE = 0,
    STATE_START = 1,
    STATE_DATA = 2,
    STATE_STOP = 3;

// UART module for asynchronous serial communication
module uart
    #(
        // 115200 with 25MHz input clock, actual baud rate c. 115207.37, an error of <0.1%
        parameter BIT_PERIOD = 217
    )
    (
        input         reset,
        input         clock,

        input         trigger,          // Trigger to start a transmission
        input         [7:0] write_data, // Data to be transmitted
        output reg    [7:0] read_data,  // Data received
        output reg    framing_error_set,
        output reg    tx_ready,         // High when TX is ready for new data
        output reg    rx_ready_set,     // High when new data has been received
        output reg    tx,               // UART transmit line
        input         rx                // UART receive line
    );


    // Transmission (TX) registers and state
    reg [7:0] tx_data;
    integer tx_baud_counter;
    reg [2:0] tx_bit_counter;
    integer tx_state;

    // Transmitter state machine
    always @ (posedge clock) begin
        if (reset == 1'b1) begin
            tx_baud_counter <= 0;
            tx_bit_counter <= 3'b000;
            tx_state <= STATE_IDLE;
            tx <= 1'b1;
            tx_ready <= 1'b1;
        end else begin
            // Baud rate counter decrement
            if (tx_baud_counter == 0 || tx_state == STATE_IDLE) begin
                tx_baud_counter <= BIT_PERIOD;
            end else begin
                tx_baud_counter <= tx_baud_counter - 1;
            end

            case (tx_state)
                // Idle – line idle, waiting for trigger
                STATE_IDLE: begin
                    tx <= 1'b1;
                    if (trigger == 1'b1) begin
                        tx_ready <= 1'b0;          // busy
                        tx_data <= write_data;     // latch data
                        tx_state <= STATE_START;    // move to start bit
                    end
                end

                // Start bit – drive low until baud counter expires
                STATE_START: begin
                    tx <= 1'b0; // Start bit
                    if (tx_baud_counter == 0) begin
                        tx_state <= STATE_DATA;      // move to data bits
                        tx_bit_counter <= 3'b000;    // reset bit counter
                    end
                end

                // Data bits – shift out each bit on each baud period
                STATE_DATA: begin
                    tx <= tx_data[tx_bit_counter]; // Send data bits
                    if (tx_baud_counter == 0) begin
                        if (tx_bit_counter == 3'b111) begin
                            tx_state <= STATE_STOP;   // all bits sent
                        end else begin
                            tx_bit_counter <= tx_bit_counter + 3'b001; // next bit
                        end
                    end
                end

                // Stop bit – drive high until baud counter expires
                STATE_STOP: begin
                    tx <= 1'b1; // Stop bit
                    if (tx_baud_counter == 0) begin
                        tx_ready <= 1'b1;          // ready for next byte
                        tx_state <= STATE_IDLE;     // back to idle
                    end
                end
            endcase
        end
    end

    // Receiver (RX) registers and state
    reg [7:0] rx_data;
    integer rx_baud_counter;
    reg [2:0] rx_bit_counter;
    integer rx_state;

    // Receiver state machine
    always @ (posedge clock) begin
        if (reset == 1'b1) begin
            rx_ready_set <= 1'b0;
            rx_baud_counter <= 0;
            rx_bit_counter <= 3'b000;
            rx_state <= STATE_IDLE;
            read_data <= 8'h00;
        end else begin
            if (rx_state != STATE_IDLE) begin
                if (rx_baud_counter == 0) begin
                    rx_baud_counter <= BIT_PERIOD;
                end else begin
                    rx_baud_counter <= rx_baud_counter - 1;
                end
            end else begin
                // Center over the incoming start bit
                rx_baud_counter <= BIT_PERIOD / 2;
            end

            case (rx_state)
                // Idle – line idle, waiting for start bit
                STATE_IDLE: begin
                    rx_ready_set <= 1'b0;
                    framing_error_set <= 1'b0;
                    if (rx == 1'b0) begin
                        rx_state <= STATE_START; // start bit detected
                    end
                end

                // Start bit – verify start and center sampling
                STATE_START: begin
                    if (rx_baud_counter == 0) begin
                        if (rx == 1'b1) begin
                            framing_error_set <= 1'b1; // stray high
                        end
                        rx_bit_counter <= 0;
                        rx_state <= STATE_DATA;      // move to data bits
                    end
                end

                // Data bits – sample each bit on each baud period
                STATE_DATA: begin
                    rx_data[rx_bit_counter] <= rx;
                    if (rx_baud_counter == 0) begin
                        if (rx_bit_counter == 3'b111) begin
                            rx_state <= STATE_STOP;   // all bits received
                        end else begin
                            rx_bit_counter <= rx_bit_counter + 3'b001; // next bit
                        end
                    end
                end

                // Stop bit – verify stop and latch data
                STATE_STOP: begin
                    if (rx_baud_counter == 0) begin
                        if (rx == 1'b0) begin
                            framing_error_set <= 1'b1; // missing stop
                        end
                        rx_ready_set <= 1'b1;          // data ready
                        rx_state <= STATE_IDLE;         // back to idle
                        read_data <= rx_data;           // latch received byte
                    end
                end
            endcase
        end
    end
endmodule
