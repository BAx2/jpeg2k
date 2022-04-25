module ReorderBuffer #(
    parameter DataWidth = 16,
    parameter MaxLineSize = 512
) (
    input logic clk_i,
    input logic rst_i,

    Axis.Slave  s_axis,
    Axis.Master m_axis,
    
    output logic writeData_o
);
    typedef enum {
        ReadSlave,
        WriteMaster
    } State_t;

    State_t state, nextState;

    localparam MemoryAddrWidth = $clog2(MaxLineSize);
    logic [MemoryAddrWidth:0] wcnt, rcnt;
    logic we;
    logic re;

    Bram #(
        .DataWidth(DataWidth),
        .AddrWidth(MemoryAddrWidth)
    ) BramInst (
        .clka_i(clk_i),
        .wea_i(we),
        .ena_i(1'b1),
        .addra_i(wcnt),
        .dina_i(s_axis.data),
        .douta_o(),

        .clkb_i(clk_i),
        .web_i(1'b0),
        .enb_i((state == ReadSlave) | m_axis.ready),
        .addrb_i(rcnt),
        .dinb_i({DataWidth{1'b0}}),
        .doutb_o(m_axis.data)
    );

    assign s_axis.ready = (state == ReadSlave);
    assign we = s_axis.valid & s_axis.ready & (state == ReadSlave);
    assign re = (state == WriteMaster) & m_axis.ready | 
                (state == ReadSlave) & s_axis.eol & s_axis.ready & s_axis.valid;
    assign m_axis.valid = (state == WriteMaster);

    logic sof;
    always_ff @(posedge clk_i) begin
        if (s_axis.sof & s_axis.valid & s_axis.ready & (state == ReadSlave)) begin
            sof <= 1'b1;
        end else if (m_axis.valid & m_axis.ready)
            sof <= 1'b0;
    end
    assign m_axis.sof = sof;

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            wcnt <= 0;
        end else if (we) begin
            wcnt <= wcnt + 1;
        end else if (m_axis.valid & m_axis.ready & (nextState == ReadSlave)) begin
            wcnt <= 0;
        end
    end

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
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
    always_ff @(posedge clk_i) begin
        if (m_axis.valid & m_axis.ready) begin
            lastValue <= rcnt == wcnt - 1;
        end
    end
    assign m_axis.eol = lastValue;

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            state <= ReadSlave;
        end else begin
            state <= nextState;
        end
    end

    always_comb begin
        case (state)
        ReadSlave: 
            if (s_axis.valid & s_axis.ready & s_axis.eol) 
                nextState = WriteMaster;
            else
                nextState = ReadSlave;
        WriteMaster:
            if (lastValue & m_axis.ready & m_axis.valid) 
                nextState = ReadSlave;
            else
                nextState = WriteMaster;
        default:
            nextState = state;
        endcase
    end

    assign writeData_o = (state == WriteMaster);
    
endmodule