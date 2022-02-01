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

    logic                     col_ready;
    logic                     col_valid;
    logic                     col_sof;
    logic                     col_eol;
    logic   [2*DataWidth-1:0] col_data;

    ColumnDwt97 #(
        .DataWidth(DataWidth),
        .Point(Point),
        .MaximumSideSize(MaximumSideSize)
    ) ColumnDwtInst (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .s_ready_o(s_ready_o),
        .s_valid_i(s_valid_i),
        .s_sof_i(s_sof_i),
        .s_eol_i(s_eol_i),
        .s_data_i(s_data_i),
        .m_ready_i(col_ready),
        .m_valid_o(col_valid),
        .m_sof_o(col_sof),
        .m_eol_o(col_eol),
        .m_data_o(col_data)
    );

    logic                     exp_ready;
    logic                     exp_valid;
    logic                     exp_sof;
    logic                     exp_eol;
    logic   [2*DataWidth-1:0] exp_data;

    BorderExpander #(
        .DataWidth(DataWidth),
        .EnableInputReg(0)
    ) BorderExpanderInst (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .s_ready_o(col_ready),
        .s_valid_i(col_valid),
        .s_sof_i(col_sof),
        .s_eol_i(col_eol),
        .s_data_i(col_data),
        .m_ready_i(exp_ready),
        .m_valid_o(exp_valid),
        .m_sof_o(exp_sof),
        .m_eol_o(exp_eol),
        .m_data_o(exp_data)
    );

    logic                     transpose_ready;
    logic                     transpose_valid;
    logic                     transpose_sof;
    logic                     transpose_eol;
    logic   [2*DataWidth-1:0] transpose_data;

    Transpose #(
        .DataWidth(DataWidth)
    ) TransposeInst (
        .clk_i(clk_i),
        .rst_i(rst_i),

        .s_ready_o(exp_ready),
        .s_valid_i(exp_valid),
        .s_sof_i(exp_sof),
        .s_eol_i(exp_eol),
        .s_data_i(exp_data),

        .m_ready_i(transpose_ready),
        .m_valid_o(transpose_valid),
        .m_sof_o(transpose_sof),
        .m_eol_o(transpose_eol),
        .m_data_o(transpose_data)
    );

    logic                     row_ready;
    logic                     row_valid;
    logic                     row_sof;
    logic                     row_eol;
    logic   [2*DataWidth-1:0] row_data;

    RowDwt97 #(
        .DataWidth(DataWidth),
        .Point(Point),
        .MaximumSideSize(MaximumSideSize)
    ) RowDwtInst (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .s_ready_o(transpose_ready),
        .s_valid_i(transpose_valid),
        .s_sof_i(transpose_sof),
        .s_eol_i(transpose_eol),
        .s_data_i(transpose_data),
        .m_ready_i(row_ready),
        .m_valid_o(row_valid),
        .m_sof_o(row_sof),
        .m_eol_o(row_eol),
        .m_data_o(row_data)
    );

    localparam CoeffHH = (
        Coefficient::Alpha * Coefficient::Alpha *
        Coefficient::Beta  * Coefficient::Beta  *
        Coefficient::Gama  * Coefficient::Gama
    );
    localparam CoeffLL = CoeffHH * (Coefficient::Delta * Coefficient::Delta);
    localparam CoeffLH = CoeffHH * (Coefficient::Delta);
    localparam CoeffHL = CoeffHH * (Coefficient::Delta);

    OutputScale #(
        .InDataWidth   (16),
        .InDataPoint   (10),

        .OutDataWidth  (16),
        .OutDataPoint  (10),

        .KWidth        (25),
        .OddK          (CoeffLL * Coefficient::K * Coefficient::K),
        .OddPoint      (10),
        .EvenK         (CoeffHL),
        .EvenPoint     (10),

        .InputReg      (1),
        .OutputReg     (1)
    ) ScaleLLineInst (
        .clk_i(clk_i),
        .rst_i(rst_i),

        .s_ready_o(row_ready),
        .s_valid_i(row_valid),
        .s_sof_i(row_sof),
        .s_eol_i(row_eol),
        .s_data_i(row_data[DataWidth-1:0]),

        .m_ready_i(m_ready_i),
        .m_valid_o(m_valid_o),
        .m_sof_o(m_sof_o),
        .m_eol_o(m_eol_o),
        .m_data_o(m_data_o[DataWidth-1:0])
    );

    OutputScale #(
        .InDataWidth   (16),
        .InDataPoint   (10),

        .OutDataWidth  (16),
        .OutDataPoint  (10),

        .KWidth        (25),
        .OddK          (CoeffLH),
        .OddPoint      (10),
        .EvenK         (CoeffHH / (Coefficient::K * Coefficient::K)),
        .EvenPoint     (10),

        .InputReg      (1),
        .OutputReg     (1)
    ) ScaleHLineInst (
        .clk_i(clk_i),
        .rst_i(rst_i),

        .s_ready_o(),
        .s_valid_i(row_valid),
        .s_sof_i(row_sof),
        .s_eol_i(row_eol),
        .s_data_i(row_data[2*DataWidth-1:DataWidth]),

        .m_ready_i(m_ready_i),
        .m_valid_o(),
        .m_sof_o(),
        .m_eol_o(),
        .m_data_o(m_data_o[2*DataWidth-1:DataWidth])
    );

endmodule