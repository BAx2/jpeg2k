module tb_pu ();

    localparam ClkPeriod    = 10ns;
    localparam DataWidth    = 24;
    localparam Point        = 16;
    localparam SideSize     = 16;

    typedef logic [DataWidth-1:0] coeff_t;
    typedef coeff_t [0:SideSize-1] coeff_line_t;

    real    src_data [0:SideSize-1][0:SideSize-1];
    coeff_line_t in_data[0:SideSize-1];

    coeff_t even, odd;
    logic   sof, eol;
    logic   ready, valid;

    logic m_ready;
    logic m_valid;
    logic m_sof;
    logic m_eol;
    logic [2*DataWidth-1:0] m_data;
    
    logic signed [DataWidth-1:0] h_int, l_int;
    real    l, h;

    assign l_int = m_data[DataWidth-1:0];
    assign h_int = m_data[2*DataWidth-1:DataWidth];
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

    task WriteLine(coeff_line_t even_line, coeff_line_t odd_line, logic start_frame);
        sof = start_frame;
        eol = 0;
        for (int i = 0; i < SideSize; i++) begin
            valid = 1;
            even = even_line[i];
            odd = odd_line[i];
            if (i == SideSize - 1) begin
                eol = 1;
            end
            @(negedge clk);
            sof = 0;
            eol = 0;
        end
        valid = 0;
        even = 'hx;
        odd = 'hx;
    endtask

    initial begin
        clk = 0;
        rst = 1;
        valid = 0;
        eol = 0;
        sof = 0;
        @(negedge clk);
        @(negedge clk);
        rst = 0;
        @(negedge clk);
        @(negedge clk);

        WriteLine(in_data[4], in_data[3], 1);
        // @(negedge clk);
        WriteLine(in_data[2], in_data[1], 0);
        // @(negedge clk);
        for (int i = 0; i < SideSize; i+=2) begin
            WriteLine(in_data[i], in_data[i+1], 0);
            // @(negedge clk);
        end
        WriteLine(in_data[SideSize-2], in_data[SideSize-3], 0);
        // @(negedge clk);
        WriteLine(in_data[SideSize-4], in_data[SideSize-5], 0);
    end

    assign m_ready = 1;

    ProcessingUnit1D #(
        .DataWidth(DataWidth),
        .Point(Point),
        .MaximumSideSize(2*SideSize),
        .Alpha(Coefficient::Alpha),
        .Beta(Coefficient::Beta),
        .InputReg(1)
    ) DUT (
        .clk_i(clk),
        .rst_i(rst),
        
        .s_ready_o(ready),
        .s_valid_i(valid),
        .s_sof_i(sof),
        .s_eol_i(eol),
        .s_data_i({ odd, even }),
        
        .m_ready_i(m_ready),
        .m_valid_o(m_valid),
        .m_sof_o(m_sof),
        .m_eol_o(m_eol),
        .m_data_o(m_data)
    );

endmodule