module Adder #(
    parameter AWidth   = 16,
    parameter APoint   = 0,

    parameter BWidth   = 16,
    parameter BPoint   = 0,

    parameter OutWidth = 16,
    parameter OutPoint = 0
) (
    input   logic   signed  [AWidth-1:0]    a_i,
    input   logic   signed  [BWidth-1:0]    b_i,
    output  logic   signed  [OutWidth-1:0]  s_o
);
    localparam InternalPoint = (APoint > BPoint)
                             ? (APoint > OutPoint ? APoint : OutPoint) 
                             : (BPoint > OutPoint ? BPoint : OutPoint);
    
    localparam AIntPart = AWidth - APoint;
    localparam BIntPart = BWidth - BPoint;
    localparam OutIntPart = OutWidth - OutPoint;
    localparam IntPartSize = (AIntPart > BIntPart) 
                           ? (AIntPart > OutIntPart ? AIntPart : OutIntPart) 
                           : (BIntPart > OutIntPart ? BIntPart : OutIntPart);
    
    localparam AOffset = InternalPoint - APoint;
    localparam BOffset = InternalPoint - BPoint;
    localparam InternalWidth = IntPartSize+InternalPoint+1;
    localparam OutLsb = InternalPoint - OutPoint;

    logic signed [InternalWidth-1 : 0] sum;
    assign sum = (a_i << AOffset) + (b_i << BOffset);
    assign s_o = sum[OutWidth+OutLsb-1: OutLsb];

    // sim 
    real ra, rb, rsi, rs;
    assign ra  = a_i    / (2.0 ** APoint);
    assign rb  = b_i    / (2.0 ** BPoint);
    assign rsi = sum    / (2.0 ** InternalPoint);
    assign rs  = s_o    / (2.0 ** OutPoint);

    logic overflow;
    always_comb begin
        overflow = 0;
        for (int i = OutWidth+OutLsb; i < InternalWidth; i++) begin
            overflow = overflow || (sum[i] != sum[OutWidth+OutLsb-1]);
        end
        assert (overflow != 1) else 
            $display("\t\tTime: %5t \t Adder overflow(a = %3.3f b = %3.3f intSum = %3.3f outSum = %3.3f)", 
                     $time, ra, rb, rsi, rs);
    end

endmodule
