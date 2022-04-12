module AxisMux (
    Axis.Slave  in0,
    Axis.Slave  in1,
    Axis.Master out,
    input logic select
);
    always_comb begin
        case (select)
        0: begin
            out.data  = in0.data;
            out.sof   = in0.sof;
            out.eol   = in0.eol;
            out.valid = in0.valid;
            in0.ready = out.ready;
            in1.ready = 0;
        end
        default: begin
            out.data  = in1.data;
            out.sof   = in1.sof;
            out.eol   = in1.eol;
            out.valid = in1.valid;
            in1.ready = out.ready;
            in0.ready = 0;            
        end
        endcase
    end
endmodule