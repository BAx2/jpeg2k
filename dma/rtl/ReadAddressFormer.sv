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
    localparam EXPAND_SIZE = 4;

    typedef logic [ADDR_W-1:0] addr_t;

    // localparam EXPAND_SIZE = 4;
    //                       e o e o e o e o e o       e   o   e   o   e   o
    //          for forward: 4 3 2 1 0 1 2 3 4 5 ... N-2 N-1 N-2 N-3 N-4 N-5
    addr_t vsize;
    addr_t hsize;
    addr_t stride;

    addr_t even_cnt, odd_cnt;
    addr_t last_line_num;
    addr_t line_addr;
    addr_t line_offset;

    always_ff @(posedge clk_i) begin
        if (start_i) begin
            vsize <= vsize_i - 1;
            hsize <= hsize_i;
            stride <= stride_i;
            last_line_num <= vsize_i - EXPAND_SIZE + 1;
        end
    end 

    // addr = base_addr_i + (even_cnt * hsize_i) + line_offset
    assign line_addr = base_addr_i + (even_cnt * stride);
    assign even_addr_o = line_addr + line_offset;

    logic next_line;
    logic next_addr;
    assign next_addr = ready_i & valid_o;

    typedef enum { Idle, ExpandUp, Normal, ExpandDown } state_t;
    state_t state, next_state;

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            state = Idle;
        end else begin
            state <= next_state;
        end
    end

    always_comb begin
        case (state)
            Idle: begin
                next_state = start_i ? ExpandUp : Idle;
            end
            ExpandUp: begin
                next_state = (even_cnt == 0) ? Normal : ExpandUp;
            end
            Normal: begin
                next_state = (even_cnt == vsize) ? ExpandDown : Normal;
            end
            ExpandDown: begin
                next_state = (even_cnt == last_line_num) ? Idle : ExpandDown;
            end
            default: begin
                next_state = Idle;
            end 
        endcase
    end

    always_ff @(posedge clk_i) begin
        if (start_i) begin
            even_cnt <= EXPAND_SIZE;
            odd_cnt  <= EXPAND_SIZE-1;
        end else if ( /* next_addr & next_line */ 1) begin
            case (state)
                Idle: begin
                    even_cnt <= EXPAND_SIZE;
                    odd_cnt  <= EXPAND_SIZE-1;
                end
                ExpandUp: begin
                    even_cnt <= (even_cnt == 0) ? (even_cnt + 2) : (even_cnt - 2);
                    if (even_cnt == 2) begin
                        odd_cnt <= 1;    
                    end else if (even_cnt == 0) begin
                        odd_cnt <= 3;
                    end else begin
                        odd_cnt <= odd_cnt  - 2;
                    end
                end
                Normal: begin     
                    even_cnt <= (even_cnt == vsize) ? (even_cnt) : (even_cnt + 2);
                    odd_cnt  <= (even_cnt == vsize) ? (odd_cnt - 2) : (odd_cnt  + 2);
                end
                ExpandDown: begin 
                    even_cnt <= even_cnt - 2;
                    odd_cnt  <= odd_cnt  - 2;
                end
                default: begin    
                    even_cnt <= even_cnt;
                    odd_cnt  <= odd_cnt;
                end
            endcase
        end
    end


    logic                   new_line;
    logic   [ADDR_W-1:0]    line_size;
    logic   [ADDR_W-1:0]    offset;
    logic   [ 7:0]          burst_len;
    logic                   offset_valid;
    logic                   last_offset;
    logic                   offset_ready;

    InLineOffsetFormer #(
        .ADDR_W(ADDR_W),
        .DATA_W(DATA_W),
        .MAX_BURST_LEN(MAX_BURST_LEN)
    ) InLineOffsetFormerInst (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .new_line_i(new_line),
        .line_size_i(line_size),
        .offset_o(offset),
        .burst_len_o(burst_len),
        .valid_o(offset_valid),
        .last_o(last_offset),
        .ready_i(offset_ready)
    );

endmodule