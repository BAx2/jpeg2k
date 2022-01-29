module tb_transpose ();
    parameter DataWidth = 16;
    parameter SideSize = 8; // must be even
    logic                   clk_i;
    logic                   rst_i;
    logic                   s_ready_o;
    logic                   s_valid_i;
    logic                   s_sof_i;
    logic                   s_eol_i;
    logic [2*DataWidth-1:0] s_data_i;
    logic                   m_ready_i;
    logic                   m_valid_o;
    logic                   m_sof_o;
    logic                   m_eol_o;
    logic [2*DataWidth-1:0] m_data_o;

    always #5 clk_i = ~clk_i;

    logic stop;

    typedef logic [2*DataWidth-1:0] coeff_t;
    coeff_t din   [0:SideSize-1];
    coeff_t dout  [0:SideSize-1];

    // init input data
    initial begin
        for (int i = 0; i < SideSize; i++) begin
            din[i] = { DataWidth'(i*2+1),  DataWidth'(i*2) };
        end
    end

    // write
    initial begin
        s_sof_i = 0;
        s_eol_i = 0;
        s_data_i = 0;
        stop = 0;

        @(negedge rst_i);
        for (int i = 0; i < SideSize; i++) begin
            while (!(s_valid_i & s_ready_o)) @(negedge clk_i);
            s_data_i = din[i];
            s_sof_i = (i == 0);
            s_eol_i = (i == SideSize-1);
            @(negedge clk_i);
        end
        stop = 1;

        s_sof_i = 0;
        s_eol_i = 0;
        s_data_i = 0;
    end

    // read 
    int m_idx = 0;
    always @(posedge clk_i) begin
        if (m_valid_o & m_ready_i) begin
            dout[m_idx] <= m_data_o;
            assert (!(m_idx == SideSize-1 && !m_eol_o)) 
            else   $display("bad eol");
            m_idx <= (m_idx == SideSize-1) ? 0 : m_idx + 1;
        end
    end

    initial begin
        while (1) begin
            @(posedge clk_i); #2;
            s_valid_i = $urandom_range(0, 1) & !stop;
            // s_valid_i = 1 & !stop;
            m_ready_i = $urandom_range(0, 1);
            // m_ready_i = 1;
        end
    end

    initial begin
        clk_i = 0;
        rst_i = 1;
        @(negedge clk_i);
        @(negedge clk_i);
        @(negedge clk_i);
        rst_i = 0;
    end


    Transpose #(
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