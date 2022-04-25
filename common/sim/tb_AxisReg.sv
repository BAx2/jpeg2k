module tb_AxisReg ();

    localparam DataWidth = 8;
    localparam Transperent = 0;
    localparam Pipelined = 1;

    logic                       clk_i;
    logic                       rst_i;
    logic   [DataWidth-1:0]     s_data_i;
    logic                       s_valid_i;
    logic                       s_ready_o;
    logic                       m_ready_i;
    logic                       m_valid_o;
    logic   [DataWidth-1:0]     m_data_o;

    logic   end_sim;
    localparam DinSize = 16;
    logic [2*DataWidth-1:0] test_dout [0:2*DinSize];

    always #5 clk_i = !clk_i;


    initial begin
        while (1) begin
            @(posedge clk_i); #2;
            m_ready_i = ($urandom_range(0, 1) | m_ready_i);
            s_valid_i = ($urandom_range(0, 1) | s_valid_i) & !end_sim;
            // m_ready_i = ($urandom_range(0, 1));
            // s_valid_i = ($urandom_range(0, 1)) & !end_sim;
            // m_ready_i = 1;
            // s_valid_i = !end_sim;
        end
    end

    task automatic WriteAxis(logic [2*DataWidth-1:0] data);
        s_data_i = data;
        s_valid_i = 1;
        while (!(s_valid_i & s_ready_o)) @(negedge clk_i);
        @(negedge clk_i);
        #2; s_valid_i = 0;
    endtask

    initial begin
        clk_i = 1;
        rst_i = 1;
        end_sim = 0;
        @(negedge clk_i);
        @(negedge clk_i);
        @(negedge clk_i);
        rst_i = 0;

        for (int i = 0; i < DinSize; i++) begin
            WriteAxis(i);
        end
        end_sim = 1;
    end

    int dout_cnt = 0;
    always @(posedge clk_i) begin
        if (m_valid_o & m_ready_i) begin
            test_dout[dout_cnt] = m_data_o;
            dout_cnt++;
            #2 m_ready_i = 0;
        end
    end

    logic valid_output;
    always_comb begin
        valid_output = 1;
        for (int i = 0; i < DinSize; i++)
            valid_output = valid_output & (test_dout[i] == i);
        valid_output = valid_output & (dout_cnt == DinSize);
    end

    AxisReg #(
        .DataWidth(DataWidth),
        .Transperent(Transperent),
        .Pipelined(Pipelined)
    ) DUT (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .s_data_i(s_data_i),
        .s_valid_i(s_valid_i),
        .s_ready_o(s_ready_o),
        .m_ready_i(m_ready_i),
        .m_valid_o(m_valid_o),
        .m_data_o(m_data_o)
    );

endmodule