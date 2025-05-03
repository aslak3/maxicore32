module uart_tb;
    reg uart_clock;
    reg uart_reset;
    reg uart_trigger;
    reg [7:0] uart_write_data;
    reg [7:0] uart_read_data;
    reg uart_framing_error_set;
    reg uart_tx_ready;
    reg uart_rx_ready_set;
    reg uart_ready_set;
    reg uart_tx;
    reg uart_rx;
    wire uart_loopback;

    uart #(
        .BIT_PERIOD(1)
    )
    dut (
        .reset(uart_reset),
        .clock(uart_clock),

        .trigger(uart_trigger),
        .write_data(uart_write_data),
        .read_data(uart_read_data),
        .framing_error_set(uart_framing_error_set),
        .tx_ready(uart_tx_ready),
        .rx_ready_set(uart_rx_ready_set),
        .tx(uart_loopback),
        .rx(uart_loopback)
    );

    initial uart_clock = 1'b0;

    always #1 uart_clock = ~uart_clock;

    initial begin
        $dumpfile("uart.vcd");
        $dumpvars;

        // Reset sequence
        uart_reset = 1'b1;
        uart_trigger = 1'b0;
        uart_write_data = 8'h00;

        #2;

        // Write one byte
        uart_reset = 1'b0;
        uart_write_data = 8'h2a;
        uart_trigger = 1'b1;

        #2;

        uart_write_data = 8'h00;
        uart_trigger = 1'b0;

        #2;

        wait (uart_tx_ready);

        #8;

        $display("+++All good");
        $finish;
    end

    always @ (negedge uart_clock) begin
        $display("LOOPBACK: %d TX %d: RX: %d TX_READY: %d RX_READY_SET: %d READ_DATA: %x", uart_loopback, uart_tx, uart_rx, uart_tx_ready, uart_rx_ready_set, uart_read_data);
    end
endmodule
