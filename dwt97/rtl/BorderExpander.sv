module BorderExpander #(
    parameter     DataWidth  = 16,
    parameter bit EnableInputReg = 1
) (
    input   logic                                   clk_i,
    input   logic                                   rst_i,

    output  logic                                   s_ready_o,
    input   logic                                   s_valid_i,
    input   logic                                   s_sof_i,
    input   logic                                   s_eol_i,
    input   logic   [2*DataWidth-1:0]               s_data_i,

    input   logic                                   m_ready_i,
    output  logic                                   m_valid_o,
    output  logic                                   m_sof_o,
    output  logic                                   m_eol_o,
    output  logic   [2*DataWidth-1:0]               m_data_o
);
    localparam ExpandSize = 4;
    localparam BufferSize = ExpandSize + 1;

    typedef enum { 
        FillBuffer, // fill buffer (shift_en)
        ExpandLeft, // transmit data from buffer (delay from min to max delay)
        Normal,     // (max delay, shift_en)
        NearRight,  // tx from max to min
        ExpandRight // tx from min to max
    } state_t;
    state_t state, next_state;

    typedef struct packed {
        logic sof;
        logic eol;
        logic [2*DataWidth-1:0] data;
    } axis_t;

    axis_t s_axis_data;
    logic s_eol, s_sof, s_valid, s_ready;
    logic [2*DataWidth-1:0] s_data;
    
    axis_t m_axis_data;
    logic m_eol, m_sof, m_valid, m_ready;
    logic [2*DataWidth-1:0] m_data;

    logic new_in_sample;
    logic new_out_sample;

    assign new_in_sample = s_valid & s_ready,
           new_out_sample = m_valid & m_ready;
    
    logic                          buffer_we;
    logic [$clog2(BufferSize)-1:0] buff_addr;

    ShiftRegAddr #(
        .Width(2*DataWidth),
        .Depth(BufferSize)
    ) ShiftRegInst (
        .clk_i(clk_i),
        .en_i(buffer_we),
        .din_i(s_data),
        .addr_i(buff_addr),
        .dout_o(m_data)
    );

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            state <= FillBuffer;
        end else begin
            state <= next_state;
        end
    end

    logic [$clog2(BufferSize)-1:0] fill_cnt;
    logic [$clog2(BufferSize)-1:0] addr_cnt;
    logic need_sof;

    // sof
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            need_sof <= 0;
        end else begin
            if (new_in_sample & (state == FillBuffer) & fill_cnt == 0)
                need_sof <= s_sof;
            if (need_sof & new_out_sample & (state == ExpandLeft))
                need_sof <= 0;
        end
    end
    // store left border
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            fill_cnt <= 0;
        end else if (new_in_sample) begin
            if (state == FillBuffer) begin
                if (fill_cnt != ExpandSize) begin
                    fill_cnt <= fill_cnt + 1;
                end 
            end else begin
                fill_cnt <= 0;
            end
        end
    end
    // sh reg addr
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            addr_cnt <= 0;
        end else begin
            case (state)
                FillBuffer: begin
                    addr_cnt <= 0;
                end
                ExpandLeft: begin
                    if (new_out_sample)
                        addr_cnt <= addr_cnt + 1;
                end
                Normal:     begin
                    addr_cnt <= addr_cnt;
                end
                NearRight:  begin
                    if (new_out_sample) begin
                        if (addr_cnt != 0) begin
                            addr_cnt <= addr_cnt - 1;                    
                        end else begin
                            addr_cnt <= 1;
                        end
                    end
                end
                ExpandRight:begin
                    if (new_out_sample)
                        addr_cnt <= addr_cnt + 1;                    
                end
                default:    begin
                    addr_cnt <= addr_cnt;
                end
            endcase
        end
    end
    assign buff_addr = addr_cnt;
    // next state
    always_comb begin
        case (state)
            FillBuffer: begin
                if (fill_cnt == ExpandSize)
                    next_state = ExpandLeft;
                else
                    next_state = FillBuffer;
            end
            ExpandLeft: begin
                if ((addr_cnt == ExpandSize-1) & new_out_sample)
                    next_state = Normal;
                else
                    next_state = ExpandLeft;
            end
            Normal: begin
                if (s_eol & new_in_sample)
                    next_state = NearRight;
                else
                    next_state = Normal;
            end
            NearRight: begin
                if ((addr_cnt == 0) & new_out_sample)
                    next_state = ExpandRight;
                else
                    next_state = NearRight;
            end
            ExpandRight: begin
                if (addr_cnt == ExpandSize & new_out_sample)
                    next_state = FillBuffer;
                else
                    next_state = ExpandRight;
            end 
            default: begin
                next_state = FillBuffer;
            end 
        endcase
    end
    // s_ready m_ready buff_we
    always_comb
        case (state)
            FillBuffer: begin
                s_ready = 1;
                m_valid = 0;
                buffer_we = new_in_sample;
            end
            ExpandLeft: begin
                s_ready = 0;
                m_valid = 1;
                buffer_we = 0;
            end
            Normal: begin
                s_ready = m_ready;
                m_valid = s_valid;
                buffer_we = new_in_sample;
            end
            NearRight:  begin
                s_ready = 0;
                m_valid = 1;
                buffer_we = 0;
            end
            ExpandRight:    begin
                s_ready = 0;
                m_valid = 1;
                buffer_we = 0;
            end
            default:    begin
                s_ready = 0;
                buffer_we = 0;
                m_valid = 0;
            end
        endcase

    assign m_eol = (state == ExpandRight) & (addr_cnt == ExpandSize);
    assign m_sof = need_sof;

    AxisReg #(
        .DataWidth($bits(axis_t)),
        .Transperent(EnableInputReg == 0)
    ) InputRegInst (
        .clk_i(clk_i),
        .rst_i(rst_i),

        .s_data_i({s_sof_i, s_eol_i, s_data_i}),
        .s_valid_i(s_valid_i),
        .s_ready_o(s_ready_o),

        .m_data_o(s_axis_data),
        .m_valid_o(s_valid),
        .m_ready_i(s_ready)
    );

    assign s_sof = s_axis_data.sof,
           s_eol = s_axis_data.eol,
           s_data = s_axis_data.data;

    AxisReg #(
        .DataWidth($bits(axis_t))
    ) OutputRegInst (
        .clk_i(clk_i),
        .rst_i(rst_i),

        .s_data_i({m_sof, m_eol, m_data}),
        .s_valid_i(m_valid),
        .s_ready_o(m_ready),

        .m_data_o(m_axis_data),
        .m_valid_o(m_valid_o),
        .m_ready_i(m_ready_i)
    );

    assign m_sof_o = m_axis_data.sof,
           m_eol_o = m_axis_data.eol,
           m_data_o = m_axis_data.data;

endmodule