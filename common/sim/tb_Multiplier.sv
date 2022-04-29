module tb_Multiplyer ();
    
    parameter AWidth   = 16;
    parameter APoint   = 12;

    parameter BWidth   = 16;
    parameter BPoint   = 8;

    parameter OutWidth = 16;
    parameter OutPoint = 10;

    logic   signed  [AWidth-1:0]    a;
    logic   signed  [BWidth-1:0]    b;
    logic   signed  [OutWidth-1:0]  m;

    function int ToFixed(real a, int point);
        ToFixed = $rtoi(a * (2.0 ** point));  
    endfunction

    function real ToReal(int num, int point);
        ToReal = $itor(num) / (2.0 ** point);
    endfunction

    real ra, rb, rm;
    assign a = ToFixed(ra, APoint),
           b = ToFixed(rb, BPoint),
           rm = ToReal(m, OutPoint);

    initial begin
        ra = 1.5;
        rb = 2.0;
        #10;
        ra = 0.25;
        rb = -7.0;
        #10;
        ra = -0.1;
        rb = -4.1;
        #10;
    end

    Multiplier #(
        .AWidth(AWidth),
        .APoint(APoint),
        .BWidth(BWidth),
        .BPoint(BPoint),
        .OutWidth(OutWidth),
        .OutPoint(OutPoint)
    ) DUT (
        .a_i(a),
        .b_i(b),
        .m_o(m)
    );
endmodule