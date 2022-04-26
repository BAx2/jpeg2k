`timescale 1ns/1ns

module tb_Dma ();
    parameter DMA_DATA_WIDTH_SRC = 64;
    parameter DMA_AXI_ADDR_WIDTH = 32;
    parameter MEM_DEPTH = 64;

    logic                              m_axi_aclk;
    logic                              m_axi_aresetn;
    logic  [DMA_AXI_ADDR_WIDTH-1:0]    m_mm2s_axi_araddr; 
    logic  [ 1:0]                      m_mm2s_axi_arburst;
    logic  [ 3:0]                      m_mm2s_axi_arcache;
    logic  [ 7:0]                      m_mm2s_axi_arlen;
    logic  [ 2:0]                      m_mm2s_axi_arprot;
    logic                              m_mm2s_axi_arready;
    logic  [ 2:0]                      m_mm2s_axi_arsize;
    logic                              m_mm2s_axi_arvalid;
    logic  [DMA_DATA_WIDTH_SRC-1:0]    m_mm2s_axi_rdata;
    logic                              m_mm2s_axi_rlast;
    logic                              m_mm2s_axi_rready;
    logic  [ 1:0]                      m_mm2s_axi_rresp;
    logic                              m_mm2s_axi_rvalid;

    logic  [DMA_AXI_ADDR_WIDTH-1:0]    m_s2mm_axi_awaddr; 
    logic  [ 1:0]                      m_s2mm_axi_awburst;
    logic  [ 3:0]                      m_s2mm_axi_awcache;
    logic  [ 7:0]                      m_s2mm_axi_awlen;
    logic  [ 2:0]                      m_s2mm_axi_awprot;
    logic                              m_s2mm_axi_awready;
    logic  [ 2:0]                      m_s2mm_axi_awsize;
    logic                              m_s2mm_axi_awvalid;
    logic  [DMA_DATA_WIDTH_SRC-1:0]    m_s2mm_axi_wdata;
    logic                              m_s2mm_axi_wlast;
    logic                              m_s2mm_axi_wready;
    logic  [ 3:0]                      m_s2mm_axi_wstrb;
    logic                              m_s2mm_axi_wvalid;
    logic                              m_s2mm_axi_bready;
    logic  [ 1:0]                      m_s2mm_axi_bresp;
    logic                              m_s2mm_axi_bvalid;

    // streams
    logic  [DMA_DATA_WIDTH_SRC-1:0]    m_mm2s_axis_tdata;    
    logic                              m_mm2s_axis_tvalid;    
    logic                              m_mm2s_axis_tlast;    
    logic                              m_mm2s_axis_tready;    

    logic  [DMA_DATA_WIDTH_SRC-1:0]    s_s2mm_axis_tdata;
    logic                              s_s2mm_axis_tvalid;
    logic                              s_s2mm_axis_tlast;
    logic                              s_s2mm_axis_tready;
    
    // control
    logic                              read_start_i;
    logic  [DMA_AXI_ADDR_WIDTH-1:0]    read_addr_i;
    logic  [ 7:0]                      read_len_i;
    logic  [ 2:0]                      read_size_i;
    logic                              read_busy_o;

    logic                              write_start_i;
    logic  [DMA_AXI_ADDR_WIDTH-1:0]    write_addr_i;
    logic  [ 7:0]                      write_len_i;
    logic  [ 2:0]                      write_size_i;
    logic                              write_busy_o;

    logic                              start;
    logic  [ 7:0]                      len;
    logic  [ 2:0]                      size;

    always #5 m_axi_aclk = !m_axi_aclk;

    `define WAIT_WHILE(signal) while ((signal)) @(posedge m_axi_aclk);

    assign write_start_i = start,
           read_start_i = start,
           write_len_i = len,
           read_len_i = len,
           write_size_i = size,
           read_size_i = size;

    initial begin
        $timeformat(-9, 0, " ns", 20);
        $display("\t\tTime: %5t \t Reset!", $time);
        m_axi_aclk = 1;
        m_axi_aresetn = 0;
        read_addr_i = 0;
        write_addr_i = 0;
        start = 0;
        len = 0;
        size = 3; // 8 byte (64 bit) at one clock cycle

        @(posedge m_axi_aclk);
        @(posedge m_axi_aclk);

        m_axi_aresetn = 1;

        @(posedge m_axi_aclk);
        $display("\t\tTime: %5t \t Start!", $time);
        start = 1;
        len = 16 - 1;
        write_addr_i = 32;
        @(posedge m_axi_aclk);
        start = 0;
        @(posedge m_axi_aclk);
        `WAIT_WHILE(write_busy_o);
        $display("\t\tTime: %5t \t Finish!", $time);
    end

    assign s_s2mm_axis_tdata  = -m_mm2s_axis_tdata,
           s_s2mm_axis_tvalid = m_mm2s_axis_tvalid,
           s_s2mm_axis_tlast  = m_mm2s_axis_tlast,
           m_mm2s_axis_tready = s_s2mm_axis_tready;

    Dma
    #(
        .DMA_DATA_WIDTH_SRC(DMA_DATA_WIDTH_SRC),
        .DMA_AXI_ADDR_WIDTH(DMA_AXI_ADDR_WIDTH)
    ) DUT (
        .*
    );

    AxiMemory #(
        .DMA_DATA_WIDTH_SRC(DMA_DATA_WIDTH_SRC),
        .DMA_AXI_ADDR_WIDTH(DMA_AXI_ADDR_WIDTH),
        .MEM_DEPTH(MEM_DEPTH)
    ) AxiMemInst (
        .mem_o(),
        .*
    );

endmodule