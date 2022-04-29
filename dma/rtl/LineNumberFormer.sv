module LineNumberFormer 
#(
    parameter ADDR_W = 32,
    parameter EXPAND_TYPE = "forward" // "backward"
) (
    input   logic                   clk_i,
    input   logic                   rst_i,

    input   logic                   new_frame_i, 
    input   logic   [ADDR_W-1:0]    vsize_i,    // number of lines - 1
    
    input   logic                   ready_i,
    output  logic                   valid_o,
    output  logic   [ADDR_W-1:0]    even_line_num_o,
    output  logic   [ADDR_W-1:0]    odd_line_num_o,
    output  logic                   last_line_o
);
    localparam EXPAND_SIZE = (EXPAND_TYPE == "forward") ? 4 : 5;

    typedef logic [ADDR_W-1:0] addr_t;
    typedef enum { Idle, ExpandUp, Normal, ExpandDown } state_t;
    state_t state, next_state;

    addr_t vsize;
    addr_t last_line_num;
    addr_t even_cnt, odd_cnt;
    logic  next_addr;

    assign next_addr = valid_o && ready_i;

    always_ff @(posedge clk_i) begin
        if (new_frame_i) begin
            vsize <= vsize_i - 1;
            last_line_num <= vsize_i - EXPAND_SIZE + 1;
        end
    end

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            state = Idle;
        end else if (next_addr | new_frame_i) begin
            state <= next_state;
        end
    end

    always_comb begin
        case (state)
            Idle: begin
                next_state = new_frame_i ? ExpandUp : Idle;
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
        if (new_frame_i) begin
            even_cnt <= EXPAND_SIZE;
            odd_cnt  <= EXPAND_SIZE-1;
        end else if (next_addr) begin
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

    assign even_line_num_o = even_cnt;
    assign odd_line_num_o = odd_cnt;
    
    assign valid_o = (state != Idle);
    assign last_line_o = (state == ExpandDown) && (next_state == Idle);

endmodule