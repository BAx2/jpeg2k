interface AxiLite #(
    parameter ADDR_W = 8,
    parameter DATA_W = 32,
    parameter STRB_W = DATA_W / 8
)(
    input logic clk
);
    typedef logic [ADDR_W-1:0] addr_t; 
    typedef logic [DATA_W-1:0] data_t;
    // AW
    addr_t             awaddr;
    logic [2:0]        awprot;
    logic              awvalid;
    logic              awready;
    // W
    data_t             wdata;
    logic [STRB_W-1:0] wstrb;
    logic              wvalid;
    logic              wready;
    // B
    logic [1:0]        bresp;
    logic              bvalid;
    logic              bready;
    // AR
    addr_t             araddr;
    logic [2:0]        arprot;
    logic              arvalid;
    logic              arready;
    // R
    data_t             rdata;
    logic [1:0]        rresp;
    logic              rvalid;
    logic              rready;

    `define WAIT_UNTIL(signal) while ((signal)) @(posedge clk);

    task automatic Write(input addr_t addr, input data_t data);
        @(posedge clk);
        awaddr = addr;
        awvalid = 1;
        wdata = data;
        wvalid = 1;

        @(posedge clk);
        `WAIT_UNTIL((awready == 0) && (wready == 0));
        awvalid = 0;
        wvalid = 0;

        `WAIT_UNTIL(bvalid == 0);
        $display("\t\t Axi4 Lite: %5t \t Write  \t Addr: 0x%2h \t Data: 0x%8h", $time, addr, data);
    endtask

    task automatic Read(input addr_t addr, output data_t data);
        @(posedge clk);
        araddr = addr;
        arvalid = 1;
        @(posedge clk);
        `WAIT_UNTIL(arready == 0);
        arvalid = 0;

        `WAIT_UNTIL(rvalid == 0);
        data = rdata;

        $display("\t\t Axi4 Lite: %5t \t Read   \t Addr: 0x%2h \t Data: 0x%8h", $time, addr, data);
    endtask

    task automatic Reset();
        awaddr = 0;
        awprot = 0;
        awvalid = 0;
        
        wdata = 0;
        wstrb = {STRB_W{1'b1}};
        wvalid = 0;

        bready = 1'b1;
        
        araddr = 0;
        arprot = 0;
        arvalid = 0;
        
        rready = 1'b1;
    endtask

endinterface //AxiLite