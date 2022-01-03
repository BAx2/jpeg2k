module Counter #(
    parameter Width = 16,
    parameter RstVal = 0
) (
    input   logic                   clk_i,
    input   logic                   rst_i,
    input   logic                   en_i,
    output  logic   [Width-1:0]     val_o
);

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            val_o <= RstVal;
        end else if (en_i) begin
            val_o <= val_o + 1;
        end
    end
    
endmodule