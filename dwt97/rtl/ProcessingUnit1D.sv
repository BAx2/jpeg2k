// TODO: add normal axi handshake
// 
//          input      cross-stage    output                    
//          reg        reg            reg                     
//         +---+      +---+          +---+    
// =odd==> | R |      | R |          | R | =odd==>     
//         | G | mult | G | out calc | G |         
// =even=> |   |      |   |          |   | =even=>
//         +---+      +---+          +---+
//

module ProcessingUnit1D #(
    parameter       DataWidth         = 16,
    parameter       Point             = 10,
    parameter       MaximumSideSize   = 512,
    parameter       FilterType        = "Column", // "Column" "Row"
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

    localparam IntInvAlpha = $rtoi(Alpha * 2.0**Point);
    localparam IntInvAlphaBeta = $rtoi(Beta * 2.0**Point);

    typedef struct packed {
        logic                        eol;
        logic                        sof;
        logic signed [DataWidth-1:0] even;
        logic signed [DataWidth-1:0] odd;
    } mult_t;

    typedef struct packed {
        logic                        eol;
        logic                        sof;
        logic signed [DataWidth-1:0] even;
        logic signed [DataWidth-1:0] k_even;
        logic signed [DataWidth-1:0] k_odd;
    } calc_t;

    typedef struct packed {
        logic                        eol;
        logic                        sof;
        logic signed [DataWidth-1:0] even;
        logic signed [DataWidth-1:0] odd;
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
           inp_data.even = s_data_i[DataWidth-1:0],
           inp_data.odd  = s_data_i[2*DataWidth-1:DataWidth];

    AxisReg #(
        .DataWidth($bits(inp_data)),
        .Transperent(InputReg == 0)
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

    Multiplyer #(
        .Width(DataWidth),
        .InPoint(Point),
        .OutPoint(Point)
    ) OddMultInst (
        .a_i(mult_data.odd),
        .b_i(IntInvAlpha),
        .m_o(to_calc_reg.k_odd)
    );
    
    Multiplyer #(
        .Width(DataWidth),
        .InPoint(Point),
        .OutPoint(Point)
    ) EvenMultInst (
        .a_i(mult_data.even),
        .b_i(IntInvAlphaBeta),
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

    logic signed [DataWidth-1:0] d1_buff_in, d1_buff_out;
    logic signed [DataWidth-1:0] d2_buff_in, d2_buff_out;
    logic signed [DataWidth-1:0] y_odd, y_even;

    Adder #(
        .Width(DataWidth)
    ) OddAdderInst (
        .a_i(calc_data.k_odd),
        .b_i(calc_data.even),
        .s_o(d1_buff_in)
    );

    Adder #(
        .Width(DataWidth)
    ) EvenAdderInst (
        .a_i(d1_buff_out),
        .b_i(calc_data.even),
        .s_o(to_output_reg.odd)
    );

    Adder #(
        .Width(DataWidth)
    ) OddOutAdderInst (
        .a_i(calc_data.k_even),
        .b_i(d1_buff_out),
        .s_o(d2_buff_in)
    );

    Adder #(
        .Width(DataWidth)
    ) EvenOutAdderInst (
        .a_i(d2_buff_out),
        .b_i(to_output_reg.odd),
        .s_o(to_output_reg.even)
    );

    assign to_output_reg.sof = calc_data.sof,
           to_output_reg.eol = calc_data.eol;

    AxisReg #(
        .DataWidth($bits(to_output_reg))
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
    assign m_data_o = {output_data.odd, output_data.even},
           m_eol_o  = output_data.eol,
           m_sof_o  = output_data.sof;

    localparam RamAddrWidth = $clog2(MaximumSideSize);
    
    generate
        if (FilterType == "Column") begin
            logic [RamAddrWidth-1:0] raddr, waddr;
            logic buff_we;
        
            Bram #(
                .DataWidth(DataWidth),
                .AddrWidth(RamAddrWidth)
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
                .AddrWidth(RamAddrWidth)
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
                .Width(RamAddrWidth),
                .RstVal(0)
            ) WriteCounterInst (
                .clk_i(clk_i),
                .rst_i(calc_data.eol | rst_i),
                .en_i(buff_we),
                .val_o(waddr)
            );
        
            assign raddr = (calc_data.eol) ? 0 : waddr + 1;    
            assign buff_we = calc_valid;
        end 
        else if (FilterType == "Row") begin
            logic buff_we;
            ShiftReg #(
                .Width(DataWidth),
                .Depth(2)
            ) D1BuffInst (
                .clk_i(clk_i),
                .en_i(buff_we),
                .din_i(d1_buff_in),
                .dout_o(d1_buff_out)
            );
            ShiftReg #(
                .Width(DataWidth),
                .Depth(2)
            ) D2BuffInst (
                .clk_i(clk_i),
                .en_i(buff_we),
                .din_i(d2_buff_in),
                .dout_o(d2_buff_out)
            );
            assign buff_we = calc_valid;
        end 
        else begin
            illegal_parameter_condition_triggered_will_instantiate_an non_existing_module();
        end
    endgenerate

    
    /////////////////////////////////////////////////////////////
    // only sim
    real sim_even, sim_ke, sim_k_even;
    real sim_odd, sim_ko, sim_k_odd;

    assign sim_even       = mult_data.even         / (2.0 ** Point);
    assign sim_ke         = IntInvAlphaBeta        / (2.0 ** Point);
    assign sim_k_even     = to_calc_reg.k_even     / (2.0 ** Point);
    
    assign sim_odd        = mult_data.odd          / (2.0 ** Point);
    assign sim_ko         = IntInvAlpha            / (2.0 ** Point);
    assign sim_k_odd      = to_calc_reg.k_odd      / (2.0 ** Point);

    real sim_even_reg, sim_k_even_reg, sim_k_odd_reg;
    real sim_d1_in, sim_d1_out; 
    real sim_d2_in, sim_d2_out; 

    assign sim_even_reg   = calc_data.even         / (2.0 ** Point);
    assign sim_k_even_reg = calc_data.k_even       / (2.0 ** Point);
    assign sim_k_odd_reg  = calc_data.k_odd        / (2.0 ** Point);
    assign sim_d1_in      = d1_buff_in             / (2.0 ** Point);
    assign sim_d1_out     = d1_buff_out            / (2.0 ** Point);
    assign sim_d2_in      = d2_buff_in             / (2.0 ** Point);
    assign sim_d2_out     = d2_buff_out            / (2.0 ** Point);

endmodule