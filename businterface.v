`include "businterface.vh"

module businterface
    (
        input       [31:0] cpu_address,
        input       [1:0] cpu_cycle_width,
        input       [31:0] cpu_data_out,
        output reg  [31:0] cpu_data_in,
        input       cpu_read, cpu_write,

        output reg  [31:2] businterface_address,
        input       [31:0] businterface_data_in,
        output reg  [31:0] businterface_data_out,
        output reg  [3:0] businterface_data_strobes,
        output reg  businterface_bus_error,
        output reg  businterface_read, businterface_write
    );

    always @ (*) begin
        // assume there is an error state
        businterface_bus_error = 1'b1;
        businterface_address = cpu_address[31:2];
        businterface_data_strobes = 4'b0000;
        cpu_data_in = 32'hffffffff;
        businterface_data_out = 32'hffffffff;

        case (cpu_cycle_width)
            CW_BYTE: begin
                // byte operations can't be unaligned
                businterface_bus_error = 1'b0;
                case (cpu_address[1:0])
                    2'b00: begin
                        businterface_data_strobes = 4'b1000;
                        businterface_data_out = { cpu_data_out[7:0], 8'hff, 8'hff, 8'hff };
                        cpu_data_in = { 8'hff, 8'hff, 8'hff,  businterface_data_in[31:24] };
                    end
                    2'b01: begin
                        businterface_data_strobes = 4'b0100;
                        businterface_data_out = { 8'hff, cpu_data_out[7:0], 8'hff, 8'hff };
                        cpu_data_in = { 8'hff, 8'hff, 8'hff,  businterface_data_in[23:16] };
                    end
                    2'b10: begin
                        businterface_data_strobes = 4'b0010;
                        businterface_data_out = { 8'hff, 8'hff, cpu_data_out[7:0], 8'hff };
                        cpu_data_in = { 8'hff, 8'hff, 8'hff,  businterface_data_in[15:8] };
                    end
                    2'b11: begin
                        businterface_data_strobes = 4'b0001;
                        businterface_data_out = { 8'hff, 8'hff, 8'hff, cpu_data_out[7:0] };
                        cpu_data_in = { 8'hff, 8'hff, 8'hff,  businterface_data_in[7:0] };
                    end
                endcase
            end
            CW_WORD: begin
                case (cpu_address[1:0])
                    2'b00: begin
                        businterface_bus_error = 1'b0;
                        businterface_data_strobes = 4'b1100;
                        businterface_data_out = { cpu_data_out[15:0], 16'hffff };
                        cpu_data_in = { 16'hffff,  businterface_data_in[31:16] };
                    end
                    2'b01: begin
                    end
                    2'b10: begin
                        businterface_bus_error = 1'b0;
                        businterface_data_strobes = 4'b0011;
                        businterface_data_out = { 16'hffff, cpu_data_out[15:0] };
                        cpu_data_in = { 16'hffff, businterface_data_in[15:0] };
                    end
                    2'b11: begin
                    end
                endcase
            end
            CW_LONG: begin
                case (cpu_address[1:0])
                    2'b00: begin
                        businterface_bus_error = 1'b0;
                        businterface_data_strobes = 4'b1111;
                        businterface_data_out = cpu_data_out;
                        cpu_data_in = businterface_data_in;
                    end
                    2'b01: begin
                    end
                    2'b10: begin
                    end
                    2'b11: begin
                    end
                endcase
            end
            CW_NULL: begin
            end
        endcase

        // could short these in the upper level, but will need them when multi-
        // cycle operation is implemented
        businterface_read = cpu_read;
        businterface_write = cpu_write;
    end
endmodule
