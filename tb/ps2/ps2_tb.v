// Testbench for the PS/2 controller modules defined in ps2.v.
// The focus is on generating a VCD waveform file that can be
// viewed with a waveform viewer such as GTKWave.
module ps2_tb;

    // Clock for the internal logic of the controller.
    reg clock;
    // PS/2 clock line that drives the edge finder.
    reg ps2_clock;
    // PS/2 data line.
    reg ps2_data;

    // Wires to connect to the modules.
    wire edge_found;
    wire [7:0] rx_scancode;
    wire scancode_ready_set;
    wire parity_error;

    // Local variables for stimulus generation.
    reg [7:0] scancode;
    reg parity;

    // Instantiate the edge finder.
    ps2_edge_finder edge_finder_inst (
        .clock(clock),
        .edge_found(edge_found),
        .ps2_clock(ps2_clock)
    );

    // Instantiate the receiver shifter.
    ps2_rx_shifter rx_shifter_inst (
        .clock(clock),
        .edge_found(edge_found),
        .rx_scancode(rx_scancode),
        .scancode_ready_set(scancode_ready_set),
        .parity_error(parity_error),
        .ps2_data(ps2_data)
    );

    // Generate a 10‑ns period clock for the internal logic.
    initial clock = 0;
    always #5 clock = ~clock;

    // Generate a 10‑ns period PS/2 clock.  The data is valid on the
    // falling edge of this clock.
    initial ps2_clock = 1;
    always #5 ps2_clock = ~ps2_clock;

    // Inline logic for sending a single bit on the PS/2 data line.
    // The bit is driven for a full PS/2 clock period.
    // The receiver samples on the falling edge.
    // This block is used directly in the stimulus section.

    // Monitor for debugging.
    initial begin
        $dumpfile("ps2_tb.vcd");
        $dumpvars(0, ps2_tb);
        $monitor("%0t: scancode_ready=%b, scancode=0x%h, parity_error=%b", $time, scancode_ready_set, rx_scancode, parity_error);
    end

    integer i;

    // Stimulus: send a correct scancode followed by one with a parity error.
    initial begin
        // Wait for a few clock cycles to allow modules to reset.
        #100;
        // ---------- Correct scancode 0x1c ("A" key) ----------
        parity = ^scancode; // odd parity
        // Start bit
        ps2_data = 1'b0; #5; #5;
        // Data bits LSB first
        for (i = 0; i < 8; i = i + 1) begin
            ps2_data = scancode[i]; #5; #5;
        end
        // Parity bit
        ps2_data = parity; #5; #5;
        // Stop bit
        ps2_data = 1'b1; #5; #5;
        // Wait for the receiver to process the first byte.
        #200;

        // ---------- Scancode with parity error (flip parity bit) ----------
        scancode = 8'h2A; // arbitrary value
        parity = ^scancode; // correct parity
        // Flip parity to create error
        parity = ~parity;
        // Start bit
        ps2_data = 1'b0; #5; #5;
        // Data bits LSB first
        for (i = 0; i < 8; i = i + 1) begin
            ps2_data = scancode[i]; #5; #5;
        end
        // Parity bit (incorrect)
        ps2_data = parity; #5; #5;
        // Stop bit
        ps2_data = 1'b1; #5; #5;
        // Wait for the receiver to process the second byte.
        #200;
        $finish;
    end

endmodule
