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
    localparam InternalWidth = AWidth+BWidth;

    logic signed [InternalWidth-1:0] m;
    assign m = a_i * b_i;

    assign m_o = m[OutWidth+LowSignificantBit-1:LowSignificantBit];

    // sim 
    real ra, rb, rmi, rm;
    assign ra  = a_i    / (2.0 ** APoint);
    assign rb  = b_i    / (2.0 ** BPoint);
    assign rmi = m      / (2.0 ** InternalPoint);
    assign rm  = m_o    / (2.0 ** OutPoint);
    
    logic overflow;
    always_comb begin
        overflow = 0;
        for (int i = OutWidth+LowSignificantBit; i < InternalWidth; i++) begin
            overflow = overflow || (m[i] != m[OutWidth+LowSignificantBit-1]);
        end
        assert (overflow == 0) else 
            $display("\t\tTime: %5t \t Multiplier overflow(a = %3.3f b = %3.3f intMul = %3.3f outMul = %3.3f)", 
                     $time, ra, rb, rmi, rm);
    end

endmodule
