module map_ram
    (
        input a_clock,
        input a_read,
        input [4:0] a_row_index, // 32
        input [4:0] a_col_index, // by 32
        output reg [7:0] a_out,
        input b_clock,
        input b_cs,
        input b_read,
        input b_write,
        input [4:0] b_row_index, // 32
        input [4:0] b_col_index, // by 32
        input [7:0] b_in,
        output reg [7:0] b_out
    );

    reg [7:0] a_map_mem [32*32];
    reg [7:0] b_map_mem [32*32];

    always @ (posedge a_clock) begin
        if (a_read) begin
            a_out <= a_map_mem[{a_row_index, a_col_index}]; // Output register controlled by clock.
        end
    end

    always @ (negedge b_clock) begin
        if (b_cs) begin
            if (b_read) begin
                b_out <= b_map_mem[{b_row_index, b_col_index}];
            end
            if (b_write) begin
                a_map_mem[{b_row_index, b_col_index}] <= b_in;
                b_map_mem[{b_row_index, b_col_index}] <= b_in;
            end
        end
    end

    initial begin
        $readmemh("map.txt", a_map_mem);
        $readmemh("map.txt", b_map_mem);
    end
endmodule


module status_ram
    (
        input a_clock,
        input a_read,
        input [4:0] a_col_index, // by 32
        output reg [7:0] a_out,
        input b_clock,
        input b_cs,
        input b_write,
        input [4:0] b_col_index, // by 32
        input [7:0] b_in
    );

    (* ram_style = "logic" *)
    reg [7:0] status_mem [32];

    always @ (posedge a_clock) begin
        if (a_read) begin
            a_out <= status_mem[a_col_index]; // Output register controlled by clock.
        end
    end

    always @ (negedge b_clock) begin
        if (b_cs) begin
            if (b_write) begin
                status_mem[b_col_index] <= b_in;
            end
        end
    end
endmodule

