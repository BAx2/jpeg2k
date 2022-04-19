module tb ();
    
localparam DataWidth = 8;
localparam MaxLineSize = 8;
localparam DoubleBuff = 1;

localparam WriteLineNum = 8;
localparam RandomOutReady = 1;
localparam RandomInValid = 1;

logic clk, rst;
Axis #(.DataWidth(DataWidth)) out();
Axis #(.DataWidth(DataWidth)) in();

InLineReorder #(
    .DataWidth(DataWidth),
    .MaxLineSize(MaxLineSize),
    .DoubleBuff(DoubleBuff)
) DUT (
    .clk_i(clk)
    .rst_i(rst)
    .s_axis(in),
    .m_axis(out)
);

always #5 clk = !clk;

typedef logic [DataWidth-1:0] Data_t;
Data_t arr [0:MaxLineSize+1];
Data_t outVal;

task automatic WriteAxis(Data_t data, logic sof, logic eol);
    in.data = data;
    in.sof = sof;
    in.eol = eol;
    while (!(in.valid & in.ready)) @(negedge clk);
    @(negedge clk);
    in.sof = 0;
    in.eol = 0;
    in.valid = 0;
endtask

task automatic WriteLine();
    for (int i = 0; i < 8; i++) begin
        WriteAxis(outVal, (i==0), (i==7));
        outVal++;
    end
    outVal = (outVal & 'hF0) + 'h10;
endtask //automatic

initial begin
    outVal = 0;
    clk = 0;
    rst = 1;

    in.valid = 0;
    in.data = -1;
    in.sof = 0;
    in.eol = 0;

    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    rst = 0;
    @(posedge clk);

    for (int i = 0; i < WriteLineNum; i++)
        WriteLine();
end


int waddr = 0;
always @(posedge clk) begin
    if (out.valid & out.ready) begin
        arr[waddr] = out.data;
        waddr++;
        if (out.eol)
            waddr = 0;
    end
end

always @(posedge clk) begin
    out.ready = RandomOutReady ? $urandom_range(0, 1) : 1;
    in.valid = RandomInValid ? $urandom_range(0, 1) : 1;
end

endmodule