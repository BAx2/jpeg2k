module AxiMemory #(
    parameter DMA_DATA_WIDTH_SRC = 64,
    parameter DMA_AXI_ADDR_WIDTH = 32,
    parameter MEM_DEPTH = 64
) (
    input   logic                               m_axi_aclk,
    input   logic                               m_axi_aresetn,

    input   logic   [DMA_AXI_ADDR_WIDTH-1:0]    m_mm2s_axi_araddr, 
    input   logic   [ 1:0]                      m_mm2s_axi_arburst,
    input   logic   [ 3:0]                      m_mm2s_axi_arcache,
    input   logic   [ 7:0]                      m_mm2s_axi_arlen,
    input   logic   [ 2:0]                      m_mm2s_axi_arprot,
    output  logic                               m_mm2s_axi_arready,
    input   logic   [ 2:0]                      m_mm2s_axi_arsize,
    input   logic                               m_mm2s_axi_arvalid,
    
    output  logic   [DMA_DATA_WIDTH_SRC-1:0]    m_mm2s_axi_rdata,
    output  logic                               m_mm2s_axi_rlast,
    input   logic                               m_mm2s_axi_rready,
    output  logic   [ 1:0]                      m_mm2s_axi_rresp,
    output  logic                               m_mm2s_axi_rvalid,

    input   logic   [DMA_AXI_ADDR_WIDTH-1:0]    m_s2mm_axi_awaddr, 
    input   logic   [ 1:0]                      m_s2mm_axi_awburst,
    input   logic   [ 3:0]                      m_s2mm_axi_awcache,
    input   logic   [ 7:0]                      m_s2mm_axi_awlen,
    input   logic   [ 2:0]                      m_s2mm_axi_awprot,
    output  logic                               m_s2mm_axi_awready,
    input   logic   [ 2:0]                      m_s2mm_axi_awsize,
    input   logic                               m_s2mm_axi_awvalid,

    input   logic   [DMA_DATA_WIDTH_SRC-1:0]    m_s2mm_axi_wdata,
    input   logic                               m_s2mm_axi_wlast,
    output  logic                               m_s2mm_axi_wready,
    input   logic   [ 3:0]                      m_s2mm_axi_wstrb,
    input   logic                               m_s2mm_axi_wvalid,

    input   logic                               m_s2mm_axi_bready,
    output  logic   [ 1:0]                      m_s2mm_axi_bresp,
    output  logic                               m_s2mm_axi_bvalid, 

    output  logic   [DMA_DATA_WIDTH_SRC-1:0]    mem_o [0:MEM_DEPTH-1]
);
    localparam READ_DELAY = 10;
    localparam RESP_DELAY = 10;

    `define WAIT_CLOCKS(N) for (int i = 0; i < (N); i++) @(posedge m_axi_aclk);
    `define WAIT_HIGH(signal) while (!(signal)) @(posedge m_axi_aclk);

    typedef logic [DMA_DATA_WIDTH_SRC-1:0] data_t;
    data_t mem[0:MEM_DEPTH-1];

    initial begin
        // m_mm2s_axi_arready  = 1;
        m_mm2s_axi_rdata    = 0;
        m_mm2s_axi_rlast    = 0;
        m_mm2s_axi_rresp    = 0;
        m_mm2s_axi_rvalid   = 0;
        // m_s2mm_axi_awready  = 1;
        m_s2mm_axi_wready   = 1;
        m_s2mm_axi_bresp    = 0;
        m_s2mm_axi_bvalid   = 0;

        for (int i = 0; i < MEM_DEPTH; i++)
            mem[i] = i;
    end

    typedef logic [DMA_AXI_ADDR_WIDTH-1:0] addr_t;

    // read 
    addr_t read_addr;
    logic [7:0] read_len;
    logic start_read;
    assign m_mm2s_axi_arready = 1'b1;
    always @(posedge m_axi_aclk) begin
        if (m_mm2s_axi_arready & m_mm2s_axi_arvalid) begin
            read_addr = m_mm2s_axi_araddr;
            read_len = m_mm2s_axi_arlen;

            `WAIT_CLOCKS(READ_DELAY);

            for (int i = 0; i <= read_len; i++) begin
                `WAIT_HIGH(m_mm2s_axi_rready);
                m_mm2s_axi_rdata = mem[read_addr + i];
                m_mm2s_axi_rlast = (i == read_len);
                m_mm2s_axi_rresp = 0;
                m_mm2s_axi_rvalid = 1;
                @(posedge m_axi_aclk);
            end
            m_mm2s_axi_rvalid = 0;
            m_mm2s_axi_rlast = 0;
            start_read = 0;
        end
    end

    // write
    addr_t write_addr;
    logic [7:0] write_len;
    assign m_s2mm_axi_awready = 1'b1;
    always @(posedge m_axi_aclk) begin
        if (m_s2mm_axi_awready & m_s2mm_axi_awvalid) begin
            write_addr = m_s2mm_axi_awaddr;
            write_len = m_s2mm_axi_awlen;

            for (int i = 0; i <= read_len; i++) begin
                `WAIT_HIGH(m_s2mm_axi_wvalid);
                mem[write_addr + i] = m_s2mm_axi_wdata;
                @(posedge m_axi_aclk);
            end

            `WAIT_CLOCKS(RESP_DELAY);

            `WAIT_HIGH(m_s2mm_axi_bready);
            m_s2mm_axi_bvalid = 1;
            @(posedge m_axi_aclk);
            m_s2mm_axi_bvalid = 0;
        end
    end

    assign mem_o = mem;

endmodule
