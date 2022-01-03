module Dffenr #(
    parameter Width = 16
) (
    input   logic               clk_i,
    input   logic               rst_i,
    input   logic               en_i,
    input   logic [Width-1:0]   din_i,
    output  logic [Width-1:0]   dout_o
);
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            dout_o <= 'b0;
        end else begin
            if (en_i) begin
                dout_o <= din_i;
            end
        end
    end
endmodule