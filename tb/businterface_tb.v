`include "businterface.vh"

module businterface_tb;
    `define TB_NO_CLOCK 1
    `include "tests.vh" // For period only

    reg [31:0] cpu_address;
    t_cycle_width cpu_cycle_width;
    reg [31:0] cpu_data_out;
    wire [31:0] cpu_data_in;
    reg cpu_read, cpu_write;

    wire [31:2] businterface_address;
    reg [31:0] businterface_data_in;
    wire [31:0] businterface_data_out;
    wire [3:0] businterface_data_strobes;
    wire businterface_bus_error;
    wire businterface_read, businterface_write;

    businterface dut (
        .cpu_address(cpu_address),
        .cpu_cycle_width(cpu_cycle_width),
        .cpu_data_out(cpu_data_out),
        .cpu_data_in(cpu_data_in),
        .cpu_read(cpu_read), .cpu_write(cpu_write),

        .businterface_address(businterface_address),
        .businterface_data_in(businterface_data_in),
        .businterface_data_out(businterface_data_out),
        .businterface_data_strobes(businterface_data_strobes),
        .businterface_bus_error(businterface_bus_error),
        .businterface_read(businterface_read), .businterface_write(businterface_write)
    );

    task run_test
        (
            input [31:0] test_cpu_address,
            input t_cycle_width test_cpu_cycle_width,
            input [31:0] test_cpu_data_out,
            input test_cpu_read, test_cpu_write,
            input [31:0] test_businterface_data_in,

            input [31:0] exp_cpu_data_in,
            input [31:0] exp_businterface_address,
            input [31:0] exp_businterface_data_out,
            input [3:0] exp_businterface_data_strobes,
            input exp_businterface_bus_error,
            input exp_businterface_read, exp_businterface_write
        );
        begin
            cpu_address = test_cpu_address;
            cpu_cycle_width = test_cpu_cycle_width;
            cpu_data_out = test_cpu_data_out;
            cpu_read = test_cpu_read;
            cpu_write = test_cpu_write;
            businterface_data_in = test_businterface_data_in;

            #period

            $display("CPU address: %08x CPU cycle width: %02b CPU data out: %08x CPU read: %d CPU write: %d BusInterface data in: %08x",
                test_cpu_address, test_cpu_cycle_width, test_cpu_data_out, test_cpu_read, test_cpu_write, test_businterface_data_in);

            if (businterface_bus_error !== exp_businterface_bus_error) begin
                $display("BusInterface error got %d, expected %d", businterface_bus_error, exp_businterface_bus_error); $fatal;
            end
            if (businterface_bus_error === 1'b0) begin
                if (cpu_data_in !== exp_cpu_data_in) begin
                    $display("CPU data in got %08x, expected %08x", cpu_data_in, exp_cpu_data_in); $fatal;
                end
                if (businterface_address !== exp_businterface_address[31:2]) begin
                    $display("BusInterface address got %08x, expected %08x",
                        businterface_address, exp_businterface_address); $fatal;
                end
                if (businterface_data_out !== exp_businterface_data_out) begin
                    $display("BusInterface data out got %08x, expected %08x",
                        businterface_data_out, exp_businterface_data_out); $fatal;
                end
                if (businterface_data_strobes !== exp_businterface_data_strobes) begin
                    $display("BusInterface data strobes got %08x, expected %08x",
                        businterface_data_strobes, exp_businterface_data_strobes); $fatal;
                end
                if (businterface_read !== exp_businterface_read) begin
                    $display("BusInterface read got %08x, expected %08x", businterface_read, exp_businterface_read); $fatal;
                end
                if (businterface_write !== exp_businterface_write) begin
                    $display("BusInterface write got %08x, expected %08x", businterface_write, exp_businterface_write); $fatal;
                end
            end
        end
    endtask

    initial begin
        run_test(32'h00000000, CW_BYTE, 32'h000000ab, 1'b1, 1'b0, 32'h12345678,
            32'hffffff12, 32'h00000000, 32'habffffff, 4'b1000, 1'b0, 1'b1, 1'b0);
        run_test(32'h00000001, CW_BYTE, 32'h000000ab, 1'b1, 1'b0, 32'h12345678,
            32'hffffff34, 32'h00000000, 32'hffabffff, 4'b0100, 1'b0, 1'b1, 1'b0);
        run_test(32'h00000002, CW_BYTE, 32'h000000ab, 1'b1, 1'b0, 32'h12345678,
            32'hffffff56, 32'h00000000, 32'hffffabff, 4'b0010, 1'b0, 1'b1, 1'b0);
        run_test(32'h00000003, CW_BYTE, 32'h000000ab, 1'b1, 1'b0, 32'h12345678,
            32'hffffff78, 32'h00000000, 32'hffffffab, 4'b0001, 1'b0, 1'b1, 1'b0);

        run_test(32'h00000000, CW_WORD, 32'h0000abcd, 1'b1, 1'b0, 32'h12345678,
            32'hffff1234, 32'h00000000, 32'habcdffff, 4'b1100, 1'b0, 1'b1, 1'b0);
        run_test(32'h00000002, CW_WORD, 32'h0000abcd, 1'b1, 1'b0, 32'h12345678,
            32'hffff5678, 32'h00000000, 32'hffffabcd, 4'b0011, 1'b0, 1'b1, 1'b0);

        run_test(32'h00000000, CW_LONG, 32'habcdef12, 1'b1, 1'b0, 32'h12345678,
            32'h12345678, 32'h00000000, 32'habcdef12, 4'b1111, 1'b0, 1'b1, 1'b0);

        run_test(32'h00000001, CW_WORD, 32'h12345678, 1'b1, 1'b0, 32'h12345678,
            32'h12345678, 32'h00000000, 32'hffffabcd, 4'b0011, 1'b1, 1'b1, 1'b0);
        run_test(32'h00000003, CW_WORD, 32'h12345678, 1'b1, 1'b0, 32'h12345678,
            32'h12345678, 32'h00000000, 32'hffffabcd, 4'b0011, 1'b1, 1'b1, 1'b0);
        run_test(32'h00000001, CW_LONG, 32'habcdef12, 1'b1, 1'b0, 32'h12345678,
            32'h12345678, 32'h00000000, 32'habcdef12, 4'b1111, 1'b1, 1'b1, 1'b0);
        run_test(32'h00000002, CW_LONG, 32'habcdef12, 1'b1, 1'b0, 32'h12345678,
            32'h12345678, 32'h00000000, 32'habcdef12, 4'b1111, 1'b1, 1'b1, 1'b0);
        run_test(32'h00000003, CW_LONG, 32'habcdef12, 1'b1, 1'b0, 32'h12345678,
            32'h12345678, 32'h00000000, 32'habcdef12, 4'b1111, 1'b1, 1'b1, 1'b0);
    end
endmodule