module ReadAddressFormer
#(
    parameter ADDR_W = 32,
    parameter DATA_W = 32,
    parameter MAX_BURST_LEN = 255 // number data samples with width == DATA_W 
) (
    input   logic                   clk_i,
    input   logic                   rst_i,

    input   logic   [ADDR_W-1:0]    base_addr_i,
    input   logic   [ADDR_W-1:0]    stride_i,
    input   logic   [ADDR_W-1:0]    vsize_i,    // number of lines - 1
    input   logic   [ADDR_W-1:0]    hsize_i,    // number data samples with width == DATA_W 

    input   logic                   start_i,

    input   logic                   ready_i,
    output  logic                   valid_o,
    output  logic   [ADDR_W-1:0]    even_addr_o,
    output  logic   [ADDR_W-1:0]    odd_addr_o,
    output  logic   [ 7:0]          len_o
);
    // TODO: implement line address forming without mult

    localparam EXPAND_TYPE = "forward";
    typedef logic [ADDR_W-1:0] addr_t;

    logic  start_reg, start, busy;
    always_ff @(posedge clk_i) start_reg <= start_i;
    assign start = !start_reg & start_i & !busy;

    addr_t stride;
    addr_t base;
    always_ff @(posedge clk_i) begin
        if (start) begin
            stride <= stride_i;
            base <= base_addr_i;
        end
    end 

    // Line number former signals
    logic                   new_frame; 
    logic                   line_num_ready;
    logic                   line_num_valid;
    logic   [ADDR_W-1:0]    even_line_num;
    logic   [ADDR_W-1:0]    odd_line_num;
    logic                   last_line;
    // In line offset former signals
    logic                   new_line;
    logic   [ADDR_W-1:0]    offset;
    logic   [ 7:0]          burst_len;
    logic                   offset_valid;
    logic                   last_offset;
    logic                   offset_ready;

    // addr = base_addr_i + (even_cnt * hsize_i) + line_offset
    // assign even_addr_o = (base + offset) + (even_line_num * stride);
    // assign odd_addr_o  = (base + offset) + (odd_line_num  * stride);

    assign new_frame = start;
    assign new_line = line_num_ready & line_num_valid;

    addr_t current_even_line_addr;
    addr_t current_odd_line_addr;

    always_ff @(posedge clk_i) begin
        if (new_line) begin
            current_even_line_addr <= even_line_num * stride;
            current_odd_line_addr <= odd_line_num * stride;
        end
    end

    LineNumberFormer #(
        .ADDR_W(32),
        .EXPAND_TYPE(EXPAND_TYPE)
    ) LineNumberFormerInst (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .new_frame_i(new_frame), 
        .vsize_i(vsize_i),
        .ready_i(line_num_ready),
        .valid_o(line_num_valid),
        .even_line_num_o(even_line_num),
        .odd_line_num_o(odd_line_num),
        .last_line_o(last_line)
    );

    InLineOffsetFormer #(
        .ADDR_W(ADDR_W),
        .DATA_W(DATA_W),
        .MAX_BURST_LEN(MAX_BURST_LEN)
    ) InLineOffsetFormerInst (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .new_line_i(new_line),
        .line_size_i(hsize_i),
        .offset_o(offset),
        .burst_len_o(burst_len),
        .valid_o(offset_valid),
        .last_o(last_offset),
        .ready_i(offset_ready)
    );

endmodule