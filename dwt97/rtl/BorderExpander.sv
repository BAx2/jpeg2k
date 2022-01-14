// input 
//  0 2 4 6
//  1 3 5 7
// output 
//  4 2 | 0 2 4 6 | 6 4
//  3 1 | 1 3 5 7 | 5 3

// minimum row length = 16

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
    localparam BufferSize = 3;
    localparam AddrWidth = $clog2(BufferSize);
    
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


    logic new_in;
    logic sof;
    logic [DataWidth-1:0] s_odd, s_even;
    logic [DataWidth-1:0] m_odd, m_even;
    logic new_out;
    
    logic [AddrWidth-1:0] odd_addr, even_addr;
    logic odd_transperent, even_transperent;

    logic [DataWidth-1:0] odd_buff, even_buff;    
    logic buff_we;

    
    ShiftRegAddr #(
        .Width(DataWidth),
        .Depth(BufferSize)
    ) EvenBuffInst (
        .clk_i(clk_i),
        .en_i(buff_we),
        .din_i(s_even),
        .addr_i(even_addr),
        .dout_o(even_buff)
    );

    ShiftRegAddr #(
        .Width(DataWidth),
        .Depth(BufferSize)
    ) OddBuffInst (
        .clk_i(clk_i),
        .en_i(buff_we),
        .din_i(s_odd),
        .addr_i(odd_addr),
        .dout_o(odd_buff)
    );

    Mux2 #(
        .Width(DataWidth)
    ) EvenMuxInst (
        .a_i(even_buff),
        .b_i(s_even),
        .s_i(even_transperent),
        .m_o(m_even)
    );

    Mux2 #(
        .Width(DataWidth)
    ) OddMuxInst (
        .a_i(odd_buff),
        .b_i(s_odd),
        .s_i(odd_transperent),
        .m_o(m_odd)
    );

    assign m_data = { m_odd, m_even };

    assign s_even = s_data[DataWidth-1:0];
    assign s_odd  = s_data[2*DataWidth-1:DataWidth];
    
    assign new_in = s_valid & s_ready;
    assign new_out = m_valid & m_ready;

    assign buff_we = new_in;

    logic [3:0] expand_cnt;
    always_ff @(posedge clk_i) begin
        if (rst_i | expand_cnt == 9) begin
            expand_cnt <= 0;
        end else if (new_in | new_out) begin
            if (expand_cnt != 7 | s_eol) begin
                expand_cnt <= expand_cnt + 1;
            end
        end
    end

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            sof <= 0;
        end else begin
            if (new_in & expand_cnt == 0) begin
                sof <= s_sof;
            end
        end
    end

    assign s_ready = (expand_cnt < 3) | (expand_cnt == 7);
    assign m_valid = (expand_cnt > 1);
    assign m_eol = (expand_cnt == 9);
    assign m_sof = (expand_cnt == 2) ? sof : 0;

    always_comb begin
        case (expand_cnt)
            // left border
            2: begin
                even_transperent = 1;
                even_addr = 0;
                odd_transperent = 0;
                odd_addr = 0;
            end
            3: begin
                even_transperent = 0;
                even_addr = 1;
                odd_transperent = 0;
                odd_addr = 2;
            end
            4: begin
                even_transperent = 0;
                even_addr = 2;
                odd_transperent = 0;
                odd_addr = 2;                
            end
            5: begin
                even_transperent = 0;
                even_addr = 1;
                odd_transperent = 0;
                odd_addr = 1;                
            end
            6: begin
                even_transperent = 0;
                even_addr = 0;
                odd_transperent = 0;
                odd_addr = 0;
            end
            // center 
            7: begin
                even_transperent = 1;
                even_addr = 0;
                odd_transperent = 1;
                odd_addr = 0;
            end
            // right border
            8: begin
                even_transperent = 0;
                even_addr = 0;
                odd_transperent = 0;
                odd_addr = 1;
            end 
            9: begin
                even_transperent = 0;
                even_addr = 1;
                odd_transperent = 0;
                odd_addr = 2;
            end 
            // 
            default: begin
                even_transperent = 0;
                even_addr = 1;
                odd_transperent = 0;
                odd_addr = 2;
            end 
        endcase
    end


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