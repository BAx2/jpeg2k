module ReorderBuffer #(
    parameter DataWidth = 16,
    parameter MaxLineSize = 512
) (
    Axis.Slave  in,
    Axis.Master out,
    
    output logic writeData
);
    typedef enum {
        ReadSlave,
        WriteMaster
    } State_t;

    State_t state, nextState;

    logic clk, rst;
    assign clk = in.clk,
           rst = in.rst;

    logic [$clog2(MaxLineSize):0] wcnt, rcnt;
    logic we;
    logic re;

    Bram #(
        .DataWidth(DataWidth),
        .Size(MaxLineSize)
    ) BramInst (
        .clka(clk),
        .wea(we),
        .ena(1'b1),
        .addra(wcnt),
        .dina(in.data),
        .douta(),

        .clkb(clk),
        .web(1'b0),
        .enb((state == ReadSlave) | out.ready),
        .addrb(rcnt),
        .dinb({DataWidth{1'b0}}),
        .doutb(out.data)
    );

    assign in.ready = (state == ReadSlave);
    assign we = in.valid & in.ready & (state == ReadSlave);
    assign re = (state == WriteMaster) & out.ready | 
                (state == ReadSlave) & in.eol & in.ready & in.valid;
    assign out.valid = (state == WriteMaster);

    logic sof;
    always_ff @(posedge clk) begin
        if (in.sof & in.valid & in.ready & (state == ReadSlave)) begin
            sof <= 1'b1;
        end else if (out.valid & out.ready)
            sof <= 1'b0;
    end
    assign out.sof = sof;

    always_ff @(posedge clk) begin
        if (rst) begin
            wcnt <= 0;
        end else if (we) begin
            wcnt <= wcnt + 1;
        end else if (out.valid & out.ready & (nextState == ReadSlave)) begin
            wcnt <= 0;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            rcnt <= 0;
        end else if (re) begin
            if (rcnt == wcnt - 2) begin
                rcnt <= 'b1;                
            end else if (rcnt == wcnt - 1) begin
                rcnt <= 0;
            end else if (nextState != ReadSlave) begin
                rcnt <= rcnt + 2;
            end
        end
    end

    logic lastValue;
    always_ff @(posedge clk) begin
        if (out.valid & out.ready) begin
            lastValue <= rcnt == wcnt - 1;
        end
    end
    assign out.eol = lastValue;

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= ReadSlave;
        end else begin
            state <= nextState;
        end
    end

    always_comb begin
        case (state)
        ReadSlave: 
            if (in.valid & in.ready & in.eol) 
                nextState = WriteMaster;
            else
                nextState = ReadSlave;
        WriteMaster:
            if (lastValue & out.ready & out.valid) 
                nextState = ReadSlave;
            else
                nextState = WriteMaster;
        endcase
    end

    assign writeData = (state == WriteMaster);
    
endmodule