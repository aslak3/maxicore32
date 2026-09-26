module sdram_controller_tb;
    reg clock;
    reg reset;

    reg cs;
    reg [31:2] address;
    reg [31:0] data_in;
    reg [31:0] data_out;
    reg [3:0] data_strobes;
    reg read, write;
    reg hold;

    reg [15:0] sdramd_in;
    reg [15:0] sdramd_out;
    reg [12:0] sdrama;
    reg [1:0] sdramba;
    reg n_sdramcs;
    reg sdramcke;
    reg sdramclk;
    reg sdramdqml;
    reg sdramdqmh;
    reg n_sdramwe;
    reg n_sdramras;
    reg n_sdramcas;

    reg [31:0] byte_address;

    sdram_controller #(
    )
    dut (
        .clock(clock),
        .reset(reset),

        .cs(cs),
        .address(address),
        .data_in(data_in),
        .data_out(data_out),
        .data_strobes(data_strobes),
        .read(read), .write(write),
        .hold(hold),

        .sdramd_in(sdramd_in),
        .sdramd_out(sdramd_out),
        .sdrama(sdrama),
        .sdramba(sdramba),
        .n_sdramcs(n_sdramcs),
        .sdramcke(sdramcke),
        .sdramclk(sdramclk),
        .sdramdqml(sdramdqml),
        .sdramdqmh(sdramdqmh),
        .n_sdramwe(n_sdramwe),
        .n_sdramras(n_sdramras),
        .n_sdramcas(n_sdramcas)
    );

    initial clock = 1'b0;

    always #1 clock = ~clock;

    initial begin
        $dumpfile("sdram.vcd");
        $dumpvars;

        // Reset sequence
        reset = 1'b1;

        #2;

        reset = 1'b0;

        #2;

        wait (hold == 1'b0);

        byte_address = 32'h12345678;
        address[31:2] = byte_address[31:2];
        data_in = 32'hdeadbeef;
        cs = 1'b1;
        write = 1'b1;

        wait (hold == 1'b1);

        cs = 1'b0;

        wait (hold == 1'b0);

        #2000;

        $display("+++All good");
        $finish;
    end

    always @ (negedge clock) begin
        $display("/CS: %d /RAS %d: /CAS %d HOLD: %d", n_sdramcs, n_sdramras, n_sdramcas, hold);
    end
endmodule
