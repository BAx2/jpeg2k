module tb_expander ();
    
    localparam DataWidth = 8;
    
    logic                                   clk_i;
    logic                                   rst_i;
    logic                                   s_ready_o;
    logic                                   s_valid_i;
    logic                                   s_sof_i;
    logic                                   s_eol_i;
    logic   [2*DataWidth-1:0]               s_data_i;
    logic                                   m_ready_i;
    logic                                   m_valid_o;
    logic                                   m_sof_o;
    logic                                   m_eol_o;
    logic   [2*DataWidth-1:0]               m_data_o;

    localparam DinSize = 16;
    logic [2*DataWidth-1:0] test_din            [0:DinSize/2-1];
    int                     test_dout_size;
    logic [2*DataWidth-1:0] test_dout           [0:2*DinSize];
    int                     expected_dout_size;
    logic [2*DataWidth-1:0] expected_dout       [0:DinSize+8];
    
    logic [DataWidth-1:0] even_out, odd_out;

    logic   end_sim;

    always #(5) clk_i = !clk_i;

    always @(posedge clk_i) begin
        if (m_valid_o & m_ready_i) begin
            even_out = m_data_o[DataWidth-1:0];
            odd_out  = m_data_o[2*DataWidth-1:DataWidth];
        end
    end

    initial begin
        test_din[0] = { 8'd00, 8'd01 };
        test_din[1] = { 8'd00, 8'd02 };
        test_din[2] = { 8'd00, 8'd03 };
        test_din[3] = { 8'd00, 8'd04 };
        test_din[4] = { 8'd00, 8'd05 };
        test_din[5] = { 8'd00, 8'd06 };
        test_din[6] = { 8'd00, 8'd07 };
        test_din[7] = { 8'd00, 8'd08 };

        expected_dout_size = 16;

        expected_dout[0]  = { 8'd00, 8'd05 };
        expected_dout[1]  = { 8'd00, 8'd04 };
        expected_dout[2]  = { 8'd00, 8'd03 };
        expected_dout[3]  = { 8'd00, 8'd02 };
        
        expected_dout[4]  = { 8'd00, 8'd01 };
        expected_dout[5]  = { 8'd00, 8'd02 };
        expected_dout[6]  = { 8'd00, 8'd03 };
        expected_dout[7]  = { 8'd00, 8'd04 };
        expected_dout[8]  = { 8'd00, 8'd05 };
        expected_dout[9]  = { 8'd00, 8'd06 };
        expected_dout[10] = { 8'd00, 8'd07 };
        expected_dout[11] = { 8'd00, 8'd08 };

        expected_dout[12] = { 8'd00, 8'd07 };
        expected_dout[13] = { 8'd00, 8'd06 };
        expected_dout[14] = { 8'd00, 8'd05 };
        expected_dout[15] = { 8'd00, 8'd04 };
    end

    always @(posedge clk_i) begin
        if (m_valid_o & m_ready_i) begin
            test_dout[test_dout_size] = m_data_o;
            test_dout_size++;
        end
    end

    task automatic WriteAxis(logic [2*DataWidth-1:0] data, logic sof, logic eol);
        s_data_i = data;
        s_sof_i = sof;
        s_eol_i = eol;
        s_valid_i = 1;
        while (!(s_valid_i & s_ready_o)) @(negedge clk_i);
        @(negedge clk_i);
        s_valid_i = 0;
        s_sof_i = 0;
        s_eol_i = 0;
    endtask //automatic

    initial begin
        end_sim = 0;
        clk_i = 0;
        rst_i = 1;

        @(negedge clk_i);
        @(negedge clk_i);

        rst_i = 0;

        for (int i = 0; i < DinSize/2; i++)
            WriteAxis(test_din[i], i == 0, (i == DinSize/2-1));

        end_sim = 1;
        for (int i = 0; i < 20; i++)
            @(negedge clk_i);

        assert (test_dout_size == expected_dout_size) begin
            for (int i = 0; i < test_dout_size; i++) begin
                assert (test_dout[i] == expected_dout[i]) 
                else   $display("test_dout[%d] != expected_dout[%d] (0x%h != 0x%h)", i, i, test_dout[i], expected_dout[i]);
            end
        end
        else   $display("expected size != output size (%d != %d)", expected_dout_size, test_dout_size);
    end

    always @(posedge clk_i) begin
        m_ready_i = $urandom_range(0, 1);
        s_valid_i = $urandom_range(0, 1) & !end_sim;
        // m_ready_i = 1;
        // s_valid_i = !end_sim;
    end

   
    BorderExpander #(
        .DataWidth(DataWidth)
    ) DUT (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .s_ready_o(s_ready_o),
        .s_valid_i(s_valid_i),
        .s_sof_i(s_sof_i),
        .s_eol_i(s_eol_i),
        .s_data_i(s_data_i),
        .m_ready_i(m_ready_i),
        .m_valid_o(m_valid_o),
        .m_sof_o(m_sof_o),
        .m_eol_o(m_eol_o),
        .m_data_o(m_data_o)
    );

endmodule