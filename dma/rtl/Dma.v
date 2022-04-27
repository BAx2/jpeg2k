`timescale 1ns / 1ps

module Dma
#(
    parameter DMA_DATA_WIDTH_SRC = 64,
    parameter DMA_AXI_ADDR_WIDTH = 32,
    parameter AXIL_ADDR_W = 8,
    parameter AXIL_DATA_W = 32,
    parameter AXIL_STRB_W = AXIL_DATA_W / 8
)(
    input                               m_axi_aclk,
    input                               m_axi_aresetn,
    output  [DMA_AXI_ADDR_WIDTH-1:0]    m_mm2s_axi_araddr, 
    output  [ 1:0]                      m_mm2s_axi_arburst,
    output  [ 3:0]                      m_mm2s_axi_arcache,
    output  [ 7:0]                      m_mm2s_axi_arlen,
    output  [ 2:0]                      m_mm2s_axi_arprot,
    input                               m_mm2s_axi_arready,
    output  [ 2:0]                      m_mm2s_axi_arsize,
    output                              m_mm2s_axi_arvalid,
    input   [DMA_DATA_WIDTH_SRC-1:0]    m_mm2s_axi_rdata,
    input                               m_mm2s_axi_rlast,
    output                              m_mm2s_axi_rready,
    input   [ 1:0]                      m_mm2s_axi_rresp,
    input                               m_mm2s_axi_rvalid,

    output  [DMA_DATA_WIDTH_SRC-1:0]    m_mm2s_axis_tdata,    
    output                              m_mm2s_axis_tvalid,    
    output                              m_mm2s_axis_tlast,    
    input                               m_mm2s_axis_tready,    

    output  [DMA_AXI_ADDR_WIDTH-1:0]    m_s2mm_axi_awaddr, 
    output  [ 1:0]                      m_s2mm_axi_awburst,
    output  [ 3:0]                      m_s2mm_axi_awcache,
    output  [ 7:0]                      m_s2mm_axi_awlen,
    output  [ 2:0]                      m_s2mm_axi_awprot,
    input                               m_s2mm_axi_awready,
    output  [ 2:0]                      m_s2mm_axi_awsize,
    output                              m_s2mm_axi_awvalid,
    output  [DMA_DATA_WIDTH_SRC-1:0]    m_s2mm_axi_wdata,
    output                              m_s2mm_axi_wlast,
    input                               m_s2mm_axi_wready,
    output  [ 3:0]                      m_s2mm_axi_wstrb,
    output                              m_s2mm_axi_wvalid,
    output                              m_s2mm_axi_bready,
    input   [ 1:0]                      m_s2mm_axi_bresp,
    input                               m_s2mm_axi_bvalid,

    input   [DMA_DATA_WIDTH_SRC-1:0]    s_s2mm_axis_tdata,
    input                               s_s2mm_axis_tvalid,
    input                               s_s2mm_axis_tlast,
    output                              s_s2mm_axis_tready,

    input   [AXIL_ADDR_W-1:0]           axil_awaddr,
    input   [2:0]                       axil_awprot,
    input                               axil_awvalid,
    output                              axil_awready,
    input   [AXIL_DATA_W-1:0]           axil_wdata,
    input   [AXIL_STRB_W-1:0]           axil_wstrb,
    input                               axil_wvalid,
    output                              axil_wready,
    output  [1:0]                       axil_bresp,
    output                              axil_bvalid,
    input                               axil_bready,
    input   [AXIL_ADDR_W-1:0]           axil_araddr,
    input   [2:0]                       axil_arprot,
    input                               axil_arvalid,
    output                              axil_arready,
    output  [AXIL_DATA_W-1:0]           axil_rdata,
    output  [1:0]                       axil_rresp,
    output                              axil_rvalid,
    input                               axil_rready
);
    wire                          read_start_i;
    wire [DMA_AXI_ADDR_WIDTH-1:0] read_addr_i;
    wire [ 7:0]                   read_len_i;
    wire [ 2:0]                   read_size_i;
    wire                          read_busy_o;
    wire                          write_start_i;
    wire [DMA_AXI_ADDR_WIDTH-1:0] write_addr_i;
    wire [ 7:0]                   write_len_i;
    wire [ 2:0]                   write_size_i;
    wire                          write_busy_o;
    
    DmaRegs #(
        .ADDR_W(AXIL_ADDR_W),
        .DATA_W(AXIL_DATA_W),
        .STRB_W(AXIL_STRB_W)
    ) DmaRegsInst (
        // System
        .clk(m_axi_aclk),
        .rst(~m_axi_aresetn),

        // read
        .csr_debug_cr_mm2s_len_out(read_len_i),
        .csr_debug_cr_mm2s_size_out(read_size_i),
        .csr_debug_cr_mm2s_start_out(read_start_i),
        .csr_debug_mm2s_addr_addr_out(read_addr_i),
        .csr_debug_sr_mm2s_busy_in(read_busy_o),

        // write
        .csr_debug_cr_s2mm_len_out(write_len_i),
        .csr_debug_cr_s2mm_size_out(write_size_i),
        .csr_debug_cr_s2mm_start_out(write_start_i),
        .csr_debug_s2mm_addr_addr_out(write_addr_i),
        .csr_debug_sr_s2mm_busy_in(write_busy_o),

        // AXIL
        .axil_awaddr(axil_awaddr),
        .axil_awprot(axil_awprot),
        .axil_awvalid(axil_awvalid),
        .axil_awready(axil_awready),
        .axil_wdata(axil_wdata),
        .axil_wstrb(axil_wstrb),
        .axil_wvalid(axil_wvalid),
        .axil_wready(axil_wready),
        .axil_bresp(axil_bresp),
        .axil_bvalid(axil_bvalid),
        .axil_bready(axil_bready),
        .axil_araddr(axil_araddr),
        .axil_arprot(axil_arprot),
        .axil_arvalid(axil_arvalid),
        .axil_arready(axil_arready),
        .axil_rdata(axil_rdata),
        .axil_rresp(axil_rresp),
        .axil_rvalid(axil_rvalid),
        .axil_rready(axil_rready)
    );

    ReadChannel #(
        .DMA_DATA_WIDTH_SRC(DMA_DATA_WIDTH_SRC),
        .DMA_AXI_ADDR_WIDTH(DMA_AXI_ADDR_WIDTH)
    ) ReadChannelInst (
        .m_axi_aclk(m_axi_aclk),
        .m_axi_aresetn(m_axi_aresetn),
        .m_mm2s_axi_araddr(m_mm2s_axi_araddr), 
        .m_mm2s_axi_arburst(m_mm2s_axi_arburst),
        .m_mm2s_axi_arcache(m_mm2s_axi_arcache),
        .m_mm2s_axi_arlen(m_mm2s_axi_arlen),
        .m_mm2s_axi_arprot(m_mm2s_axi_arprot),
        .m_mm2s_axi_arready(m_mm2s_axi_arready),
        .m_mm2s_axi_arsize(m_mm2s_axi_arsize),
        .m_mm2s_axi_arvalid(m_mm2s_axi_arvalid),
        .m_mm2s_axi_rdata(m_mm2s_axi_rdata),
        .m_mm2s_axi_rlast(m_mm2s_axi_rlast),
        .m_mm2s_axi_rready(m_mm2s_axi_rready),
        .m_mm2s_axi_rresp(m_mm2s_axi_rresp),
        .m_mm2s_axi_rvalid(m_mm2s_axi_rvalid),
        .m_mm2s_axis_tdata(m_mm2s_axis_tdata),    
        .m_mm2s_axis_tvalid(m_mm2s_axis_tvalid),    
        .m_mm2s_axis_tlast(m_mm2s_axis_tlast),    
        .m_mm2s_axis_tready(m_mm2s_axis_tready),    
        .read_start_i(read_start_i),
        .read_addr_i(read_addr_i),
        .read_len_i(read_len_i),
        .read_size_i(read_size_i),
        .read_busy_o(read_busy_o)
    );

    WriteChannel #(
        .DMA_DATA_WIDTH_SRC(DMA_DATA_WIDTH_SRC),
        .DMA_AXI_ADDR_WIDTH(DMA_AXI_ADDR_WIDTH)
    ) WriteChannelInst (
        .m_axi_aclk(m_axi_aclk),
        .m_axi_aresetn(m_axi_aresetn),
        .m_s2mm_axi_awaddr(m_s2mm_axi_awaddr), 
        .m_s2mm_axi_awburst(m_s2mm_axi_awburst),
        .m_s2mm_axi_awcache(m_s2mm_axi_awcache),
        .m_s2mm_axi_awlen(m_s2mm_axi_awlen),
        .m_s2mm_axi_awprot(m_s2mm_axi_awprot),
        .m_s2mm_axi_awready(m_s2mm_axi_awready),
        .m_s2mm_axi_awsize(m_s2mm_axi_awsize),
        .m_s2mm_axi_awvalid(m_s2mm_axi_awvalid),
        .m_s2mm_axi_wdata(m_s2mm_axi_wdata),
        .m_s2mm_axi_wlast(m_s2mm_axi_wlast),
        .m_s2mm_axi_wready(m_s2mm_axi_wready),
        .m_s2mm_axi_wstrb(m_s2mm_axi_wstrb),
        .m_s2mm_axi_wvalid(m_s2mm_axi_wvalid),
        .m_s2mm_axi_bready(m_s2mm_axi_bready),
        .m_s2mm_axi_bresp(m_s2mm_axi_bresp),
        .m_s2mm_axi_bvalid(m_s2mm_axi_bvalid),
        .s_s2mm_axis_tdata(s_s2mm_axis_tdata),
        .s_s2mm_axis_tvalid(s_s2mm_axis_tvalid),
        .s_s2mm_axis_tlast(s_s2mm_axis_tlast),
        .s_s2mm_axis_tready(s_s2mm_axis_tready),
        .write_start_i(write_start_i),
        .write_addr_i(write_addr_i),
        .write_len_i(write_len_i),
        .write_size_i(write_size_i),
        .write_busy_o(write_busy_o)
    );

endmodule
