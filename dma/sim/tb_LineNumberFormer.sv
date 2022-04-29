module tb_LineNumberFormer ();
    parameter ADDR_W = 32;
    parameter EXPAND_TYPE = "forward";
    // parameter EXPAND_TYPE = "backward";
    
    logic                   clk_i;
    logic                   rst_i;
    logic                   new_frame_i; 
    logic   [ADDR_W-1:0]    vsize_i;    // number of lines - 1
    logic                   ready_i;
    logic                   valid_o;
    logic   [ADDR_W-1:0]    even_line_num_o;
    logic   [ADDR_W-1:0]    odd_line_num_o;
    logic                   last_line_o;

    logic                   last;
    logic   [ADDR_W-1:0]    even, odd;
    always @(posedge clk_i) begin
        if (new_frame_i) begin
            last <= 0;
            even <= 0;
            odd <= 0;
        end else if (valid_o && ready_i) begin
            last <= last_line_o;
            even <= even_line_num_o;
            odd <= odd_line_num_o;
        end
    end

    always #5 clk_i <= ~clk_i;
    `define WAIT_UNTIL(signal) while ((signal)) @(posedge clk_i);
    `define WAIT_CLOCKS(N) for (int i = 0; i < (N); i++) @(posedge clk_i);

    initial begin
        clk_i = 1;
        rst_i = 1;
        ready_i = 0;
        new_frame_i = 0;
        @(posedge clk_i);
        @(posedge clk_i);
        rst_i = 0;
        @(posedge clk_i);

        vsize_i = 16    -1;
        new_frame_i = 1;
        @(posedge clk_i);
        new_frame_i = 0;

        for (int i = 0; i < 20; i++) begin
            // @(posedge clk_i);
            // @(posedge clk_i);
            ready_i = 1;
            // @(posedge clk_i);
            // ready_i = 0;            
        end

        for (int i = 0; i < 25; i++) @(posedge clk_i);
        new_frame_i = 1;
        @(posedge clk_i);
        new_frame_i = 0;
    end

    LineNumberFormer #(
        .ADDR_W(ADDR_W),
        .EXPAND_TYPE(EXPAND_TYPE)
    ) DUT (
        .*
    );

endmodule
