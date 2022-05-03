module ProcessingUnit1D #(
    parameter       MaximumSideSize   = 512,
    parameter       FilterType        = "Column", // "Column" "Row"
    parameter real  OddK              = 1.0 / (Coefficient::Alpha),
    parameter real  EvenK             = 1.0 / (Coefficient::Alpha * Coefficient::Beta) + 1.0,
    
    parameter bit   InputReg          = 1,
    parameter bit   InputSkidBuff     = 1,

    parameter bit   OutputReg         = 1,
    parameter bit   OutputSkidBuff    = 1,

    //  Coeffs fixed point formats
    parameter       OddInputWidth     = 16,
    parameter       OddInputPoint     = 10,
    parameter       OddKWidth         = 16,
    parameter       OddKPoint         = 10,
    parameter       OddMultOutWidth   = 16,
    parameter       OddMultOutPoint   = 10,
    parameter       OddBuffWidth      = 16,
    parameter       OddBuffPoint      = 10,
    parameter       OddOutputWidth    = 16,
    parameter       OddOutputPoint    = 10,
    //
    parameter       EvenInputWidth    = 16,
    parameter       EvenInputPoint    = 10,
    parameter       EvenKWidth        = 16,
    parameter       EvenKPoint        = 10,
    parameter       EvenMultOutWidth  = 16,
    parameter       EvenMultOutPoint  = 10,
    parameter       EvenBuffWidth     = 16,
    parameter       EvenBuffPoint     = 10,
    parameter       EvenOutputWidth   = 16,
    parameter       EvenOutputPoint   = 10
) (
    input   logic                                   clk_i,
    input   logic                                   rst_i,

    output  logic                                   s_ready_o,
    input   logic                                   s_valid_i,
    input   logic                                   s_sof_i,
    input   logic                                   s_eol_i,
    input   logic   [OddInputWidth-1:0]             s_data_odd_i,
    input   logic   [EvenInputWidth-1:0]            s_data_even_i,

    input   logic                                   m_ready_i,
    output  logic                                   m_valid_o,
    output  logic                                   m_sof_o,
    output  logic                                   m_eol_o,
    output  logic   [OddOutputWidth-1:0]            m_data_odd_o,
    output  logic   [EvenOutputWidth-1:0]           m_data_even_o
);
    localparam IntEvenK = $rtoi(EvenK * 2.0**EvenKPoint);
    localparam IntOddK  = $rtoi(OddK * 2.0**OddKPoint);

    typedef struct packed {
        logic                             eol;
        logic                             sof;
        logic signed [EvenInputWidth-1:0] even;
        logic signed [OddInputWidth-1:0]  odd;
    } mult_t;

    typedef struct packed {
        logic                               eol;
        logic                               sof;
        logic signed [EvenInputWidth-1:0]   even;
        logic signed [EvenMultOutWidth-1:0] k_even;
        logic signed [OddMultOutWidth-1:0]  k_odd;
    } calc_t;

    typedef struct packed {
        logic                              eol;
        logic                              sof;
        logic signed [EvenOutputWidth-1:0] even;
        logic signed [OddOutputWidth-1:0]  odd;
    } output_t;

    mult_t inp_data, mult_data;
    calc_t to_calc_reg;
    logic mult_ready, mult_valid;

    calc_t calc_data;
    logic calc_ready, calc_valid, calc_do_op;
    output_t to_output_reg;

    output_t output_data;

    assign inp_data.eol  = s_eol_i,
           inp_data.sof  = s_sof_i,
           inp_data.even = s_data_even_i,
           inp_data.odd  = s_data_odd_i;

    AxisReg #(
        .DataWidth($bits(inp_data)),
        .Transperent(InputReg == 0),
        .Pipelined(InputSkidBuff)
    ) InputRegInst (
        .clk_i(clk_i),
        .rst_i(rst_i),
        
        .s_data_i(inp_data),
        .s_valid_i(s_valid_i),
        .s_ready_o(s_ready_o),
        
        .m_data_o(mult_data),
        .m_valid_o(mult_valid),
        .m_ready_i(mult_ready)
    );
    
    // mult stage

    Multiplier #(
        .AWidth(OddInputWidth),
        .APoint(OddInputPoint),
        .BWidth(OddKWidth),
        .BPoint(OddKPoint),
        .OutWidth(OddMultOutWidth),
        .OutPoint(OddMultOutPoint)
    ) OddMultInst (
        .a_i(mult_data.odd),
        .b_i(IntOddK),
        .m_o(to_calc_reg.k_odd)
    );
    
    Multiplier #(
        .AWidth(EvenInputWidth),
        .APoint(EvenInputPoint),
        .BWidth(EvenKWidth),
        .BPoint(EvenKPoint),
        .OutWidth(EvenMultOutWidth),
        .OutPoint(EvenMultOutPoint)
    ) EvenMultInst (
        .a_i(mult_data.even),
        .b_i(IntEvenK),
        .m_o(to_calc_reg.k_even)
    );

    assign to_calc_reg.eol  = mult_data.eol,
           to_calc_reg.sof  = mult_data.sof,
           to_calc_reg.even = mult_data.even;

    // calc stage
    AxisReg #(
        .DataWidth($bits(to_calc_reg))
    ) CalcRegInst (
        .clk_i(clk_i),
        .rst_i(rst_i),
        
        .s_data_i(to_calc_reg),
        .s_valid_i(mult_valid),
        .s_ready_o(mult_ready),
        
        .m_data_o(calc_data),
        .m_valid_o(calc_valid),
        .m_ready_i(calc_ready)
    );
    assign calc_do_op = calc_valid & calc_ready;

    logic signed [OddBuffWidth-1:0] d1_buff_in, d1_buff_out;   //  odd buffer
    logic signed [EvenBuffWidth-1:0] d2_buff_in, d2_buff_out;   // even buffer
    logic signed [OddOutputWidth-1:0] y_odd;
    logic signed [EvenOutputWidth-1:0] y_even;

    Adder #(
        .AWidth(OddMultOutWidth),
        .APoint(OddMultOutPoint),
        .BWidth(EvenInputWidth),
        .BPoint(EvenInputPoint),
        .OutWidth(OddBuffWidth),
        .OutPoint(OddBuffPoint)
    ) OddAdderInst (
        .a_i(calc_data.k_odd),
        .b_i(calc_data.even),
        .s_o(d1_buff_in)
    );

    Adder #(
        .AWidth(OddBuffWidth),
        .APoint(OddBuffPoint),
        .BWidth(EvenInputWidth),
        .BPoint(EvenInputPoint),
        // TODO: change fixed point format
        .OutWidth(OddOutputWidth),
        .OutPoint(OddOutputPoint)
    ) EvenAdderInst (
        .a_i(d1_buff_out),
        .b_i(calc_data.even),
        .s_o(to_output_reg.odd)
    );

    Adder #(
        .AWidth(EvenMultOutWidth),
        .APoint(EvenMultOutPoint),
        .BWidth(OddBuffWidth),
        .BPoint(OddBuffPoint),
        .OutWidth(EvenBuffWidth),
        .OutPoint(EvenBuffPoint)
    ) OddOutAdderInst (
        .a_i(calc_data.k_even),
        .b_i(d1_buff_out),
        .s_o(d2_buff_in)
    );

    Adder #(
        .AWidth(EvenBuffWidth),
        .APoint(EvenBuffPoint),
        .BWidth(OddOutputWidth),
        .BPoint(OddOutputPoint),
        .OutWidth(EvenOutputWidth),
        .OutPoint(EvenOutputPoint)
    ) EvenOutAdderInst (
        .a_i(d2_buff_out),
        .b_i(to_output_reg.odd),
        .s_o(to_output_reg.even)
    );

    assign to_output_reg.sof = calc_data.sof,
           to_output_reg.eol = calc_data.eol;

    AxisReg #(
        .DataWidth($bits(to_output_reg)),
        .Transperent(OutputReg == 0),
        .Pipelined(OutputSkidBuff)
    ) OutputRegInst (
        .clk_i(clk_i),
        .rst_i(rst_i),
        
        .s_data_i(to_output_reg),
        .s_valid_i(calc_valid),
        .s_ready_o(calc_ready),
        
        .m_data_o(output_data),
        .m_valid_o(m_valid_o),
        .m_ready_i(m_ready_i)
    );
    assign m_data_odd_o = output_data.odd, 
           m_data_even_o = output_data.even,
           m_eol_o  = output_data.eol,
           m_sof_o  = output_data.sof;

    localparam RamAddrWidth = $clog2(MaximumSideSize);
    
    logic [RamAddrWidth-1:0] raddr, waddr;
    logic buff_we;
    generate
        if (FilterType == "Column") begin
        
            Bram #(
                .DataWidth(OddBuffWidth),
                .AddrWidth(RamAddrWidth)
            ) D1RamInst (
                .clka_i(clk_i),
                .clkb_i(clk_i),
                // write channel
                .addra_i(waddr),
                .ena_i(1),
                .wea_i(buff_we),
                .dina_i(d1_buff_in),
                .douta_o(),
                // read channel
                .addrb_i(raddr),
                .enb_i(calc_do_op),
                .web_i(1'b0),
                .dinb_i('h0),
                .doutb_o(d1_buff_out)
            );
        
            Bram #(
                .DataWidth(EvenBuffWidth),
                .AddrWidth(RamAddrWidth)
            ) D2RamInst (
                .clka_i(clk_i),
                .clkb_i(clk_i),
                // write channel
                .addra_i(waddr),
                .ena_i(1),
                .wea_i(buff_we),
                .dina_i(d2_buff_in),
                .douta_o(),
                // read channel
                .addrb_i(raddr),
                .enb_i(calc_do_op),
                .web_i(1'b0),
                .dinb_i('h0),
                .doutb_o(d2_buff_out)
            );
        
            Counter #(
                .Width(RamAddrWidth),
                .RstVal(0)
            ) WriteCounterInst (
                .clk_i(clk_i),
                .rst_i(calc_data.eol | rst_i),
                .en_i(buff_we),
                .val_o(waddr)
            );
        
            assign raddr = (calc_data.eol) ? 0 : waddr + 1;    
            assign buff_we = calc_do_op;
        end 
        else if (FilterType == "Row") begin
            ShiftReg #(
                .Width(OddBuffWidth),
                .Depth(2)
            ) D1BuffInst (
                .clk_i(clk_i),
                .en_i(buff_we),
                .din_i(d1_buff_in),
                .dout_o(d1_buff_out)
            );
            ShiftReg #(
                .Width(EvenBuffWidth),
                .Depth(2)
            ) D2BuffInst (
                .clk_i(clk_i),
                .en_i(buff_we),
                .din_i(d2_buff_in),
                .dout_o(d2_buff_out)
            );
            assign buff_we = calc_do_op;
        end 
        else begin
            illegal_parameter_condition_triggered_will_instantiate_an non_existing_module();
        end
    endgenerate

    /////////////////////////////////////////////////////////////
    // only sim
    real sim_even, sim_ke, sim_k_even;
    real sim_odd, sim_ko, sim_k_odd;

    assign sim_even       = mult_data.even         / (2.0 ** EvenInputPoint);
    assign sim_ke         = IntEvenK               / (2.0 ** EvenKPoint);
    assign sim_k_even     = to_calc_reg.k_even     / (2.0 ** EvenMultOutPoint);
    
    assign sim_odd        = mult_data.odd          / (2.0 ** OddInputPoint);
    assign sim_ko         = IntOddK                / (2.0 ** OddKPoint);
    assign sim_k_odd      = to_calc_reg.k_odd      / (2.0 ** OddMultOutPoint);

    real sim_even_reg, sim_k_even_reg, sim_k_odd_reg;
    real sim_d1_in, sim_d1_out; 
    real sim_d2_in, sim_d2_out; 

    assign sim_even_reg   = calc_data.even         / (2.0 ** EvenInputPoint);
    assign sim_k_even_reg = calc_data.k_even       / (2.0 ** EvenMultOutPoint);
    assign sim_k_odd_reg  = calc_data.k_odd        / (2.0 ** OddMultOutPoint);
    assign sim_d1_in      = d1_buff_in             / (2.0 ** OddBuffPoint);
    assign sim_d1_out     = d1_buff_out            / (2.0 ** OddBuffPoint);
    assign sim_d2_in      = d2_buff_in             / (2.0 ** EvenBuffPoint);
    assign sim_d2_out     = d2_buff_out            / (2.0 ** EvenBuffPoint);

endmodule
