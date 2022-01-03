`timescale 1ns / 1ns

module tb_dwt ();
    
    localparam ClkPeriod    = 10ns;
    localparam DataWidth    = 16;
    localparam Point        = 10;
    localparam SideSize     = 16;

    real src_data [0:SideSize-1][0:SideSize-1];
    logic [DataWidth-1:0] in_data[0:15][0:15];
    logic [DataWidth-1:0] out_data[0:15][0:15];
    real dst_data [0:SideSize-1][0:SideSize-1];

    initial begin
        for (int y = 0; y < SideSize; y++) begin
            for (int x = 0; x < SideSize; x++) begin
                in_data[y][x] = src_data[y][x] * (2**Point);
            end
        end
    end

    logic clk;
    initial clk = 0;
    always #(ClkPeriod/2) clk = ~clk;

    always_ff @(posedge clk)
    begin
        
    end  

endmodule