module AxisDemux (
    Axis.Slave  in,
    Axis.Master out0,
    Axis.Master out1,
    input logic select
);
    always_comb begin
        case (select)
        0: begin
            out0.data  = in.data;
            out0.sof   = in.sof;
            out0.eol   = in.eol;
            out0.valid = in.valid;
            in.ready   = out0.ready;
            out1.data  = 0;
            out1.sof   = 0;
            out1.eol   = 0;
            out1.valid = 0;
        end
        default: begin
            out0.data  = 0;
            out0.sof   = 0;
            out0.eol   = 0;
            out0.valid = 0;
            in.ready   = out1.ready;
            out1.data  = in.data;
            out1.sof   = in.sof;
            out1.eol   = in.eol;
            out1.valid = in.valid;
        end
        endcase
    end
endmodule