module ProcessingUnit1D #(
    parameter       DataWidth         = 16,
    parameter       Point             = 10,
    parameter       MaximumSideSize   = 512,
    // parameter       Orientation       = "Horizontal", // posible: "Horizontal" "Vertical"
    parameter real  Alpha             = Coefficient::Alpha,
    parameter real  Beta              = Coefficient::Beta,
    parameter bit   InputReg          = 1
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

    localparam InvAlpha = 1.0 / Alpha;
    localparam InvAlphaBeta = 1.0 + 1.0 / (Alpha * Beta);
    localparam IntInvAlpha = $rtoi(InvAlpha * 2.0**Point);
    localparam IntInvAlphaBeta = $rtoi(InvAlphaBeta * 2.0**Point);

    localparam PipelineLatency = InputReg + 1 + 1; // input reg + multiply + output calc 

    logic en_reg;

    logic [2*DataWidth-1:0] din_int;

    logic signed [DataWidth-1:0] even, odd;
    logic signed [DataWidth-1:0] k_even, k_odd;

    logic signed [DataWidth-1:0] even_reg, k_even_reg, k_odd_reg;

    generate 
        begin
            if (InputReg) begin
                Dffenr #(
                    .Width(2*DataWidth)
                ) InputRegInst (
                    .clk_i(clk_i),
                    .rst_i(rst_i),
                    .en_i(en_reg),
                    .din_i(s_data_i),
                    .dout_o(din_int)
                );
            end else begin
                assign din_int = s_data_i;
            end
            assign odd  = din_int[2*DataWidth-1:DataWidth];
            assign even = din_int[DataWidth-1:0];
        end
    endgenerate
    
    Multiplyer #(
        .Width(DataWidth),
        .InPoint(Point),
        .OutPoint(Point)
    ) OddMultInst (
        .a_i(odd),
        .b_i(IntInvAlpha),
        .m_o(k_odd)
    );
    
    Multiplyer #(
        .Width(DataWidth),
        .InPoint(Point),
        .OutPoint(Point)
    ) EvenMultInst (
        .a_i(even),
        .b_i(IntInvAlphaBeta),
        .m_o(k_even)
    );

    Dffenr #(
        .Width(DataWidth)
    ) KEvenRegInst (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .en_i(en_reg),
        .din_i(k_even),
        .dout_o(k_even_reg)
    );

    Dffenr #(
        .Width(DataWidth)
    ) EvenRegInst (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .en_i(en_reg),
        .din_i(even),
        .dout_o(even_reg)
    );

    Dffenr #(
        .Width(DataWidth)
    ) KOddRegInst (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .en_i(en_reg),
        .din_i(k_odd),
        .dout_o(k_odd_reg)
    );

    logic signed [DataWidth-1:0] d1_buff_in, d1_buff_out;
    logic signed [DataWidth-1:0] d2_buff_in, d2_buff_out;
    logic signed [DataWidth-1:0] y_odd, y_even;

    Adder #(
        .Width(DataWidth)
    ) OddAdderInst (
        .a_i(k_odd_reg),
        .b_i(even_reg),
        .s_o(d1_buff_in)
    );

    Adder #(
        .Width(DataWidth)
    ) EvenAdderInst (
        .a_i(d1_buff_out),
        .b_i(even_reg),
        .s_o(y_odd)
    );

    Adder #(
        .Width(DataWidth)
    ) OddOutAdderInst (
        .a_i(k_even_reg),
        .b_i(d1_buff_out),
        .s_o(d2_buff_in)
    );

    Adder #(
        .Width(DataWidth)
    ) EvenOutAdderInst (
        .a_i(d2_buff_out),
        .b_i(y_odd),
        .s_o(y_even)
    );

    Dffenr #(
        .Width(2*DataWidth)
    ) OutputRegInst (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .en_i(en_reg),
        .din_i({ y_odd, y_even }),
        .dout_o(m_data_o)
    );
    
    localparam AddrWidth = $clog2(MaximumSideSize);
    
    // for column filter
    logic [AddrWidth-1:0] raddr, waddr;
    logic buff_we;

    Bram #(
        .DataWidth(DataWidth),
        .AddrWidth(AddrWidth)
    ) D1RamInst (
        .clka_i(clk_i),
        .clkb_i(clk_i),
        // write channel
        .addra_i(waddr),
        .wea_i(buff_we),
        .dina_i(d1_buff_in),
        .douta_o(),
        // read channel
        .addrb_i(raddr),
        .web_i(1'b0),
        .dinb_i('h0),
        .doutb_o(d1_buff_out)
    );

    Bram #(
        .DataWidth(DataWidth),
        .AddrWidth(AddrWidth)
    ) D2RamInst (
        .clka_i(clk_i),
        .clkb_i(clk_i),
        // write channel
        .addra_i(waddr),
        .wea_i(buff_we),
        .dina_i(d2_buff_in),
        .douta_o(),
        // read channel
        .addrb_i(raddr),
        .web_i(1'b0),
        .dinb_i('h0),
        .doutb_o(d2_buff_out)
    );

    Counter #(
        .Width(AddrWidth),
        .RstVal(0)
    ) WriteCounterInst (
        .clk_i(clk_i),
        .rst_i(s_eol_i | rst_i),
        .en_i(buff_we),
        .val_o(waddr)
    );

    // TODO: fix raddr calc
    assign raddr = (s_eol_i) ? 0 : waddr + 1;    
    assign buff_we = s_valid_i;
    assign en_reg = s_valid_i;

    // 

    logic shiftEn;
    assign shiftEn = s_valid_i;

    ShiftReg #(
        .Width(1),
        .Depth(PipelineLatency)
    ) EolShRegInst (
        .clk_i(clk_i),
        .en_i(shiftEn),
        .din_i(s_eol_i),
        .dout_o(m_eol_o)
    );

    ShiftReg #(
        .Width(1),
        .Depth(PipelineLatency)
    ) SofShRegInst (
        .clk_i(clk_i),
        .en_i(shiftEn),
        .din_i(s_sof_i),
        .dout_o(m_sof_o)
    );

    assign m_valid_o = m_ready_i & s_valid_i;
    assign s_ready_o = m_ready_i;


    // only sim
    real real_even, real_ke, real_k_even;
    real real_odd, real_ko, real_k_odd;

    real real_even_reg, real_k_even_reg, real_k_odd_reg;
    
    real real_d1_in, real_d1_out; 
    real real_d2_in, real_d2_out; 
    
    assign real_even       = even            / (2.0 ** Point);
    assign real_ke         = IntInvAlphaBeta / (2.0 ** Point);
    assign real_k_even     = k_even          / (2.0 ** Point);
    
    assign real_odd        = odd             / (2.0 ** Point);
    assign real_ko         = IntInvAlpha     / (2.0 ** Point);
    assign real_k_odd      = k_odd           / (2.0 ** Point);
    
    assign real_even_reg   = even_reg        / (2.0 ** Point);
    assign real_k_even_reg = k_even_reg      / (2.0 ** Point);
    assign real_k_odd_reg  = k_odd_reg       / (2.0 ** Point);
    assign real_d1_in      = d1_buff_in      / (2.0 ** Point);
    assign real_d1_out     = d1_buff_out     / (2.0 ** Point);
    assign real_d2_in      = d2_buff_in      / (2.0 ** Point);
    assign real_d2_out     = d2_buff_out     / (2.0 ** Point);

endmodule