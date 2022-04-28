module InLineOffsetFormer 
#(
    parameter ADDR_W = 32,
    parameter DATA_W = 64,        // must be pow of 2
    parameter MAX_BURST_LEN = 255 // number data samples with width == DATA_W 
) (
    input   logic                   clk_i,
    input   logic                   rst_i,

    input   logic                   new_line_i,     // duratio = 1 clock 
    input   logic   [ADDR_W-1:0]    line_size_i,

    output  logic   [ADDR_W-1:0]    offset_o,
    output  logic   [ 7:0]          burst_len_o,
    output  logic                   valid_o,
    output  logic                   last_o,
    input   logic                   ready_i
);
    // burst_len =  min(left_in_line, MAX_BURST_LEN);
    // offset = (offset + (burst_len + 1) << BYTES_PER_CYCLE);
    // left_in_line = left_in_line - (burst_len + 1);

    localparam BYTES_PER_CYCLE = DATA_W / 8;

    typedef logic [ADDR_W-1:0] addr_t;
    typedef logic [7:0] burst_len_t;

    addr_t      left_in_line;
    addr_t      curr_offset;
    burst_len_t burst_len;
    
    logic       valid_left;
    logic       valid_burst_len;
    logic       valid_offset;

    assign valid_o = valid_left && valid_burst_len && valid_offset;

    logic next_offset;

    /// left in line calc
    always_ff @(posedge clk_i) begin
        if (new_line_i) begin
            valid_left <= 1;
        end else if (next_offset) begin
            valid_left <= 1;
        end else if (ready_i && valid_o) begin
            valid_left <= 0;
        end
    end

    always_ff @(posedge clk_i) begin
        if (new_line_i) begin
            left_in_line <= line_size_i;
        end else if (next_offset) begin
            left_in_line <= left_in_line - burst_len - 1;
        end
    end

    // burst_len calc
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            valid_burst_len <= 0;
        end else if (valid_left & !valid_burst_len) begin
            valid_burst_len <= 1;
        end else if (ready_i && valid_o) begin
            valid_burst_len <= 0;
        end
    end

    burst_len_t next_burst_len;
    logic       last_in_line;
    assign last_in_line = (left_in_line <= (MAX_BURST_LEN + 1));
    assign next_burst_len = last_in_line ?  left_in_line : MAX_BURST_LEN;

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            burst_len <= 0;
            last_o <= 0;
        end else if (valid_left & !valid_burst_len) begin
            burst_len <= next_burst_len;
            last_o <= last_in_line;
        end
    end

    assign burst_len_o = burst_len;

    // offset_calc
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            valid_offset <= 0;
        end else if (new_line_i) begin
            valid_offset <= 1;
        end else if (!valid_offset) begin
            valid_offset <= 1;
        end else if (ready_i && valid_o) begin
            valid_offset <= 0;
        end
    end

    always_ff @(posedge clk_i) begin
        if (new_line_i) begin
            curr_offset <= 0;
        end else if (!valid_offset) begin
            curr_offset <= curr_offset + ((burst_len + 1) << $clog2(BYTES_PER_CYCLE));
        end
    end

    assign offset_o = curr_offset;

    //
    // always_ff @(posedge clk_i) begin
    //     next_offset <= valid_o & ready_i & !last_in_line;
    // end
    assign next_offset = valid_o & ready_i & !last_in_line;

endmodule
