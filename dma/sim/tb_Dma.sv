`timescale 1ns/1ns
`include "../rtl/reg_file/hw/DmaRegs_pkg.sv"

module tb_Dma ();
    parameter DMA_DATA_WIDTH_SRC = 64;
    parameter DMA_AXI_ADDR_WIDTH = 32;
    parameter MEM_DEPTH = 64;
    parameter AXIL_ADDR_W = 8;
    parameter AXIL_DATA_W = 32;
    parameter AXIL_STRB_W = AXIL_DATA_W / 8;


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
    AxiLite axi(m_axi_aclk);

    always #5 m_axi_aclk = !m_axi_aclk;

    `define WAIT_WHILE(signal) while ((signal)) @(posedge m_axi_aclk);

    typedef logic [AXIL_DATA_W-1:0] axil_data_t;
    axil_data_t  wdata;
    axil_data_t  rdata;

    initial begin
        logic        start;
        logic [ 7:0] len;
        logic [ 2:0] size;

        $timeformat(-9, 0, " ns", 20);
        $display("\t\tTime: %5t \t Reset!", $time);
        axi.Reset();
        m_axi_aclk = 1;
        m_axi_aresetn = 0;
        @(posedge m_axi_aclk);
        @(posedge m_axi_aclk);

        m_axi_aresetn = 1;

        @(posedge m_axi_aclk);
        $display("\t\tTime: %5t \t Start!", $time);

        axi.Write(DmaRegs_pkg::DMA_CSR_DEBUG_MM2S_ADDR_ADDR, 32'd00);
        axi.Write(DmaRegs_pkg::DMA_CSR_DEBUG_S2MM_ADDR_ADDR, 32'd32);

        start = 1;
        size = 3;
        len = 16 - 1;
        start = 1;
        wdata = {3'b0, start, 1'b0, size, len,
                 3'b0, start, 1'b0, size, len};
        axi.Write(DmaRegs_pkg::DMA_CSR_DEBUG_CR_ADDR, wdata);

        start = 0;
        wdata = {3'b0, start, 1'b0, size, len,
                 3'b0, start, 1'b0, size, len};
        axi.Write(DmaRegs_pkg::DMA_CSR_DEBUG_CR_ADDR, wdata);

        do begin
            axi.Read(DmaRegs_pkg::DMA_CSR_DEBUG_SR_ADDR, rdata);        
        end while (rdata != 0);

        $display("\t\tTime: %5t \t Finish!", $time);
    end

    assign s_s2mm_axis_tdata  = -m_mm2s_axis_tdata,
           s_s2mm_axis_tvalid = m_mm2s_axis_tvalid,
           s_s2mm_axis_tlast  = m_mm2s_axis_tlast,
           m_mm2s_axis_tready = s_s2mm_axis_tready;

    Dma #(
        .DMA_DATA_WIDTH_SRC(DMA_DATA_WIDTH_SRC),
        .DMA_AXI_ADDR_WIDTH(DMA_AXI_ADDR_WIDTH),
        .AXIL_ADDR_W(AXIL_ADDR_W),
        .AXIL_DATA_W(AXIL_DATA_W),
        .AXIL_STRB_W(AXIL_STRB_W)
    ) DUT (
        .axil_awaddr(axi.awaddr),
        .axil_awprot(axi.awprot),
        .axil_awvalid(axi.awvalid),
        .axil_awready(axi.awready),
        .axil_wdata(axi.wdata),
        .axil_wstrb(axi.wstrb),
        .axil_wvalid(axi.wvalid),
        .axil_wready(axi.wready),
        .axil_bresp(axi.bresp),
        .axil_bvalid(axi.bvalid),
        .axil_bready(axi.bready),
        .axil_araddr(axi.araddr),
        .axil_arprot(axi.arprot),
        .axil_arvalid(axi.arvalid),
        .axil_arready(axi.arready),
        .axil_rdata(axi.rdata),
        .axil_rresp(axi.rresp),
        .axil_rvalid(axi.rvalid),
        .axil_rready(axi.rready),
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