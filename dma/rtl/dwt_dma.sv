`include "axi4.svh"

module dwt_dma #(
    parameter DMA_DATA_WIDTH_SRC = 64,
    parameter DMA_AXI_PROTOCOL_SRC = 0,
    parameter DMA_AXI_ADDR_WIDTH = 32,
    parameter C_M_AXI_ID_WIDTH = 1,
    parameter C_M_AXI_ARUSER_WIDTH = 0
)(
    // master AXI interface
    input   logic                                   m_axi_aclk,
    input   logic                                   m_axi_aresetn,

    output  logic   [C_M_AXI_ID_WIDTH-1 : 0]        m_src_axi_arid,
    output  logic   [DMA_AXI_ADDR_WIDTH-1:0]        m_src_axi_araddr,   // 
    output  logic   [7-(4*DMA_AXI_PROTOCOL_SRC):0]  m_src_axi_arlen,    //
    output  logic   [ 2:0]                          m_src_axi_arsize,   //
    output  logic   [ 1:0]                          m_src_axi_arburst,  //
    output  logic                                   m_src_axi_arlock,   // 
    output  logic   [ 3:0]                          m_src_axi_arcache,  //
    output  logic   [ 2:0]                          m_src_axi_arprot,   //
    output  logic   [ 3:0]                          m_src_axi_arqos,
    output  logic   [C_M_AXI_ARUSER_WIDTH-1:0]      m_src_axi_aruser,
    output  logic                                   m_src_axi_arvalid,  //
    input   logic                                   m_src_axi_arready,  //


    input   logic   [C_M_AXI_ID_WIDTH-1 : 0]        m_src_axi_rid,      //
    input   logic   [DMA_DATA_WIDTH_SRC-1:0]        m_src_axi_rdata,    //
    input   logic   [ 1:0]                          m_src_axi_rresp,    //
    input   logic                                   m_src_axi_rlast,    //
    input   logic   [C_M_AXI_ARUSER_WIDTH-1:0]      m_src_axi_ruser,    //
    input   logic                                   m_src_axi_rvalid,   //
    output  logic                                   m_src_axi_rready,   //

    // dbg
    input   logic          dbg_sot,
    input   logic   [31:0] dbg_addr,
    input   logic   [31:0] dbg_len,
    input   logic   [31:0] dbg_size
);

    assign m_src_axi_arid = 0;
    assign m_src_axi_araddr = dbg_addr;
    assign m_src_axi_arlen = dbg_len;
    assign m_src_axi_arsize = dbg_size;
    assign m_src_axi_arburst = Incr;
    assign m_src_axi_arlock = 0;
    assign m_src_axi_arcache = NormalNonCachBuff;
    assign m_src_axi_arprot = 0;
    assign m_src_axi_arqos = 0;
    assign m_src_axi_aruser = 1;

    logic sot_reg;
    logic sot;
    always_ff @(posedge m_axi_aclk) sot_reg <= dbg_sot;
    assign sot = dbg_sot & !sot_reg;

    always_ff @(posedge m_axi_aclk) begin
        if (!m_axi_aresetn) begin
            m_src_axi_arvalid <= 0;
        end else if (sot) begin
            m_src_axi_arvalid <= 1;
        end else if (m_src_axi_arvalid & m_src_axi_arready) begin
            m_src_axi_arvalid <= 0;            
        end
    end 
    
    assign m_src_axi_rready = 1;

    // // Read Address (AR) channel
    // assign m_src_axi_arprot  = 'h0;
    // // assign m_src_axi_arprot  = Unprivileged
    // //                         | Secure
    // //                         | Data;
    // assign m_src_axi_arburst = Incr;                // Burst type
    // assign m_src_axi_arcache = NormalNonCachBuff;   // Normal Non-cacheable Bufferable
    // assign m_src_axi_arlen   = 'b0;                 // The burst length
    // assign m_src_axi_arsize  = Byte1;               // The maximum number of bytes to transfer in each data transfer

    // always_ff @(posedge m_axi_aclk)
    // begin
    //     if (m_axi_aresetn) begin
    //         m_src_axi_araddr <= 0;
    //         m_src_axi_arvalid <= 0;
    //     end else begin
    //         if (sot) begin
    //             m_src_axi_araddr <= dbg_addr;
    //             m_src_axi_arvalid <= 1;
    //         end else if (m_src_axi_arready) begin
    //             m_src_axi_araddr <= 0;
    //             m_src_axi_arvalid <= 0;
    //         end
    //     end
    // end

    // // Read (R) channel
    // assign m_src_axi_rready = 1;

    // always_ff @(posedge m_axi_aclk) 
    // begin
    //     if (m_axi_aresetn) begin
    //         dbg_data <= 0;
    //     end else begin
    //         if (m_src_axi_rvalid) begin
    //             dbg_data <= m_src_axi_rdata;
    //             dbg_last <= m_src_axi_rlast;
    //             dbg_resp <= m_src_axi_rresp;
    //         end
    //     end
    // end

endmodule