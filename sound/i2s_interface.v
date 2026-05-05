module i2s_interface
    (
        input       reset,
        input       clock,

        input       read,
        input       write,
        input       data_cs,
        input       status_cs,
        input       [31:0] data_in,
        output reg  [31:0] data_out,
        output reg  data_out_valid,

        output      lrclk,
        output      bclk,
        output      sd
    );

    reg trigger;
	reg [31:0] data;
	reg running;
    reg new_data;

    always @ (*) begin
        if (status_cs) begin
            data_out = { new_data, 7'b0000000, 24'h000000 };
        end else begin
            data_out = 32'h0;
        end
    end

    assign data_out_valid = read && status_cs ? 1'b1 : 1'b0;

    always @ (posedge clock) begin
        if (reset) begin
            new_data <= 1'b0;
        end

        if (write) begin
            if (data_cs) begin
                data <= data_in;
                new_data <= 1'b1;
            end
        end

        trigger <= 1'b0;

        if (new_data) begin
            if (!running) begin
                trigger <= 1'b1;
                new_data <= 1'b0;
            end
        end
    end

    i2s i2s
    (
        .reset(reset),
        .clock(clock),

        .data(data),
        .trigger(trigger),
        .running(running),

        .lrclk(lrclk),
        .bclk(bclk),
        .sd(sd)
    );
endmodule
