module Mux2 #(
    parameter Width = 16
) (
    input   logic   [Width-1:0] a_i,
    input   logic   [Width-1:0] b_i,
    input   logic               s_i,
    output  logic   [Width-1:0] m_o
);
    assign m_o = s_i ? b_i : a_i;
endmodule