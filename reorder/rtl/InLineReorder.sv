module InLineReorder #(
    parameter DataWidth = 16,
    parameter MaxLineSize = 512, 
    parameter DoubleBuff = 1
) (
    input logic clk_i,
    input logic rst_i,

    Axis.Slave  s_axis,
    Axis.Master m_axis
);
    logic writeData0, writeData1;
    Axis #(.DataWidth(DataWidth)) buffIn1();
    Axis #(.DataWidth(DataWidth)) buffOut1();
    Axis #(.DataWidth(DataWidth)) buffIn2();
    Axis #(.DataWidth(DataWidth)) buffOut2();

    ReorderBuffer #(
        .DataWidth(DataWidth),
        .MaxLineSize(MaxLineSize)
    ) ReorderBufferInst1 (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .s_axis(buffIn1),
        .m_axis(buffOut1),
        .writeData_o(writeData0)
    );

    ReorderBuffer #(
        .DataWidth(DataWidth),
        .MaxLineSize(MaxLineSize)
    ) ReorderBufferInst2 (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .s_axis(buffIn2),
        .m_axis(buffOut2),
        .writeData_o(writeData1)
    );

    logic currentInputBuffer;

    AxisDemux DemuxInst (
        .s_axis(s_axis),
        .m0_axis(buffIn1),
        .m1_axis(buffIn2),
        .select_i(currentInputBuffer)
    );

    generate
        if (DoubleBuff) begin
            AxisMux MuxInst (
                .s0_axis(buffOut1),
                .s1_axis(buffOut2),
                .m_axis(m_axis),
                .select_i(!currentInputBuffer)
            );
            always_ff @(posedge clk_i) begin
                if (rst_i) begin
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
                .s0_axis(buffOut1),
                .s1_axis(buffOut2),
                .m_axis(m_axis),
                .select_i(currentInputBuffer)
            );
            assign currentInputBuffer = 0;
        end
    endgenerate

endmodule