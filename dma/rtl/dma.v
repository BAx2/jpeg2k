`timescale 1ns / 1ps

module dma
#(
    parameter DMA_DATA_WIDTH_SRC = 64,
    parameter DMA_AXI_PROTOCOL_SRC = 0,
    parameter DMA_AXI_ADDR_WIDTH = 32,
    parameter C_M_AXI_ID_WIDTH	= 1,
    parameter C_M_AXI_ARUSER_WIDTH	= 0
)(
    // master AXI interface
    input                                    m_axi_aclk,
    input                                    m_axi_aresetn,

    output   [C_M_AXI_ID_WIDTH-1 : 0]        m_src_axi_arid,
    output   [DMA_AXI_ADDR_WIDTH-1:0]        m_src_axi_araddr,   // 
    output   [7-(4*DMA_AXI_PROTOCOL_SRC):0]  m_src_axi_arlen,    //
    output   [ 2:0]                          m_src_axi_arsize,   //
    output   [ 1:0]                          m_src_axi_arburst,  //
    output                                   m_src_axi_arlock,   // 
    output   [ 3:0]                          m_src_axi_arcache,  //
    output   [ 2:0]                          m_src_axi_arprot,   //
    output   [ 3:0]                          m_src_axi_arqos,
    output   [C_M_AXI_ARUSER_WIDTH-1:0]      m_src_axi_aruser,
    output                                   m_src_axi_arvalid,  //
    input                                    m_src_axi_arready,  //


    input    [C_M_AXI_ID_WIDTH-1 : 0]        m_src_axi_rid,      //
    input    [DMA_DATA_WIDTH_SRC-1:0]        m_src_axi_rdata,    //
    input    [ 1:0]                          m_src_axi_rresp,    //
    input                                    m_src_axi_rlast,    //
    input    [C_M_AXI_ARUSER_WIDTH-1:0]      m_src_axi_ruser,    //
    input                                    m_src_axi_rvalid,   //
    output                                   m_src_axi_rready,   //

    // dbg
    input           dbg_sot,
    input    [31:0] dbg_addr,
    input    [31:0] dbg_len,    // 255
    input    [31:0] dbg_size    // 3
);

    dwt_dma #(
        .DMA_DATA_WIDTH_SRC(DMA_DATA_WIDTH_SRC),
        .DMA_AXI_PROTOCOL_SRC(DMA_AXI_PROTOCOL_SRC),
        .DMA_AXI_ADDR_WIDTH(DMA_AXI_ADDR_WIDTH),
        .C_M_AXI_ID_WIDTH(C_M_AXI_ID_WIDTH),
        .C_M_AXI_ARUSER_WIDTH(C_M_AXI_ARUSER_WIDTH)
    ) DMA_INST (
        .m_axi_aclk(m_axi_aclk),
        .m_axi_aresetn(m_axi_aresetn),

        .m_src_axi_arid(m_src_axi_arid),
        .m_src_axi_araddr(m_src_axi_araddr),   // 
        .m_src_axi_arlen(m_src_axi_arlen),    //
        .m_src_axi_arsize(m_src_axi_arsize),   //
        .m_src_axi_arburst(m_src_axi_arburst),  //
        .m_src_axi_arlock(m_src_axi_arlock),   // 
        .m_src_axi_arcache(m_src_axi_arcache),  //
        .m_src_axi_arprot(m_src_axi_arprot),   //
        .m_src_axi_arqos(m_src_axi_arqos),
        .m_src_axi_aruser(m_src_axi_aruser),
        .m_src_axi_arvalid(m_src_axi_arvalid),  //
        .m_src_axi_arready(m_src_axi_arready),  //

        .m_src_axi_rid(m_src_axi_rid),      //
        .m_src_axi_rdata(m_src_axi_rdata),    //
        .m_src_axi_rresp(m_src_axi_rresp),    //
        .m_src_axi_rlast(m_src_axi_rlast),    //
        .m_src_axi_ruser(m_src_axi_ruser),    //
        .m_src_axi_rvalid(m_src_axi_rvalid),   //
        .m_src_axi_rready(m_src_axi_rready),   //

        .dbg_sot(dbg_sot),
        .dbg_addr(dbg_addr),
        .dbg_len(dbg_len),
        .dbg_size(dbg_size)
    );

endmodule
