module addr_decode
    (
        input [31:2] address,

        // Memory selects
        output reg memory_cs,
        output reg map_cs,
        output reg status_cs,
        output reg levels_cs, // This is the EEPROM source data

        // IO selects
        output reg led_cs,
        output reg ps2_status_cs,
        output reg ps2_scancode_cs,
        output reg tonegen_duration_cs,
        output reg tonegen_period_cs,
        output reg tonegen_status_cs,
        output reg scroll_cs,
        output reg i2c_address_cs,
        output reg i2c_read_cs,
        output reg i2c_write_cs,
        output reg i2c_control_cs,
        output reg uart_status_cs,
        output reg uart_data_cs
    );

    // High byte: the device "class", Low byte: used to select IO device registers
    wire [7:0] high_byte_address = address[31:24];
    wire [7:0] low_byte_address = { address[7:2], 2'b00 };

    always @ (*) begin
        memory_cs = 1'b0;
        map_cs = 1'b0;
        status_cs = 1'b0;
        levels_cs = 1'b0;
        led_cs = 1'b0;
        ps2_status_cs = 1'b0;
        ps2_scancode_cs = 1'b0;
        tonegen_duration_cs = 1'b0;
        tonegen_period_cs = 1'b0;
        tonegen_status_cs = 1'b0;
        scroll_cs = 1'b0;
        i2c_address_cs = 1'b0;
        i2c_read_cs = 1'b0;
        i2c_write_cs = 1'b0;
        i2c_control_cs = 1'b0;
        uart_status_cs = 1'b0;
        uart_data_cs = 1'b0;

        case (high_byte_address)
            8'h00: memory_cs = 1'b1;    // Program RAM
            8'h01: map_cs = 1'b1;       // Map RAM
            8'h02: status_cs = 1'b1;    // Status map RAM
            8'h03: levels_cs = 1'b1;    // 8 levels used for I2C EEPROM programming
            8'h0f: begin
                // IO devices
                case (low_byte_address)
                    8'h00: led_cs = 1'b1;
                    8'h04: ps2_status_cs = 1'b1;
                    8'h08: ps2_scancode_cs = 1'b1;
                    8'h0c: tonegen_duration_cs = 1'b1;
                    8'h10: tonegen_period_cs = 1'b1;
                    8'h14: tonegen_status_cs = 1'b1;
                    8'h18: scroll_cs = 1'b1;
                    8'h1c: i2c_address_cs = 1'b1;
                    8'h20: i2c_read_cs = 1'b1;
                    8'h24: i2c_write_cs = 1'b1;
                    8'h28: i2c_control_cs = 1'b1;
                    8'h2c: uart_status_cs = 1'b1;
                    8'h30: uart_data_cs = 1'b1;
                    default: begin
                    end
                endcase
            end
            default: begin
            end
        endcase
    end
endmodule

module data_in_mux
    (
        input memory_cs,
        input [31:0] ram_data_out,
        input map_cs,
        input [31:0] map_data_out,
        input levels_cs,
        input [31:0] levels_data_out,

        input ps2_data_out_valid,
        input [31:0] ps2_data_out,
        input tonegen_data_out_valid,
        input [31:0] tonegen_data_out,
        input i2c_data_out_valid,
        input [31:0] i2c_data_out,
        input uart_data_out_valid,
        input [31:0] uart_data_out,

        output reg [31:0] data_in
    );

    always @ (*)  begin
        if (memory_cs) begin
            data_in = ram_data_out;
        end else if (map_cs) begin
            data_in = map_data_out;
        end else if (levels_cs) begin
            data_in = levels_data_out;
        end else if (ps2_data_out_valid) begin
            data_in = ps2_data_out;
        end else if (tonegen_data_out_valid) begin
            data_in = tonegen_data_out;
        end else if (i2c_data_out_valid) begin
            data_in = i2c_data_out;
        end else if (uart_data_out_valid) begin
            data_in = uart_data_out;
        end else begin
            data_in = 32'h0;
        end
    end
endmodule

module reset_gen
    (
        input clock,
        output reg reset
    );

    reg [7:0] reset_counter = 8'h00;
    always @ (posedge clock) begin
        if (reset_counter != 8'hff) begin
            reset <= 1'b1;
            reset_counter <= reset_counter + 8'h01;
        end else begin
            reset <= 1'b0;
        end
    end
endmodule
