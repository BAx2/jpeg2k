module Multiplier #(
    parameter AWidth   = 16,
    parameter APoint   = 10,

    parameter BWidth   = 16,
    parameter BPoint   = 10,

    parameter OutWidth = 16,
    parameter OutPoint = 10
)(
    input   logic   signed  [AWidth-1:0]    a_i,
    input   logic   signed  [BWidth-1:0]    b_i,
    output  logic   signed  [OutWidth-1:0]  m_o
);

    localparam InternalPoint = APoint + BPoint;    
    localparam LowSignificantBit = InternalPoint - OutPoint;

    logic signed [AWidth+BWidth-1:0] m;
    assign m = a_i * b_i;

    assign m_o = m[OutWidth+LowSignificantBit-1:LowSignificantBit];

    // sim 
    real ra, rb, rmi, rm;
    assign ra  = a_i    / (2.0 ** APoint);
    assign rb  = b_i    / (2.0 ** BPoint);
    assign rmi = m      / (2.0 ** InternalPoint);
    assign rm  = m_o    / (2.0 ** OutPoint);

endmodule