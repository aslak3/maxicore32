module uart_interface
    (
        input reset,
        input clock,

        input read,
        input write,
        input data_cs,
        input status_cs,
        input [31:0] data_in,
        output reg [31:0] data_out,
        output reg data_out_valid,

        output tx,
        input rx
    );

    reg rx_ready = 1'b0;
    reg framing_error = 1'b0;

    always @ (posedge clock) begin
        if (reset == 1'b1) begin
            rx_ready <= 1'b0;
            framing_error <= 1'b0;
            trigger <= 1'b0;
        end else begin
            if (read == 1'b1) begin
                if (data_cs == 1'b1) begin
                    rx_ready <= 1'b0;
                    framing_error <= 1'b0;
                end
            end

            trigger <= 1'b0;
            if (write == 1'b1) begin
                if (data_cs == 1'b1) begin
                    write_data <= data_in[31:24];
                    trigger <= 1'b1;
                end
            end

            if (rx_ready_set == 1'b1) begin
                rx_ready <= 1'b1;
            end

            if (framing_error_set == 1'b1) begin
                framing_error <= 1'b1;
            end
        end
    end

    always @ (*) begin
        if (status_cs == 1'b1) begin
            data_out = { rx_ready, framing_error, tx_ready, 5'b00000, 24'h000000 };
        end else if (data_cs == 1'b1) begin
            data_out = { read_data, 24'h0000000 };
        end else begin
            data_out = { 32'h0 };
        end
    end

    assign data_out_valid = read && (status_cs || data_cs) ? 1'b1 : 1'b0;

    reg trigger;
    reg [7:0] write_data;
    reg [7:0] read_data;
    reg framing_error_set;
    reg tx_ready;
    reg rx_ready_set;

    uart #(
    )
    uart (
        .reset(reset),
        .clock(clock),

        .trigger(trigger),
        .write_data(write_data),
        .read_data(read_data),
        .framing_error_set(framing_error_set),
        .tx_ready(tx_ready),
        .rx_ready_set(rx_ready_set),
        .tx(tx),
        .rx(rx)
    );
endmodule
