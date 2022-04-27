// Created with Corsair v1.0.2.dev0+894dec23

module DmaRegs #(
    parameter ADDR_W = 8,
    parameter DATA_W = 32,
    parameter STRB_W = DATA_W / 8
)(
    // System
    input clk,
    input rst,
    // DEBUG_CR.MM2S_LEN
    output [7:0] csr_debug_cr_mm2s_len_out,
    // DEBUG_CR.MM2S_SIZE
    output [2:0] csr_debug_cr_mm2s_size_out,
    // DEBUG_CR.MM2S_START
    output  csr_debug_cr_mm2s_start_out,
    // DEBUG_CR.S2MM_LEN
    output [7:0] csr_debug_cr_s2mm_len_out,
    // DEBUG_CR.S2MM_SIZE
    output [2:0] csr_debug_cr_s2mm_size_out,
    // DEBUG_CR.S2MM_START
    output  csr_debug_cr_s2mm_start_out,

    // DEBUG_SR.MM2S_BUSY
    input  csr_debug_sr_mm2s_busy_in,
    // DEBUG_SR.S2MM_BUSY
    input  csr_debug_sr_s2mm_busy_in,

    // DEBUG_MM2S_ADDR.ADDR
    output [31:0] csr_debug_mm2s_addr_addr_out,

    // DEBUG_S2MM_ADDR.ADDR
    output [31:0] csr_debug_s2mm_addr_addr_out,

    // AXI
    input  [ADDR_W-1:0] axil_awaddr,
    input  [2:0]        axil_awprot,
    input               axil_awvalid,
    output              axil_awready,
    input  [DATA_W-1:0] axil_wdata,
    input  [STRB_W-1:0] axil_wstrb,
    input               axil_wvalid,
    output              axil_wready,
    output [1:0]        axil_bresp,
    output              axil_bvalid,
    input               axil_bready,

    input  [ADDR_W-1:0] axil_araddr,
    input  [2:0]        axil_arprot,
    input               axil_arvalid,
    output              axil_arready,
    output [DATA_W-1:0] axil_rdata,
    output [1:0]        axil_rresp,
    output              axil_rvalid,
    input               axil_rready
);
wire              wready;
wire [ADDR_W-1:0] waddr;
wire [DATA_W-1:0] wdata;
wire              wen;
wire [STRB_W-1:0] wstrb;
wire [DATA_W-1:0] rdata;
wire              rvalid;
wire [ADDR_W-1:0] raddr;
wire              ren;
    reg [ADDR_W-1:0] waddr_int;
    reg [ADDR_W-1:0] raddr_int;
    reg [DATA_W-1:0] wdata_int;
    reg [STRB_W-1:0] strb_int;
    reg              awflag;
    reg              wflag;
    reg              arflag;
    reg              rflag;

    reg              axil_bvalid_int;
    reg [DATA_W-1:0] axil_rdata_int;
    reg              axil_rvalid_int;

    assign axil_awready = ~awflag;
    assign axil_wready  = ~wflag;
    assign axil_bvalid  = axil_bvalid_int;
    assign waddr        = waddr_int;
    assign wdata        = wdata_int;
    assign wstrb        = strb_int;
    assign wen          = awflag && wflag;
    assign axil_bresp   = 'd0; // always okay

    always @(posedge clk) begin
        if (rst == 1'b1) begin
            waddr_int       <= 'd0;
            wdata_int       <= 'd0;
            strb_int        <= 'd0;
            awflag          <= 1'b0;
            wflag           <= 1'b0;
            axil_bvalid_int <= 1'b0;
        end else begin
            if (axil_awvalid == 1'b1 && awflag == 1'b0) begin
                awflag    <= 1'b1;
                waddr_int <= axil_awaddr;
            end else if (wen == 1'b1 && wready == 1'b1) begin
                awflag    <= 1'b0;
            end

            if (axil_wvalid == 1'b1 && wflag == 1'b0) begin
                wflag     <= 1'b1;
                wdata_int <= axil_wdata;
                strb_int  <= axil_wstrb;
            end else if (wen == 1'b1 && wready == 1'b1) begin
                wflag     <= 1'b0;
            end

            if (axil_bvalid_int == 1'b1 && axil_bready == 1'b1) begin
                axil_bvalid_int <= 1'b0;
            end else if ((axil_wvalid == 1'b1 && awflag == 1'b1) || (axil_awvalid == 1'b1 && wflag == 1'b1) || (wflag == 1'b1 && awflag == 1'b1)) begin
                axil_bvalid_int <= wready;
            end
        end
    end

    assign axil_arready = ~arflag;
    assign axil_rdata   = axil_rdata_int;
    assign axil_rvalid  = axil_rvalid_int;
    assign raddr        = raddr_int;
    assign ren          = arflag && ~rflag;
    assign axil_rresp   = 'd0; // always okay

    always @(posedge clk) begin
        if (rst == 1'b1) begin
            raddr_int       <= 'd0;
            arflag          <= 1'b0;
            rflag           <= 1'b0;
            axil_rdata_int  <= 'd0;
            axil_rvalid_int <= 1'b0;
        end else begin
            if (axil_arvalid == 1'b1 && arflag == 1'b0) begin
                arflag    <= 1'b1;
                raddr_int <= axil_araddr;
            end else if (axil_rvalid_int == 1'b1 && axil_rready == 1'b1) begin
                arflag    <= 1'b0;
            end

            if (rvalid == 1'b1 && ren == 1'b1 && rflag == 1'b0) begin
                rflag <= 1'b1;
            end else if (axil_rvalid_int == 1'b1 && axil_rready == 1'b1) begin
                rflag <= 1'b0;
            end

            if (rvalid == 1'b1 && axil_rvalid_int == 1'b0) begin
                axil_rdata_int  <= rdata;
                axil_rvalid_int <= 1'b1;
            end else if (axil_rvalid_int == 1'b1 && axil_rready == 1'b1) begin
                axil_rvalid_int <= 1'b0;
            end
        end
    end

//------------------------------------------------------------------------------
// CSR:
// [0xf0] - DEBUG_CR - DMA Control
//------------------------------------------------------------------------------
wire [31:0] csr_debug_cr_rdata;
assign csr_debug_cr_rdata[11] = 1'b0;
assign csr_debug_cr_rdata[15:13] = 3'h0;
assign csr_debug_cr_rdata[27] = 1'b0;
assign csr_debug_cr_rdata[31:29] = 3'h0;

wire csr_debug_cr_wen;
assign csr_debug_cr_wen = wen && (waddr == 8'hf0);

wire csr_debug_cr_ren;
assign csr_debug_cr_ren = ren && (raddr == 8'hf0);
reg csr_debug_cr_ren_ff;
always @(posedge clk) begin
    if (rst) begin
        csr_debug_cr_ren_ff <= 1'b0;
    end else begin
        csr_debug_cr_ren_ff <= csr_debug_cr_ren;
    end
end
//---------------------
// Bit field:
// DEBUG_CR[7:0] - MM2S_LEN - The burst length
// access: rw, hardware: o
//---------------------
reg [7:0] csr_debug_cr_mm2s_len_ff;

assign csr_debug_cr_rdata[7:0] = csr_debug_cr_mm2s_len_ff;

assign csr_debug_cr_mm2s_len_out = csr_debug_cr_mm2s_len_ff;

always @(posedge clk) begin
    if (rst) begin
        csr_debug_cr_mm2s_len_ff <= 8'h0;
    end else  begin
    if (csr_debug_cr_wen) begin
            if (wstrb[0]) begin
                csr_debug_cr_mm2s_len_ff[7:0] <= wdata[7:0];
            end
        end else begin
            csr_debug_cr_mm2s_len_ff <= csr_debug_cr_mm2s_len_ff;
        end
    end
end


//---------------------
// Bit field:
// DEBUG_CR[10:8] - MM2S_SIZE - The number of bytes in a transfer must be equal to the data bus width
// access: rw, hardware: o
//---------------------
reg [2:0] csr_debug_cr_mm2s_size_ff;

assign csr_debug_cr_rdata[10:8] = csr_debug_cr_mm2s_size_ff;

assign csr_debug_cr_mm2s_size_out = csr_debug_cr_mm2s_size_ff;

always @(posedge clk) begin
    if (rst) begin
        csr_debug_cr_mm2s_size_ff <= 3'h0;
    end else  begin
    if (csr_debug_cr_wen) begin
            if (wstrb[1]) begin
                csr_debug_cr_mm2s_size_ff[2:0] <= wdata[10:8];
            end
        end else begin
            csr_debug_cr_mm2s_size_ff <= csr_debug_cr_mm2s_size_ff;
        end
    end
end


//---------------------
// Bit field:
// DEBUG_CR[12] - MM2S_START - Start read transaction
// access: rw, hardware: o
//---------------------
reg  csr_debug_cr_mm2s_start_ff;

assign csr_debug_cr_rdata[12] = csr_debug_cr_mm2s_start_ff;

assign csr_debug_cr_mm2s_start_out = csr_debug_cr_mm2s_start_ff;

always @(posedge clk) begin
    if (rst) begin
        csr_debug_cr_mm2s_start_ff <= 1'b0;
    end else  begin
    if (csr_debug_cr_wen) begin
            if (wstrb[1]) begin
                csr_debug_cr_mm2s_start_ff <= wdata[12];
            end
        end else begin
            csr_debug_cr_mm2s_start_ff <= csr_debug_cr_mm2s_start_ff;
        end
    end
end


//---------------------
// Bit field:
// DEBUG_CR[23:16] - S2MM_LEN - The burst length
// access: rw, hardware: o
//---------------------
reg [7:0] csr_debug_cr_s2mm_len_ff;

assign csr_debug_cr_rdata[23:16] = csr_debug_cr_s2mm_len_ff;

assign csr_debug_cr_s2mm_len_out = csr_debug_cr_s2mm_len_ff;

always @(posedge clk) begin
    if (rst) begin
        csr_debug_cr_s2mm_len_ff <= 8'h0;
    end else  begin
    if (csr_debug_cr_wen) begin
            if (wstrb[2]) begin
                csr_debug_cr_s2mm_len_ff[7:0] <= wdata[23:16];
            end
        end else begin
            csr_debug_cr_s2mm_len_ff <= csr_debug_cr_s2mm_len_ff;
        end
    end
end


//---------------------
// Bit field:
// DEBUG_CR[26:24] - S2MM_SIZE - The number of bytes in a transfer must be equal to the data bus width
// access: rw, hardware: o
//---------------------
reg [2:0] csr_debug_cr_s2mm_size_ff;

assign csr_debug_cr_rdata[26:24] = csr_debug_cr_s2mm_size_ff;

assign csr_debug_cr_s2mm_size_out = csr_debug_cr_s2mm_size_ff;

always @(posedge clk) begin
    if (rst) begin
        csr_debug_cr_s2mm_size_ff <= 3'h0;
    end else  begin
    if (csr_debug_cr_wen) begin
            if (wstrb[3]) begin
                csr_debug_cr_s2mm_size_ff[2:0] <= wdata[26:24];
            end
        end else begin
            csr_debug_cr_s2mm_size_ff <= csr_debug_cr_s2mm_size_ff;
        end
    end
end


//---------------------
// Bit field:
// DEBUG_CR[28] - S2MM_START - Start read transaction
// access: rw, hardware: o
//---------------------
reg  csr_debug_cr_s2mm_start_ff;

assign csr_debug_cr_rdata[28] = csr_debug_cr_s2mm_start_ff;

assign csr_debug_cr_s2mm_start_out = csr_debug_cr_s2mm_start_ff;

always @(posedge clk) begin
    if (rst) begin
        csr_debug_cr_s2mm_start_ff <= 1'b0;
    end else  begin
    if (csr_debug_cr_wen) begin
            if (wstrb[3]) begin
                csr_debug_cr_s2mm_start_ff <= wdata[28];
            end
        end else begin
            csr_debug_cr_s2mm_start_ff <= csr_debug_cr_s2mm_start_ff;
        end
    end
end


//------------------------------------------------------------------------------
// CSR:
// [0xf4] - DEBUG_SR - DMA Status
//------------------------------------------------------------------------------
wire [31:0] csr_debug_sr_rdata;
assign csr_debug_sr_rdata[31:2] = 30'h0;


wire csr_debug_sr_ren;
assign csr_debug_sr_ren = ren && (raddr == 8'hf4);
reg csr_debug_sr_ren_ff;
always @(posedge clk) begin
    if (rst) begin
        csr_debug_sr_ren_ff <= 1'b0;
    end else begin
        csr_debug_sr_ren_ff <= csr_debug_sr_ren;
    end
end
//---------------------
// Bit field:
// DEBUG_SR[0] - MM2S_BUSY - Read transaction in process
// access: ro, hardware: i
//---------------------
reg  csr_debug_sr_mm2s_busy_ff;

assign csr_debug_sr_rdata[0] = csr_debug_sr_mm2s_busy_ff;


always @(posedge clk) begin
    if (rst) begin
        csr_debug_sr_mm2s_busy_ff <= 1'b0;
    end else  begin
     begin            csr_debug_sr_mm2s_busy_ff <= csr_debug_sr_mm2s_busy_in;
        end
    end
end


//---------------------
// Bit field:
// DEBUG_SR[1] - S2MM_BUSY - Write transaction in process
// access: ro, hardware: i
//---------------------
reg  csr_debug_sr_s2mm_busy_ff;

assign csr_debug_sr_rdata[1] = csr_debug_sr_s2mm_busy_ff;


always @(posedge clk) begin
    if (rst) begin
        csr_debug_sr_s2mm_busy_ff <= 1'b0;
    end else  begin
     begin            csr_debug_sr_s2mm_busy_ff <= csr_debug_sr_s2mm_busy_in;
        end
    end
end


//------------------------------------------------------------------------------
// CSR:
// [0xf8] - DEBUG_MM2S_ADDR - MM2S Start address
//------------------------------------------------------------------------------
wire [31:0] csr_debug_mm2s_addr_rdata;

wire csr_debug_mm2s_addr_wen;
assign csr_debug_mm2s_addr_wen = wen && (waddr == 8'hf8);

wire csr_debug_mm2s_addr_ren;
assign csr_debug_mm2s_addr_ren = ren && (raddr == 8'hf8);
reg csr_debug_mm2s_addr_ren_ff;
always @(posedge clk) begin
    if (rst) begin
        csr_debug_mm2s_addr_ren_ff <= 1'b0;
    end else begin
        csr_debug_mm2s_addr_ren_ff <= csr_debug_mm2s_addr_ren;
    end
end
//---------------------
// Bit field:
// DEBUG_MM2S_ADDR[31:0] - ADDR - Indicates the Start Address
// access: rw, hardware: o
//---------------------
reg [31:0] csr_debug_mm2s_addr_addr_ff;

assign csr_debug_mm2s_addr_rdata[31:0] = csr_debug_mm2s_addr_addr_ff;

assign csr_debug_mm2s_addr_addr_out = csr_debug_mm2s_addr_addr_ff;

always @(posedge clk) begin
    if (rst) begin
        csr_debug_mm2s_addr_addr_ff <= 32'h0;
    end else  begin
    if (csr_debug_mm2s_addr_wen) begin
            if (wstrb[0]) begin
                csr_debug_mm2s_addr_addr_ff[7:0] <= wdata[7:0];
            end
            if (wstrb[1]) begin
                csr_debug_mm2s_addr_addr_ff[15:8] <= wdata[15:8];
            end
            if (wstrb[2]) begin
                csr_debug_mm2s_addr_addr_ff[23:16] <= wdata[23:16];
            end
            if (wstrb[3]) begin
                csr_debug_mm2s_addr_addr_ff[31:24] <= wdata[31:24];
            end
        end else begin
            csr_debug_mm2s_addr_addr_ff <= csr_debug_mm2s_addr_addr_ff;
        end
    end
end


//------------------------------------------------------------------------------
// CSR:
// [0xfc] - DEBUG_S2MM_ADDR - S2MM Start address
//------------------------------------------------------------------------------
wire [31:0] csr_debug_s2mm_addr_rdata;

wire csr_debug_s2mm_addr_wen;
assign csr_debug_s2mm_addr_wen = wen && (waddr == 8'hfc);

wire csr_debug_s2mm_addr_ren;
assign csr_debug_s2mm_addr_ren = ren && (raddr == 8'hfc);
reg csr_debug_s2mm_addr_ren_ff;
always @(posedge clk) begin
    if (rst) begin
        csr_debug_s2mm_addr_ren_ff <= 1'b0;
    end else begin
        csr_debug_s2mm_addr_ren_ff <= csr_debug_s2mm_addr_ren;
    end
end
//---------------------
// Bit field:
// DEBUG_S2MM_ADDR[31:0] - ADDR - Indicates the Start Address
// access: rw, hardware: o
//---------------------
reg [31:0] csr_debug_s2mm_addr_addr_ff;

assign csr_debug_s2mm_addr_rdata[31:0] = csr_debug_s2mm_addr_addr_ff;

assign csr_debug_s2mm_addr_addr_out = csr_debug_s2mm_addr_addr_ff;

always @(posedge clk) begin
    if (rst) begin
        csr_debug_s2mm_addr_addr_ff <= 32'h0;
    end else  begin
    if (csr_debug_s2mm_addr_wen) begin
            if (wstrb[0]) begin
                csr_debug_s2mm_addr_addr_ff[7:0] <= wdata[7:0];
            end
            if (wstrb[1]) begin
                csr_debug_s2mm_addr_addr_ff[15:8] <= wdata[15:8];
            end
            if (wstrb[2]) begin
                csr_debug_s2mm_addr_addr_ff[23:16] <= wdata[23:16];
            end
            if (wstrb[3]) begin
                csr_debug_s2mm_addr_addr_ff[31:24] <= wdata[31:24];
            end
        end else begin
            csr_debug_s2mm_addr_addr_ff <= csr_debug_s2mm_addr_addr_ff;
        end
    end
end


//------------------------------------------------------------------------------
// Write ready
//------------------------------------------------------------------------------
assign wready = 1'b1;

//------------------------------------------------------------------------------
// Read address decoder
//------------------------------------------------------------------------------
reg [31:0] rdata_ff;
always @(posedge clk) begin
    if (rst) begin
        rdata_ff <= 32'h0;
    end else if (ren) begin
        case (raddr)
            8'hf0: rdata_ff <= csr_debug_cr_rdata;
            8'hf4: rdata_ff <= csr_debug_sr_rdata;
            8'hf8: rdata_ff <= csr_debug_mm2s_addr_rdata;
            8'hfc: rdata_ff <= csr_debug_s2mm_addr_rdata;
            default: rdata_ff <= 32'h0;
        endcase
    end else begin
        rdata_ff <= 32'h0;
    end
end
assign rdata = rdata_ff;

//------------------------------------------------------------------------------
// Read data valid
//------------------------------------------------------------------------------
reg rvalid_ff;
always @(posedge clk) begin
    if (rst) begin
        rvalid_ff <= 1'b0;
    end else if (ren && rvalid) begin
        rvalid_ff <= 1'b0;
    end else if (ren) begin
        rvalid_ff <= 1'b1;
    end
end

assign rvalid = rvalid_ff;

endmodule