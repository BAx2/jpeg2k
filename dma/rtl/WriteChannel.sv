`include "../rtl/axi4.svh"

module WriteChannel #(
    parameter DMA_DATA_WIDTH_SRC = 64,
    parameter DMA_AXI_ADDR_WIDTH = 32
)(
    // master AXI interface
    input   logic                               m_axi_aclk,
    input   logic                               m_axi_aresetn,

    // Write address
    output  logic   [DMA_AXI_ADDR_WIDTH-1:0]    m_s2mm_axi_awaddr, 
    output  logic   [ 1:0]                      m_s2mm_axi_awburst,
    output  logic   [ 3:0]                      m_s2mm_axi_awcache,
    output  logic   [ 7:0]                      m_s2mm_axi_awlen,
    output  logic   [ 2:0]                      m_s2mm_axi_awprot,
    input   logic                               m_s2mm_axi_awready,
    output  logic   [ 2:0]                      m_s2mm_axi_awsize,
    output  logic                               m_s2mm_axi_awvalid,

    // Write
    output  logic   [DMA_DATA_WIDTH_SRC-1:0]    m_s2mm_axi_wdata,
    output  logic                               m_s2mm_axi_wlast,
    input   logic                               m_s2mm_axi_wready,
    output  logic   [ 3:0]                      m_s2mm_axi_wstrb,
    output  logic                               m_s2mm_axi_wvalid,

    // Write response
    output  logic                               m_s2mm_axi_bready,
    input   logic   [ 1:0]                      m_s2mm_axi_bresp,
    input   logic                               m_s2mm_axi_bvalid,

    // Stream data
    input   logic   [DMA_DATA_WIDTH_SRC-1:0]    s_s2mm_axis_tdata,
    input   logic                               s_s2mm_axis_tvalid,
    input   logic                               s_s2mm_axis_tlast,
    output  logic                               s_s2mm_axis_tready,

    // 
    input   logic                               write_start_i,
    input   logic   [DMA_AXI_ADDR_WIDTH-1:0]    write_addr_i,
    input   logic   [ 7:0]                      write_len_i,
    input   logic   [ 2:0]                      write_size_i,
    output  logic                               write_busy_o
);
    // start transaction
    logic start_reg, start;
    always_ff @(posedge m_axi_aclk) start_reg <= write_start_i;
    assign start = !start_reg & write_start_i;

    // Write address
    assign m_s2mm_axi_awburst = Incr,
           m_s2mm_axi_awcache = NormalNonCachBuff,
           m_s2mm_axi_awprot  = 0;  // Unprivileged access, Secure access, Data access

    always_ff @(posedge m_axi_aclk) begin
        if (start & !write_busy_o) begin
            m_s2mm_axi_awaddr  <= write_addr_i;
            m_s2mm_axi_awlen   <= write_len_i;
            m_s2mm_axi_awsize  <= write_size_i;
        end
    end

    always_ff @(posedge m_axi_aclk) begin
        if (!m_axi_aresetn) begin
            m_s2mm_axi_awvalid <= 0;
        end else begin
            if (start & !write_busy_o) begin
                m_s2mm_axi_awvalid <= 1;
            end else if (m_s2mm_axi_awvalid & m_s2mm_axi_awready) begin
                m_s2mm_axi_awvalid <= 0;
            end
        end
    end

    // Write
    assign m_s2mm_axi_wdata   = s_s2mm_axis_tdata,
           m_s2mm_axi_wlast   = s_s2mm_axis_tlast,
           s_s2mm_axis_tready = m_s2mm_axi_wready,
           m_s2mm_axi_wstrb   = 4'hF,
           m_s2mm_axi_wvalid  = s_s2mm_axis_tvalid;

    // Write response
    logic response_ok;
    logic has_response;

    assign m_s2mm_axi_bready = 1;
    always_ff @(posedge m_axi_aclk) begin
        if (!m_axi_aresetn) begin
            response_ok <= 0;
            has_response <= 0;
        end else begin
            if (start || !write_busy_o) begin
                response_ok <= 0;
                has_response <= 0;                
            end else if (m_s2mm_axi_bready && m_s2mm_axi_bvalid) begin
                has_response <= 1;
                response_ok <= (m_s2mm_axi_bresp == 0);
            end
        end
    end

    // Busy
    logic no_more_data;
    always_ff @(posedge m_axi_aclk) begin
        if (!m_axi_aresetn) begin
            no_more_data <= 1;
        end else begin
            if (!write_busy_o) begin
                no_more_data <= 1;
            end else if (start & !write_busy_o) begin
                no_more_data <= 0;
            end else if (m_s2mm_axi_wready & m_s2mm_axi_wvalid & m_s2mm_axi_wlast) begin
                no_more_data <= 1;
            end
        end
    end

    always_ff @(posedge m_axi_aclk) begin
        if (!m_axi_aresetn) begin
            write_busy_o <= 0;
        end else begin
            if (start & !write_busy_o) begin
                write_busy_o <= 1;
            end else if (no_more_data & has_response) begin
                write_busy_o <= 0;
            end
        end
    end

endmodule
