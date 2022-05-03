module tb_pu ();

    localparam ClkPeriod   = 10ns;
    
    localparam CommonWidth = 24;
    localparam CommonPoint = 16;

    localparam SideSize    = 16;

    parameter       MaximumSideSize   = 512;
    parameter       FilterType        = "Column"; // "Column" "Row"
    parameter real  OddK              = 1.0 / (Coefficient::Alpha);
    parameter real  EvenK             = 1.0 / (Coefficient::Alpha * Coefficient::Beta) + 1.0;
    parameter bit   InputReg          = 1;
    parameter bit   InputSkidBuff     = 1;
    parameter bit   OutputReg         = 1;
    parameter bit   OutputSkidBuff    = 1;

    parameter       OddInputWidth     = CommonWidth;
    parameter       OddInputPoint     = CommonPoint;
    parameter       OddKWidth         = CommonWidth;
    parameter       OddKPoint         = CommonPoint;
    parameter       OddMultOutWidth   = CommonWidth;
    parameter       OddMultOutPoint   = CommonPoint;
    parameter       OddBuffWidth      = CommonWidth;
    parameter       OddBuffPoint      = CommonPoint;
    parameter       OddOutputWidth    = CommonWidth;
    parameter       OddOutputPoint    = CommonPoint;

    parameter       EvenInputWidth    = CommonWidth;
    parameter       EvenInputPoint    = CommonPoint;
    parameter       EvenKWidth        = CommonWidth;
    parameter       EvenKPoint        = CommonPoint;
    parameter       EvenMultOutWidth  = CommonWidth;
    parameter       EvenMultOutPoint  = CommonPoint;
    parameter       EvenBuffWidth     = CommonWidth;
    parameter       EvenBuffPoint     = CommonPoint;
    parameter       EvenOutputWidth   = CommonWidth;
    parameter       EvenOutputPoint   = CommonPoint;

    typedef real real_line_t[0:SideSize-1];
    real_line_t src_data [0:SideSize-1];
    real_line_t coeff    [-4:SideSize-1];

    logic                                   clk_i;
    logic                                   rst_i;
    logic                                   s_ready_o;
    logic                                   s_valid_i;
    logic                                   s_sof_i;
    logic                                   s_eol_i;
    logic   [OddInputWidth-1:0]             s_data_odd_i;
    logic   [EvenInputWidth-1:0]            s_data_even_i;
    logic                                   m_ready_i;
    logic                                   m_valid_o;
    logic                                   m_sof_o;
    logic                                   m_eol_o;
    logic   [OddOutputWidth-1:0]            m_data_odd_o;
    logic   [EvenOutputWidth-1:0]           m_data_even_o;

    initial begin
        if (FilterType == "Column") begin
            src_data[ 0] = {   0.39,    0.39,   0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
            src_data[ 1] = {   0.0078,  0.0078, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
            src_data[ 2] = {  -0.039,  -0.039,  0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
            src_data[ 3] = {   0.01,    0.01,   0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
            src_data[ 4] = {  -0.2,    -0.2,    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
            src_data[ 5] = {   0.05,    0.05,   0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
            src_data[ 6] = {   0.0,     0.0,    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
            src_data[ 7] = {   0.0,     0.0,    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
            src_data[ 8] = {   0.0,     0.0,    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
            src_data[ 9] = {   0.0,     0.0,    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
            src_data[10] = {   0.0,     0.0,    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
            src_data[11] = {   0.0,     0.0,    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
            src_data[12] = {   0.0,     0.0,    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
            src_data[13] = {   0.0,     0.0,    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
            src_data[14] = {   0.0,     0.0,    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
            src_data[15] = {   0.0,     0.0,    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
        end else begin
            src_data[ 0] = { 0.39,   0.0, -0.039, 0.0, -0.2,  0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
            src_data[ 1] = { 0.0078, 0.0,  0.01,  0.0,  0.05, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
            src_data[ 2] = { 0.0,    0.0,  0.0,   0.0,  0.0,  0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
            src_data[ 3] = { 0.0,    0.0,  0.0,   0.0,  0.0,  0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
            src_data[ 4] = { 0.0,    0.0,  0.0,   0.0,  0.0,  0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
            src_data[ 5] = { 0.0,    0.0,  0.0,   0.0,  0.0,  0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
            src_data[ 6] = { 0.0,    0.0,  0.0,   0.0,  0.0,  0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
            src_data[ 7] = { 0.0,    0.0,  0.0,   0.0,  0.0,  0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
            src_data[ 8] = { 0.0,    0.0,  0.0,   0.0,  0.0,  0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
            src_data[ 9] = { 0.0,    0.0,  0.0,   0.0,  0.0,  0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
            src_data[10] = { 0.0,    0.0,  0.0,   0.0,  0.0,  0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
            src_data[11] = { 0.0,    0.0,  0.0,   0.0,  0.0,  0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
            src_data[12] = { 0.0,    0.0,  0.0,   0.0,  0.0,  0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
            src_data[13] = { 0.0,    0.0,  0.0,   0.0,  0.0,  0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
            src_data[14] = { 0.0,    0.0,  0.0,   0.0,  0.0,  0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
            src_data[15] = { 0.0,    0.0,  0.0,   0.0,  0.0,  0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
        end
    end

    logic clk;
    logic rst;
    always #(ClkPeriod/2) clk = ~clk;
    assign clk_i = clk;
    assign rst_i = rst;

    function int ToFixed(real a, int point);
        ToFixed = $rtoi(a * (2.0 ** point));  
    endfunction

    function real ToReal(int num, int point);
        ToReal = $itor(num) / (2.0 ** point);
    endfunction

    task WriteLine(real_line_t even_line, real_line_t odd_line, logic start_frame);
        s_sof_i = start_frame;
        s_eol_i = 0;

        if (FilterType == "Row") begin
            for (int i = 4; i > 1; i--) begin
                s_valid_i = 1;
                s_data_even_i = ToFixed(even_line[i], EvenInputPoint);
                s_data_odd_i  = ToFixed(odd_line[i-2], OddInputPoint);
                if (i == SideSize - 1) begin
                    s_eol_i = 1;
                end
                @(negedge clk);
                s_sof_i = 0;
            end
            s_data_even_i = 0;
            s_data_odd_i = 0;
            @(negedge clk);
        end

        for (int i = 0; i < SideSize; i++) begin
            s_valid_i = 1;
            s_data_even_i = ToFixed(even_line[i], EvenInputPoint);
            s_data_odd_i  = ToFixed(odd_line[i],  OddInputPoint);
            if (i == SideSize - 1) begin
                s_eol_i = 1;
            end
            @(negedge clk);
            s_sof_i = 0;
            s_eol_i = 0;
        end

        s_valid_i = 0;
        s_data_even_i = 'hx;
        s_data_odd_i = 'hx;
    endtask

    initial begin
        clk = 0;
        rst = 1;
        s_valid_i = 0;
        s_eol_i = 0;
        s_sof_i = 0;
        @(negedge clk);
        @(negedge clk);
        rst = 0;
        @(negedge clk);
        @(negedge clk);

        if (FilterType == "Column") begin
            WriteLine(src_data[4], src_data[3], 1);
            WriteLine(src_data[2], src_data[1], 0);
            for (int i = 0; i < SideSize; i+=2) begin
                WriteLine(src_data[i], src_data[i+1], 0);
            end
            WriteLine(src_data[SideSize-2], src_data[SideSize-3], 0);
            WriteLine(src_data[SideSize-4], src_data[SideSize-5], 0);
        end else begin
            WriteLine(src_data[0], src_data[1], 1);
        end

        for (int i = 0; i < 20; i++) @(negedge clk);


        for (int y = $left(coeff, 1); y < $right(coeff, 1); y++) begin
            for (int x = $left(coeff, 2); x < $right(coeff, 2); x++) begin
                $write("\t%3.3f", coeff[y][x]);
            end
            $write("\n");
        end
    end

    int x, y;
    always @(posedge clk) begin
        if (rst) begin
            x = 0;
            y = $left(coeff, 1);
            $display("\t\t\t\t%i", $left(coeff, 1));
        end else if (m_ready_i && m_valid_o) begin
            if (m_sof_o) begin 
                x = 0;
                y = $left(coeff, 1);
            end

            coeff[y][x]   = ToReal(m_data_even_o, EvenOutputPoint);
            coeff[y+1][x] = ToReal(m_data_odd_o, OddOutputPoint);
            
            x = x + 1;
            if (m_eol_o) begin
                x = 0;
                y = y + 2;
            end
        end
    end

    assign m_ready_i = 1;

    ProcessingUnit1D #(
        .MaximumSideSize(MaximumSideSize),
        .FilterType(FilterType),
        
        .OddK(OddK),
        .EvenK(EvenK),
        
        .InputReg(InputReg),
        .InputSkidBuff(InputSkidBuff),
        
        .OutputReg(OutputReg),
        .OutputSkidBuff(OutputSkidBuff),

        .OddInputWidth(OddInputWidth),
        .OddInputPoint(OddInputPoint),
        .OddKWidth(OddKWidth),
        .OddKPoint(OddKPoint),
        .OddMultOutWidth(OddMultOutWidth),
        .OddMultOutPoint(OddMultOutPoint),
        .OddBuffWidth(OddBuffWidth),
        .OddBuffPoint(OddBuffPoint),
        .OddOutputWidth(OddOutputWidth),
        .OddOutputPoint(OddOutputPoint),
        .EvenInputWidth(EvenInputWidth),
        .EvenInputPoint(EvenInputPoint),
        .EvenKWidth(EvenKWidth),
        .EvenKPoint(EvenKPoint),
        .EvenMultOutWidth(EvenMultOutWidth),
        .EvenMultOutPoint(EvenMultOutPoint),
        .EvenBuffWidth(EvenBuffWidth),
        .EvenBuffPoint(EvenBuffPoint),
        .EvenOutputWidth(EvenOutputWidth),
        .EvenOutputPoint(EvenOutputPoint)
    ) DUT (
        .*
    );

endmodule
