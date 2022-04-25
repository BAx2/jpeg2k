module AxisDemux (
    Axis.Slave  s_axis,
    Axis.Master m0_axis,
    Axis.Master m1_axis,
    input logic select_i
);
    always_comb begin
        case (select_i)
        0: begin
            m0_axis.data  = s_axis.data;
            m0_axis.sof   = s_axis.sof;
            m0_axis.eol   = s_axis.eol;
            m0_axis.valid = s_axis.valid;
            s_axis.ready  = m0_axis.ready;
            m1_axis.data  = 0;
            m1_axis.sof   = 0;
            m1_axis.eol   = 0;
            m1_axis.valid = 0;
        end
        default: begin
            m0_axis.data  = 0;
            m0_axis.sof   = 0;
            m0_axis.eol   = 0;
            m0_axis.valid = 0;
            s_axis.ready  = m1_axis.ready;
            m1_axis.data  = s_axis.data;
            m1_axis.sof   = s_axis.sof;
            m1_axis.eol   = s_axis.eol;
            m1_axis.valid = s_axis.valid;
        end
        endcase
    end
endmodule