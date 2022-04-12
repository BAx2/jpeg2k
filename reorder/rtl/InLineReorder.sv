module InLineReorder #(
    parameter DataWidth = 16,
    parameter MaxLineSize = 512, 
    parameter DoubleBuff = 1
) (
    Axis.Slave  in,
    Axis.Master out
);
    logic clk, rst;
    assign clk = in.clk,
           rst = in.rst;

    logic writeData0, writeData1;
    Axis buffIn1(clk, rst), buffOut1(clk, rst), buffIn2(clk, rst), buffOut2(clk, rst);

    ReorderBuffer #(
        .DataWidth(DataWidth),
        .MaxLineSize(MaxLineSize)
    ) ReorderBufferInst1 (
        .in(buffIn1),
        .out(buffOut1),
        .writeData(writeData0)
    );

    ReorderBuffer #(
        .DataWidth(DataWidth),
        .MaxLineSize(MaxLineSize)
    ) ReorderBufferInst2 (
        .in(buffIn2),
        .out(buffOut2),
        .writeData(writeData1)
    );

    logic currentInputBuffer;

    AxisDemux DemuxInst (
        .in(in),
        .out0(buffIn1),
        .out1(buffIn2),
        .select(currentInputBuffer)
    );

    generate
        if (DoubleBuff) begin
            AxisMux MuxInst (
                .in0(buffOut1),
                .in1(buffOut2),
                .out(out),
                .select(!currentInputBuffer)
            );
            always_ff @(posedge clk) begin
                if (rst) begin
                    currentInputBuffer <= 0;
                end else begin
                    if ((currentInputBuffer == 0) & writeData0 & !writeData1)
                        currentInputBuffer <= 1;
                    if ((currentInputBuffer == 1) & !writeData0 & writeData1)
                        currentInputBuffer <= 0;
                end
            end
        end else begin
            AxisMux MuxInst (
                .in0(buffOut1),
                .in1(buffOut2),
                .out(out),
                .select(currentInputBuffer)
            );
            assign currentInputBuffer = 0;
        end
    endgenerate

endmodule