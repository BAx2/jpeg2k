module Multiplyer #(
    parameter Width = 16,
    parameter InPoint = 10,
    parameter OutPoint = 10
)(
    input   logic   signed  [Width-1:0]     a_i,
    input   logic   signed  [Width-1:0]     b_i,
    output  logic   signed  [Width-1:0]     m_o
);
    localparam LowSignificantBit = 2*InPoint - OutPoint;
    
    logic signed [Width*2 - 1:0] m;
    assign m = a_i * b_i;

    assign m_o = m[Width+LowSignificantBit-1:LowSignificantBit];

    // sim 
    real ra, rb, rmi, rm;
    assign ra  = a_i    / (2.0 ** InPoint);
    assign rb  = b_i    / (2.0 ** InPoint);
    assign rmi = m      / (2.0 ** (2 * InPoint));
    assign rm  = m_o    / (2.0 ** OutPoint);

endmodule