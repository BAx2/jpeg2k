module OutputScale #(
    parameter   int  InDataWidth  = 16,
    parameter   int  InDataPoint  = 10,

    parameter   int  OutDataWidth = 16,
    parameter   int  OutDataPoint = 10,

    parameter   int  KWidth       = 25,
    parameter   real OddK         = 5.12453,
    parameter   int  OddPoint     = 10,
    parameter   real EvenK        = -55.234,
    parameter   int  EvenPoint    = 10,

    parameter   bit  InputReg     = 1,
    parameter   bit  OutputReg    = 1
) (
    input   logic                                   clk_i,
    input   logic                                   rst_i,

    output  logic                                   s_ready_o,
    input   logic                                   s_valid_i,
    input   logic                                   s_sof_i,
    input   logic                                   s_eol_i,
    input   logic   [InDataWidth-1:0]               s_data_i,   // {odd, even} or {high, low}

    input   logic                                   m_ready_i,
    output  logic                                   m_valid_o,
    output  logic                                   m_sof_o,
    output  logic                                   m_eol_o,
    output  logic   [OutDataWidth-1:0]              m_data_o    // {odd, even} or {high, low}
);
    localparam IntEvenK = $rtoi(EvenK * 2.0**EvenPoint);
    localparam IntOddK  = $rtoi(OddK * 2.0**OddPoint);

    typedef struct packed {
        logic                          eol;
        logic                          sof;
        logic signed [InDataWidth-1:0] data;
    } din_t;

    typedef struct packed {
        logic                           eol;
        logic                           sof;
        logic                           even_point;
        logic signed [InDataWidth+KWidth-1:0] data;
    } dout_t;

    logic                       s_ready;
    logic                       s_valid;

    logic                       m_ready;
    logic                       m_valid;

    din_t din, din_reg;
    dout_t dout, dout_reg;

    AxisReg #(
        .DataWidth($bits(din)),
        .Transperent(InputReg == 0)
    ) InputRegInst (
        .clk_i(clk_i),
        .rst_i(rst_i),
        
        .s_data_i(din),
        .s_valid_i(s_valid_i),
        .s_ready_o(s_ready_o),
        
        .m_data_o(din_reg),
        .m_valid_o(s_valid),
        .m_ready_i(s_ready)
    );

    AxisReg #(
        .DataWidth($bits(dout)),
        .Transperent(InputReg == 0)
    ) OutputRegInst (
        .clk_i(clk_i),
        .rst_i(rst_i),
        
        .s_data_i(dout),
        .s_valid_i(m_valid),
        .s_ready_o(m_ready),
        
        .m_data_o(dout_reg),
        .m_valid_o(m_valid_o),
        .m_ready_i(m_ready_i)
    );

    assign din.eol = s_eol_i,
           din.sof = s_sof_i,
           din.data = s_data_i;

    logic                            even_koeff;
    logic   [KWidth-1:0]             koeff;
    logic   [InDataWidth+KWidth-1:0] mult;

    localparam evenOffset = EvenPoint + InDataPoint - OutDataPoint;
    localparam oddOffset  = OddPoint + InDataPoint - OutDataPoint;

    assign koeff       = even_koeff ? IntEvenK : IntOddK;
    assign mult        = signed'(koeff) * signed'(din_reg.data);

    assign dout.data = mult,
           dout.even_point = even_koeff;

    assign dout.sof = din_reg.sof,
           dout.eol = din_reg.eol;

    assign m_data_o = dout_reg.even_point ? (dout_reg.data >> evenOffset) : (dout_reg.data >> oddOffset),
           m_sof_o = dout_reg.sof,
           m_eol_o = dout_reg.eol;

    assign m_valid = s_valid,
           s_ready = m_ready;

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            even_koeff <= 1;
        end begin
            if (s_valid & s_ready) begin
                if (din_reg.eol) begin
                    even_koeff <= 1;
                end else begin
                    even_koeff <= ~even_koeff;
                end
            end
        end
    end

endmodule