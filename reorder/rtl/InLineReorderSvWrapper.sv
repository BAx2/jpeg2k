module InLineReorderSvWrapper #(
    parameter DataWidth = 16,
    parameter MaxLineSize = 512, 
    parameter DoubleBuff = 1
) (
    input   logic                   clk_i,
    input   logic                   rst_i,

    input   logic                   s_axis_tvalid, 
    input   logic                   s_axis_tuser, 
    input   logic                   s_axis_tlast,
    input   logic   [DataWidth-1:0] s_axis_tdata, 
    output  logic                   s_axis_tready, 

    output  logic                   m_axis_tvalid, 
    output  logic                   m_axis_tuser, 
    output  logic                   m_axis_tlast,
    output  logic   [DataWidth-1:0] m_axis_tdata, 
    input   logic                   m_axis_tready
);

    Axis #(.DataWidth(DataWidth)) s_axis();
    Axis #(.DataWidth(DataWidth)) m_axis();

    assign
        s_axis.data = s_axis_tdata,
        s_axis.sof = s_axis_tuser,
        s_axis.eol = s_axis_tlast,
        s_axis.valid = s_axis_tvalid,
        s_axis_tready = s_axis.ready;

    assign
        m_axis_tdata = m_axis.data,
        m_axis_tuser = m_axis.sof,
        m_axis_tlast = m_axis.eol,
        m_axis_tvalid = m_axis.valid,
        m_axis.ready = m_axis_tready;

    InLineReorder #(
        .DataWidth(DataWidth),
        .MaxLineSize(MaxLineSize), 
        .DoubleBuff(DoubleBuff)
    ) ReorderInst (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .s_axis(s_axis),
        .m_axis(m_axis)
    );


endmodule