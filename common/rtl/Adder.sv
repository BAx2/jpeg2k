module Adder #(
    parameter Width = 16
) (
    input   logic   [Width-1:0]     a_i,
    input   logic   [Width-1:0]     b_i,
    output  logic   [Width-1:0]     s_o
);
    assign s_o = a_i + b_i;
endmodule