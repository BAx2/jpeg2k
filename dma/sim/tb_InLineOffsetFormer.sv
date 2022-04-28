module tb_InLineOffsetFormer ();
    parameter ADDR_W = 32;
    parameter DATA_W = 64;        // must be pow of 2
    parameter MAX_BURST_LEN = 15; // number data samples with width == DATA_W 

    logic                   clk_i;
    logic                   rst_i;

    logic                   new_line_i;
    logic   [ADDR_W-1:0]    line_size_i;

    logic   [ADDR_W-1:0]    offset_o;
    logic   [ 7:0]          burst_len_o;
    logic                   valid_o;
    logic                   last_o;
    logic                   ready_i;

    always #5 clk_i <= ~clk_i;
    `define WAIT_UNTIL(signal) while ((signal)) @(posedge clk_i);
    `define WAIT_CLOCKS(N) for (int i = 0; i < (N); i++) @(posedge clk_i);

    initial begin
        clk_i = 1;
        rst_i = 1;
        new_line_i = 0;
        line_size_i = 0;
        ready_i = 1;

        @(posedge clk_i);
        @(posedge clk_i);
        rst_i = 0;
        @(posedge clk_i);
        @(posedge clk_i);

        line_size_i = 60-1;
        // burst_len : 15    15    15    11
        // DATA_W(8) :  0    16    32    48
        // DATA_W(64):  0   128   256   384

        new_line_i = 1;
        @(posedge clk_i);
        // new_line_i = 0;
        `WAIT_UNTIL(last_o == 0);
        
        ////////////////////////////////////////
        line_size_i = 30;
        `WAIT_CLOCKS(5);
        new_line_i = 1;
        @(posedge clk_i);
        new_line_i = 0;

        `WAIT_UNTIL(valid_o == 0);
        ready_i = 1;
        @(posedge clk_i);
        ready_i = 0;
        @(posedge clk_i);
        `WAIT_CLOCKS(5);

        `WAIT_UNTIL(valid_o == 0);
        ready_i = 1;
        @(posedge clk_i);
        ready_i = 0;
        @(posedge clk_i);
        `WAIT_CLOCKS(5);

        `WAIT_UNTIL(valid_o == 0);
        ready_i = 1;
        @(posedge clk_i);
        ready_i = 0;
        @(posedge clk_i);
        `WAIT_CLOCKS(5);

        `WAIT_UNTIL(valid_o == 0);
        ready_i = 1;
        @(posedge clk_i);
        ready_i = 0;
        @(posedge clk_i);
        `WAIT_CLOCKS(5);
    end

    InLineOffsetFormer #(
        .ADDR_W(ADDR_W),
        .DATA_W(DATA_W),       
        .MAX_BURST_LEN(MAX_BURST_LEN)
    ) DUT (
        .*
    );

endmodule
