module Dwt97 #(
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

    ProcessingUnit1D #(
        .DataWidth(DataWidth),
        .Point(Point),
        .MaximumSideSize(MaximumSideSize),
        .Alpha(Coefficient::Alpha),
        .Beta(Coefficient::Beta),
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
    
    logic signed [DataWidth-1:0] even;
    logic signed [DataWidth-1:0] odd;

    assign odd  = data[2*DataWidth-1:DataWidth];
    assign even = data[DataWidth-1:0];
    
    logic signed [2*DataWidth-1:0] k_even;
    logic signed [2*DataWidth-1:0] k_odd;
    logic        [2*DataWidth-1:0] data_int;

    assign k_odd = $rtoi(Coefficient::Alpha * odd);
    assign k_even = $rtoi(Coefficient::Alpha * Coefficient::Beta * even);

    assign data_int[2*DataWidth-1:DataWidth] = k_odd;
    assign data_int[DataWidth-1:0] = k_even;

    ProcessingUnit1D #(
        .DataWidth(DataWidth),
        .Point(Point),
        .MaximumSideSize(MaximumSideSize),
        .Alpha(Coefficient::Gama),
        .Beta(Coefficient::Delta),
        .InputReg(1)
    ) SecondPuInst (
        .clk_i(clk_i),
        .rst_i(rst_i),

        .s_ready_o(ready),
        .s_valid_i(valid),
        .s_sof_i(sof),
        .s_eol_i(eol),

        .s_data_i(data_int),
        
        .m_ready_i(m_ready_i),
        .m_valid_o(m_valid_o),
        .m_sof_o(m_sof_o),
        .m_eol_o(m_eol_o),
        .m_data_o(m_data_o)
    );
endmodule