module tb_dwt ();

    localparam ClkPeriod    = 10ns;
    localparam DataWidth    = 24;
    localparam Point        = 16;
    localparam SideSize     = 16;

    typedef logic [DataWidth-1:0] coeff_t;
    typedef coeff_t [0:SideSize-1] coeff_line_t;

    real    src_data [0:SideSize-1][0:SideSize-1];
    coeff_line_t in_data[0:SideSize-1];
    // coeff_line_t out_data[0:SideSize-1];
    // real    dst_data [0:SideSize-1][0:SideSize-1];

    logic   s_sof_i, s_eol_i;
    logic   s_ready_o, s_valid_i;
    logic [2*DataWidth-1:0] s_data_i;
    logic [2*DataWidth-1:0] out;
    logic signed [DataWidth-1:0] h_int, l_int;
    real    l, h;

    assign l_int = out[DataWidth-1:0];
    assign h_int = out[2*DataWidth-1:DataWidth];
    assign l = l_int / (2.0 ** Point); 
    assign h = h_int / (2.0 ** Point); 

    initial begin
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


        for (int y = 0; y < SideSize; y++) begin
            for (int x = 0; x < SideSize; x++) begin
                in_data[y][x] = $rtoi(src_data[y][x] * (2.0**Point));
            end
        end
    end

    logic clk;
    logic rst;
    always #(ClkPeriod/2) clk = ~clk;


    task automatic WriteAxis(logic [2*DataWidth-1:0] data, logic sof, logic eol);
        s_data_i = data;
        s_sof_i = sof;
        s_eol_i = eol;
        s_valid_i = 1;
        while (!(s_valid_i & s_ready_o)) @(negedge clk);
        @(negedge clk);
        s_valid_i = 0;
        s_sof_i = 0;
        s_eol_i = 0;
    endtask //automatic

    task WriteLine(coeff_line_t even_line, coeff_line_t odd_line, logic start_frame);
        logic sof, eol; 
        coeff_t even, odd;

        sof = start_frame;
        eol = 0;
        for (int i = 0; i < SideSize; i++) begin
            even = even_line[i];
            odd = odd_line[i];
            if (i == SideSize - 1) begin
                eol = 1;
            end
            WriteAxis({ odd, even }, sof, eol);
        end
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

        WriteLine(in_data[4], in_data[3], 1);
        @(negedge clk);
        WriteLine(in_data[2], in_data[1], 0);
        @(negedge clk);
        for (int i = 0; i < SideSize; i+=2) begin
            WriteLine(in_data[i], in_data[i+1], 0);
            @(negedge clk);
        end
        WriteLine(in_data[SideSize-2], in_data[SideSize-3], 0);
        @(negedge clk);
        WriteLine(in_data[SideSize-4], in_data[SideSize-5], 0);
    end


    Dwt97 #(
        .DataWidth(DataWidth),
        .Point(Point),
        .MaximumSideSize(2*SideSize)
    ) DUT (
        .clk_i(clk),
        .rst_i(rst),
        
        .s_ready_o(s_ready_o), //ready),
        .s_valid_i(s_valid_i), //valid),
        .s_sof_i(s_sof_i), //sof),
        .s_eol_i(s_eol_i), //eol),
        .s_data_i(s_data_i), //{ odd, even }),
        
        .m_ready_i(1),
        .m_valid_o(),
        .m_sof_o(),
        .m_eol_o(),
        .m_data_o(out)
    );

endmodule