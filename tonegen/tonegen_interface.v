module tonegen_interface
    (
        input reset,
        input clock,

        input read,
        input write,
        input duration_cs,
        input period_cs,
        input status_cs,
        input [31:0] data_in,
        output reg [31:0] data_out,
        output reg data_out_valid,

        output buzzer
    );

    reg [31:0] duration = 32'h0;
    reg [31:0] period = 32'h0;
    reg tone_start;
    wire playing;

    always @ (posedge clock) begin
        if (reset) begin
            duration <= 32'h0;
            period <= 32'h0;
            tone_start <= 1'b0;
        end else begin
            tone_start <= 1'b0;
            if (write) begin
                if (duration_cs) begin
                    duration <= { data_in[23:0], 8'h00 };
                    tone_start <= 1'b1;
                end

                if (period_cs) begin
                    period <= data_in;
                end
            end
        end
    end

    always @ (*) begin
        if (status_cs) begin
            data_out = { playing, 7'b0, 24'h0000000 };
        end else begin
            data_out = { 32'h0 };
        end
    end

    assign data_out_valid = read && status_cs ? 1'b1 : 1'b0;

    tonegen tonegen (
        .reset(reset),
        .clock(clock),
        .duration(duration),
        .period(period),
        .tone_start(tone_start),
        .buzzer(buzzer),
        .playing(playing)
    );
endmodule