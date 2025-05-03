localparam
    STATE_IDLE = 0,
    STATE_START = 1,
    STATE_DATA = 2,
    STATE_STOP = 3;

module uart
    #(
        // 115200 with 25MHz input clock, actual baud rate c. 115207.37, an error of <0.1%
        parameter BIT_PERIOD = 217
    )
    (
        input         reset,
        input         clock,

        input         trigger,
        input         [7:0] write_data,
        output reg    [7:0] read_data,
        output reg    framing_error_set,
        output reg     tx_ready,
        output reg     rx_ready_set,
        output reg    tx,
        input         rx
    );


    reg [7:0] tx_data;
    integer tx_baud_counter;
    reg [2:0] tx_bit_counter;
    integer tx_state;

    always @ (posedge clock) begin
        if (reset == 1'b1) begin
            tx_baud_counter <= 0;
            tx_bit_counter <= 3'b000;
            tx_state <= STATE_IDLE;
            tx <= 1'b1;
            tx_ready <= 1'b1;
        end else begin
            if (tx_baud_counter == 0 || tx_state == STATE_IDLE) begin
                tx_baud_counter <= BIT_PERIOD;
            end else begin
                tx_baud_counter <= tx_baud_counter - 1;
            end

            case (tx_state)
                STATE_IDLE: begin
                    tx <= 1'b1;
                    if (trigger == 1'b1) begin
                        tx_ready <= 1'b0;
                        tx_data <= write_data;
                        tx_state <= STATE_START;
                    end
                end

                STATE_START: begin
                    tx <= 1'b0;
                    if (tx_baud_counter == 0) begin
                        tx_state <= STATE_DATA;
                        tx_bit_counter <= 3'b000;
                    end
                end

                STATE_DATA: begin
                    tx <= tx_data[tx_bit_counter];
                    if (tx_baud_counter == 0) begin
                        if (tx_bit_counter == 3'b111) begin
                            tx_state <= STATE_STOP;
                        end else begin
                            tx_bit_counter <= tx_bit_counter + 3'b001;
                        end
                    end
                end

                STATE_STOP: begin
                    tx <= 1'b1;
                    if (tx_baud_counter == 0) begin
                        tx_ready <= 1'b1;
                        tx_state <= STATE_IDLE;
                    end
                end
            endcase
        end
    end

    reg [7:0] rx_data;
    integer rx_baud_counter;
    reg [2:0] rx_bit_counter;
    integer rx_state;

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
                STATE_IDLE: begin
                    rx_ready_set <= 1'b0;
                    framing_error_set <= 1'b0;
                    if (rx == 1'b0) begin
                        rx_state <= STATE_START;
                    end
                end

                STATE_START: begin
                    if (rx_baud_counter == 0) begin
                        if (rx == 1'b1) begin
                            framing_error_set <= 1'b1;
                        end
                        rx_bit_counter <= 0;
                        rx_state <= STATE_DATA;
                    end
                end

                STATE_DATA: begin
                    rx_data[rx_bit_counter] <= rx;
                    if (rx_baud_counter == 0) begin
                        if (rx_bit_counter == 3'b111) begin
                            rx_state <= STATE_STOP;
                        end else begin
                            rx_bit_counter <= rx_bit_counter + 3'b001;
                        end
                    end
                end

                STATE_STOP: begin
                    if (rx_baud_counter == 0) begin
                        if (rx == 1'b0) begin
                            framing_error_set <= 1'b1;
                        end
                        rx_ready_set <= 1'b1;
                        rx_state <= STATE_IDLE;
                        read_data <= rx_data;
                    end
                end
            endcase
        end
    end
endmodule
