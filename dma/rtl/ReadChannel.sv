`include "../rtl/axi4.svh"

module ReadChannel #(
    parameter DMA_DATA_WIDTH_SRC = 64,
    parameter DMA_AXI_ADDR_WIDTH = 32
)(
    // master AXI interface
    input   logic                               m_axi_aclk,
    input   logic                               m_axi_aresetn,

    // Read address
    output  logic   [DMA_AXI_ADDR_WIDTH-1:0]    m_mm2s_axi_araddr, 
    output  logic   [ 1:0]                      m_mm2s_axi_arburst,
    output  logic   [ 3:0]                      m_mm2s_axi_arcache,
    output  logic   [ 7:0]                      m_mm2s_axi_arlen,
    output  logic   [ 2:0]                      m_mm2s_axi_arprot,
    input   logic                               m_mm2s_axi_arready,
    output  logic   [ 2:0]                      m_mm2s_axi_arsize,
    output  logic                               m_mm2s_axi_arvalid,

    // Read
    input   logic   [DMA_DATA_WIDTH_SRC-1:0]    m_mm2s_axi_rdata,
    input   logic                               m_mm2s_axi_rlast,
    output  logic                               m_mm2s_axi_rready,
    input   logic   [ 1:0]                      m_mm2s_axi_rresp,
    input   logic                               m_mm2s_axi_rvalid,

    // Stream data
    output  logic   [DMA_DATA_WIDTH_SRC-1:0]    m_mm2s_axis_tdata,    
    output  logic                               m_mm2s_axis_tvalid,    
    output  logic                               m_mm2s_axis_tlast,    
    input   logic                               m_mm2s_axis_tready,    

    // dbg
    input   logic                               read_start_i,
    input   logic   [DMA_AXI_ADDR_WIDTH-1:0]    read_addr_i,
    input   logic   [ 7:0]                      read_len_i,
    input   logic   [ 2:0]                      read_size_i,
    output  logic                               read_busy_o
);
    // start transaction
    logic start_reg, start;
    always_ff @(posedge m_axi_aclk) start_reg <= read_start_i;
    assign start = !start_reg & read_start_i;

    // Read address
    assign m_mm2s_axi_arburst = Incr,
           m_mm2s_axi_arcache = NormalNonCachBuff,
           m_mm2s_axi_arprot  = 0;  // Unprivileged access, Secure access, Data access

    always_ff @(posedge m_axi_aclk) begin
        if (start & !read_busy_o) begin
            m_mm2s_axi_araddr  <= read_addr_i;
            m_mm2s_axi_arlen   <= read_len_i;
            m_mm2s_axi_arsize  <= read_size_i;
        end
    end

    always_ff @(posedge m_axi_aclk) begin
        if (!m_axi_aresetn) begin
            m_mm2s_axi_arvalid <= 0;
        end else if (start) begin
            m_mm2s_axi_arvalid <= 1;
        end else if (m_mm2s_axi_arvalid & m_mm2s_axi_arready) begin
            m_mm2s_axi_arvalid <= 0;            
        end
    end 
    
    // Read
    assign m_mm2s_axis_tdata  = m_mm2s_axi_rdata,
           m_mm2s_axis_tvalid = m_mm2s_axi_rvalid,
           m_mm2s_axis_tlast  = m_mm2s_axi_rlast,
           m_mm2s_axi_rready  = m_mm2s_axis_tready;

    // Busy
    logic no_more_data;
    always_ff @(posedge m_axi_aclk) begin
        if (!m_axi_aresetn) begin
            no_more_data <= 1;
        end else begin
            if (start & !read_busy_o) begin
                no_more_data <= 0;
            end else if (!read_busy_o) begin
                no_more_data <= 1;
            end else if (m_mm2s_axi_rready & m_mm2s_axi_rvalid & m_mm2s_axi_rlast) begin
                no_more_data <= 1;
            end
        end
    end

    always_ff @(posedge m_axi_aclk) begin
        if (!m_axi_aresetn) begin
            read_busy_o <= 0;
        end else begin
            if (start & !read_busy_o) begin
                read_busy_o <= 1;
            end else if (no_more_data) begin
                read_busy_o <= 0;
            end
        end
    end

endmodule
