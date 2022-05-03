module tb_pu ();

    localparam ClkPeriod   = 10ns;
    
    localparam CommonWidth = 16;
    localparam CommonPoint = 12;

    localparam SideSize    = 16;

    parameter       MaximumSideSize   = 512;
    parameter       FilterType        = "Column"; // "Column" "Row"
    parameter real  OddK              = 1.0 / (Coefficient::Alpha);
    parameter real  EvenK             = 1.0 / (Coefficient::Alpha * Coefficient::Beta) + 1.0;
    parameter bit   InputReg          = 1;
    parameter bit   InputSkidBuff     = 1;
    parameter bit   OutputReg         = 1;
    parameter bit   OutputSkidBuff    = 1;

    localparam      CoefficientWidth  = 16;
    parameter       OddKWidth         = CoefficientWidth;
    parameter       OddKPoint         = CoefficientWidth - 1;
    parameter       EvenKWidth        = CoefficientWidth;
    parameter       EvenKPoint        = CoefficientWidth - 5;

    parameter       OddInputWidth     = CommonWidth;
    parameter       OddInputPoint     = CommonPoint;
    parameter       OddMultOutWidth   = CommonWidth;
    parameter       OddMultOutPoint   = CommonPoint;
    parameter       OddBuffWidth      = CommonWidth;
    parameter       OddBuffPoint      = CommonPoint;
    parameter       OddOutputWidth    = CommonWidth;
    parameter       OddOutputPoint    = CommonPoint;

    parameter       EvenInputWidth    = CommonWidth;
    parameter       EvenInputPoint    = CommonPoint;
    parameter       EvenMultOutWidth  = CommonWidth;
    parameter       EvenMultOutPoint  = CommonPoint;
    parameter       EvenBuffWidth     = CommonWidth;
    parameter       EvenBuffPoint     = CommonPoint;
    parameter       EvenOutputWidth   = CommonWidth;
    parameter       EvenOutputPoint   = CommonPoint;

    typedef real real_line_t[0:SideSize-1];
    real_line_t src_data [0:SideSize-1];
    real_line_t coeff    [-4:SideSize-1];
    real_line_t expected [0:SideSize-1];

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
    logic signed [OddOutputWidth-1:0]       m_data_odd_o;
    logic signed [EvenOutputWidth-1:0]      m_data_even_o;

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

    function real Abs(real a);
        Abs = a > 0 ? a : -a;
    endfunction

    function real Max(real a, real b);
        Max = a > b ? a : b;
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
        real max_abs_diff;
        max_abs_diff = 0;

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

        $display("Odd k: %f", OddK);
        $display("Even k: %f", EvenK);

        if (FilterType == "Column") begin
            WriteLine(src_data[2], src_data[1], 1);
            for (int i = 0; i < SideSize; i+=2) begin
                WriteLine(src_data[i], src_data[i+1], 0);
            end
            WriteLine(src_data[SideSize-2], src_data[SideSize-3], 0);
        end else begin
            WriteLine(src_data[0], src_data[1], 1);
        end

        for (int i = 0; i < 20; i++) @(negedge clk);


        for (int y = 0; y <= $right(coeff, 1); y++) begin
            for (int x = $left(coeff, 2); x <= $right(coeff, 2); x++) begin
                real diff;
                diff = coeff[y][x] - expected[y][x];
                max_abs_diff = Max(max_abs_diff, Abs(diff));
                $write("\t%3.3f", coeff[y][x]);
                // $write("\t%3.3f", diff);
            end
            $write("\n");
        end

        $display("max_abs_diff: %f", max_abs_diff);
    end

    int x, y;
    always @(posedge clk) begin
        if (rst) begin
            x = 0;
            y = $left(coeff, 1);
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


    initial begin
        if (FilterType == "Column") begin
            src_data[ 0] = { 0.048,  0.215,  0.102,  0.044, -0.076,  0.145, -0.062,  0.391,  0.463, -0.116,  0.291,  0.028,  0.068,  0.425, -0.428, -0.412}; 
            src_data[ 1] = {-0.479,  0.332,  0.278,  0.37,   0.478,  0.299, -0.038,  0.28,  -0.381,  0.139, -0.356,  0.444,  0.021, -0.085, -0.235,  0.274}; 
            src_data[ 2] = {-0.043,  0.068, -0.481,  0.117,  0.112,  0.116,  0.443,  0.181, -0.14,  -0.062,  0.197, -0.439,  0.166,  0.17,  -0.289, -0.371}; 
            src_data[ 3] = {-0.184, -0.136,  0.07,  -0.061,  0.488, -0.397, -0.291, -0.338,  0.153, -0.246, -0.033, -0.255, -0.341, -0.389,  0.156, -0.361}; 
            src_data[ 4] = {-0.303, -0.131,  0.32,  -0.402,  0.337, -0.403,  0.476, -0.031,  0.476,  0.104,  0.239, -0.46,  -0.217, -0.379, -0.203, -0.381}; 
            src_data[ 5] = {-0.182, -0.085, -0.435,  0.192,  0.066, -0.234,  0.023, -0.406,  0.075,  0.429, -0.181,  0.167, -0.368,  0.216, -0.21,  -0.316}; 
            src_data[ 6] = { 0.086, -0.479,  0.328, -0.495,  0.177, -0.229,  0.235,  0.462, -0.251,  0.076,  0.092,  0.072, -0.276,  0.452, -0.052,  0.346}; 
            src_data[ 7] = { 0.199, -0.202,  0.313, -0.103,  0.381,  0.081,  0.381,  0.192,  0.225,  0.001,  0.456,  0.143, -0.076,  0.106, -0.48,  -0.198}; 
            src_data[ 8] = { 0.16,  -0.209,  0.118, -0.071, -0.364, -0.201,  0.069,  0.09,   0.074,  0.153,  0.152, -0.068,  0.396, -0.132, -0.064,  0.391}; 
            src_data[ 9] = { 0.306,  0.203, -0.399,  0.419,  0.214,  0.498, -0.35,   0.368, -0.337,  0.115, -0.376,  0.348,  0.307,  0.069, -0.092, -0.43 }; 
            src_data[10] = { 0.197, -0.046,  0.222,  0.366,  0.475,  0.355, -0.488, -0.14,   0.229, -0.328,  0.021, -0.445, -0.3,   -0.481,  0.293, -0.276}; 
            src_data[11] = {-0.154,  0.428,  0.204, -0.468, -0.335,  0.121,  0.077, -0.262,  0.434,  0.113,  0.035,  0.089,  0.23,  -0.188, -0.101, -0.29 }; 
            src_data[12] = {-0.313,  0.444,  0.239, -0.009, -0.272, -0.245, -0.441, -0.065, -0.188,  0.196, -0.122, -0.32,  -0.475, -0.432,  0.179, -0.046}; 
            src_data[13] = { 0.036,  0.396,  0.49,  -0.283,  0.163, -0.236, -0.479,  0.258, -0.179, -0.116,  0.088,  0.331,  0.128,  0.372, -0.226,  0.298}; 
            src_data[14] = {-0.314,  0.452,  0.187, -0.284,  0.447,  0.23,  -0.246, -0.286,  0.018, -0.474, -0.292, -0.075, -0.125, -0.036, -0.222,  0.086}; 
            src_data[15] = { 0.363, -0.382,  0.017, -0.367,  0.216, -0.103,  0.065, -0.316, -0.355, -0.011, -0.144,  0.44,   0.265,  0.248,  0.403, -0.416};
            
            expected[ 0] = { 1.1851843,  2.705873,   0.1052626,  0.3790571, -1.4351235,  1.8704833,  0.072115,   5.443842,   6.6361152, -1.9116694,  4.8877913, -1.0486516,  1.2507208,  6.3546806, -6.2308838, -6.8142957}; 
            expected[ 1] = { 0.3069921,  0.0736861, -0.5542689, -0.0722715, -0.2653616,  0.0724914,  0.4049576,  0.3954702,  0.5632066, -0.2656344,  0.712445,  -0.6909258,  0.2207603,  0.6485894, -0.568841,  -0.955747 }; 
            expected[ 2] = {-0.4347028,  0.9056294, -6.4833033,  1.0734872,  1.2087726,  1.4161859,  6.7791243,  2.9124676, -0.8632549, -0.8063406,  3.5135512, -6.6532594,  2.360149,   2.7078405, -4.5982946, -5.8950512}; 
            expected[ 3] = {-0.2299947,  0.0227431, -0.2051325, -0.2465417,  0.1413338, -0.0367059,  1.1024649,  0.3630967,  0.2395391,  0.1970941,  0.4568053, -0.7382318,  0.1639881,  0.0362503, -0.5903523, -0.5244026}; 
            expected[ 4] = {-3.9379516, -2.0925681,  4.5251205, -6.0483924,  4.6240245, -5.3168791,  7.4633662,  0.6811648,  6.0816562,  1.3442256,  3.7460202, -6.7055211, -2.6793022, -4.5370313, -3.1286558, -4.8940777}; 
            expected[ 5] = {-0.1022556, -0.5564106,  0.9222517, -1.018049,   0.4723894, -0.4844715,  0.6964993,  0.6869682,  0.1777152, -0.0904689,  0.4451139, -0.4932874, -0.2609894, -0.0631801, -0.1226026,  0.1642265}; 
            expected[ 6] = { 1.0416825, -6.8171589,  5.0741179, -7.4096133,  2.1514835, -3.69064,    3.5567937,  6.6157211, -3.1280401,  1.042301,   1.4964229,  0.2773566, -3.3774753,  5.5687926, -0.5547803,  5.1434597}; 
            expected[ 7] = { 0.1205377, -0.5606463,  0.2486649, -0.5010622, -0.4272066, -0.4810676,  0.0637934,  0.430951,  -0.3188543,  0.2283695, -0.0434914, -0.0861563,  0.1679152,  0.2531709,  0.1866225,  0.8618318}; 
            expected[ 8] = { 2.1886165, -3.4307313,  2.2444204, -1.3151268, -4.7827273, -3.0329393,  0.6865559,  1.2199407,  1.0772122,  1.8015668,  2.1753635, -1.6277579,  4.7827645, -1.9741317, -0.2879751,  5.9008328}; 
            expected[ 9] = { 0.1640781, -0.3829841,  0.591555,   0.0308357, -0.0239192, -0.1599709, -0.1983377, -0.2820106,  0.5154662, -0.2475033,  0.4100543, -0.7324013, -0.0975523, -0.656502,   0.2870027,  0.3860994}; 
            expected[10] = { 2.4894703, -0.8022227,  3.5657413,  5.0382942,  6.042788,   4.0982445, -6.9830854, -1.9878297,  3.007946,  -4.353947,   0.5368882, -6.8490144, -4.5875602, -7.1748768,  4.3093807, -3.0374673}; 
            expected[11] = {-0.0189086,  0.1281616,  0.3323854,  0.652057,   0.4142053,  0.0337139, -0.9775457, -0.0398185, -0.2326212, -0.2032424, -0.1230662, -0.8211113, -0.9200066, -0.7944728,  0.5356768, -0.1391656}; 
            expected[12] = {-4.3933066,  6.0580998,  3.2935592,  0.4303781, -2.7503614, -2.7479977, -6.6104554, -1.3269784, -2.526969,   1.9242922, -2.0443475, -5.232796,  -7.2532079, -6.6378071,  2.7652623, -0.8344439}; 
            expected[13] = {-0.6496967,  0.6463364,  0.1170728, -0.1145788,  0.0722344,  0.1337894, -0.3850079, -0.5136596, -0.057147,  -0.2048662, -0.4694808, -0.6036835, -0.6806993, -0.7025325,  0.0994848, -0.1478782}; 
            expected[14] = {-5.2431563,  7.1699754,  2.7056557, -3.8307998,  6.1493561,  3.3957281, -3.8453891, -4.2898343,  0.4168676, -6.7865331, -4.4374952, -1.9235878, -2.5852727, -1.3592876, -3.240393,   1.3097951}; 
            expected[15] = {-0.8568583,  1.1448371,  0.3632821, -0.3366199,  0.7578199,  0.5249378, -0.5329801, -0.3727735,  0.2598146, -0.9410649, -0.4932132, -0.427404,  -0.4170729, -0.228355,  -0.6980768,  0.4342729};

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
