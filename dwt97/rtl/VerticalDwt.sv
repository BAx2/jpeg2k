module VerticalDwt #(
    parameter DataWidth = 16,
    parameter MaximumSideSize = 512
) (
    input   logic                                   clk_i,
    input   logic                                   rst_i,

    input   logic   [$clog2(MaximumSideSize)-1:0]   side_size_i,

    input   logic                                   din_valid_i,
    output  logic                                   din_ready_o,
    input   logic                                   din_eol_i,
    input   logic   [2*DataWidth-1:0]               din_i,

    output  logic                                   dout_valid_i,
    input   logic                                   dout_ready_o,
    output  logic                                   dout_eol_o,
    output  logic   [2*DataWidth-1:0]               dout_o
);
    logic [DataWidth-1:0] even, odd;
    assign even = din_i[DataWidth-1:0];
    assign odd  = din_i[2*DataWidth-1:DataWidth];

endmodule