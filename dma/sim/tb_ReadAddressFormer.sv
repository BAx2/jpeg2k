module tb_ReadAddressFormer ();

    parameter ADDR_W = 32;
    parameter MAX_BURST_LEN = 15; // number data samples with width == DATA_W 
    parameter EXPAND_SIZE = 4;

    logic                   clk_i;
    logic                   rst_i;
    logic   [ADDR_W-1:0]    base_addr_i;
    logic   [ADDR_W-1:0]    stride_i;
    logic   [ADDR_W-1:0]    vsize_i;    // number of lines - 1
    logic   [ADDR_W-1:0]    hsize_i;    // number data samples with width == DATA_W 
    logic                   start_i;
    logic                   ready_i;
    logic                   valid_o;
    logic   [ADDR_W-1:0]    even_addr_o;
    logic   [ADDR_W-1:0]    odd_addr_o;
    logic   [ 7:0]          len_o;

    always #5 clk_i <= ~clk_i;
    `define WAIT_UNTIL(signal) while ((signal)) @(posedge clk_i);
    `define WAIT_CLOCKS(N) for (int i = 0; i < (N); i++) @(posedge clk_i);

    initial begin
        clk_i = 1;
        rst_i = 1;
        ready_i = 0;
        start_i = 0;
        @(posedge clk_i);
        @(posedge clk_i);
        rst_i = 0;
        @(posedge clk_i);

        base_addr_i = 'h1000;
        stride_i = 'h100;
        vsize_i = 16    -1;
        hsize_i = 'h80  -1;
        start_i = 1;
        @(posedge clk_i);
        start_i = 0;

    end

    ReadAddressFormer #(
        .ADDR_W(ADDR_W),
        .MAX_BURST_LEN(MAX_BURST_LEN) // number data samples with width == DATA_W 
    ) DUT (
        .*
    );
endmodule
