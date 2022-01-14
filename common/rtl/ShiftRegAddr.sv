module ShiftRegAddr #(
    parameter Width = 1,
    parameter Depth = 1
) (
    input   logic                       clk_i,
    input   logic                       en_i,
    input   logic   [Width-1:0]         din_i,
    input   logic   [$clog2(Depth)-1:0] addr_i,
    output  logic   [Width-1:0]         dout_o
);
    logic   [Width-1:0] shreg [Depth-1:0];

    always_ff @(posedge clk_i) begin
        if (en_i) begin
            if (Depth == 1) begin
                shreg[0] <= din_i;
            end else begin
                shreg <= {shreg[Depth-2:0], din_i};
            end
        end
    end
    
    assign dout_o = (Depth == 0) ? din_i : shreg[addr_i];

endmodule