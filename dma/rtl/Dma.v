`timescale 1ns / 1ps

module Dma
#(
    parameter DMA_DATA_WIDTH_SRC = 64,
    parameter DMA_AXI_ADDR_WIDTH = 32
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

    input                               read_start_i,
    input   [DMA_AXI_ADDR_WIDTH-1:0]    read_addr_i,
    input   [ 7:0]                      read_len_i,
    input   [ 2:0]                      read_size_i,
    output                              read_busy_o,

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

    input                               write_start_i,
    input   [DMA_AXI_ADDR_WIDTH-1:0]    write_addr_i,
    input   [ 7:0]                      write_len_i,
    input   [ 2:0]                      write_size_i,
    output                              write_busy_o
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
