`include "Coefficient.svh"

module RowDwt97 #(
    parameter       DataWidth         = 16,
    parameter       Point             = 10,
    parameter       MaximumSideSize   = 512
) (
    input   logic                                   clk_i,
    input   logic                                   rst_i,

    output  logic                                   s_ready_o,
    input   logic                                   s_valid_i,
    input   logic                                   s_sof_i,
    input   logic                                   s_eol_i,
    input   logic   [2*DataWidth-1:0]               s_data_i,   // {odd, even} or {high, low}

    input   logic                                   m_ready_i,
    output  logic                                   m_valid_o,
    output  logic                                   m_sof_o,
    output  logic                                   m_eol_o,
    output  logic   [2*DataWidth-1:0]               m_data_o    // {odd, even} or {high, low}
);

    logic                       ready;
    logic                       valid;
    logic                       sof;
    logic                       eol;
    logic   [2*DataWidth-1:0]   data;

    logic m_ready, m_valid, m_sof, m_eol;
    logic [2*DataWidth-1:0] m_data;

    ProcessingUnit1D #(
        .DataWidth(DataWidth),
        .Point(Point),
        .MaximumSideSize(MaximumSideSize),
        .FilterType("Row"),
        .Alpha(1.0 / Coefficient::Alpha),
        .Beta(1.0 / (Coefficient::Alpha * Coefficient::Beta) + 1),
        .InputReg(1)
    ) FirstPuInst (
        .clk_i(clk_i),
        .rst_i(rst_i),
        
        .s_ready_o(s_ready_o),
        .s_valid_i(s_valid_i),
        .s_sof_i(s_sof_i),
        .s_eol_i(s_eol_i),
        .s_data_i(s_data_i),
        
        .m_ready_i(ready),
        .m_valid_o(valid),
        .m_sof_o(sof),
        .m_eol_o(eol),
        .m_data_o(data)
    );

    ProcessingUnit1D #(
        .DataWidth(DataWidth),
        .Point(Point),
        .MaximumSideSize(MaximumSideSize),
        .FilterType("Row"),
        .Alpha(1.0 / (Coefficient::Gama * Coefficient::Beta)),
        .Beta(1.0 / (Coefficient::Gama * Coefficient::Delta) + 1),
        .InputReg(0)
    ) SecondPuInst (
        .clk_i(clk_i),
        .rst_i(rst_i),

        .s_ready_o(ready),
        .s_valid_i(valid),
        .s_sof_i(sof),
        .s_eol_i(eol),
        .s_data_i(data),
        
        .m_ready_i(m_ready),
        .m_valid_o(m_valid),
        .m_sof_o(m_sof),
        .m_eol_o(m_eol),
        .m_data_o(m_data)
    );

    // skip first N coeff
    localparam SkipNum = 8;
    localparam SkipCntWidth = $clog2(SkipNum + 1);

    logic [SkipCntWidth-1:0] skip_cnt;
    always_ff @(posedge clk_i) begin
        if (rst_i | m_eol) begin
            skip_cnt <= 0;
        end else begin
            if (m_valid & m_ready & skip_cnt != SkipNum) begin
                skip_cnt <= skip_cnt + 1;
            end
        end
    end
    
    logic need_sof;
    always_ff @(posedge clk_i) begin
        if (rst_i | (skip_cnt == SkipNum)) begin
            need_sof <= 0;
        end else begin
            if (skip_cnt == 0 & m_valid & m_ready) begin
                need_sof <= m_sof;
            end
        end
    end


    assign m_ready = (skip_cnt == SkipNum) ? m_ready_i : 1;
    assign m_valid_o = (skip_cnt == SkipNum) ? m_valid : 0;
    assign m_eol_o = m_eol;
    assign m_sof_o = (skip_cnt == SkipNum) ? need_sof : 0;
    assign m_data_o = m_data;
    
endmodule