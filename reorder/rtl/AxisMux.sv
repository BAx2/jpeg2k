module AxisMux (
    Axis.Slave  s0_axis,
    Axis.Slave  s1_axis,
    Axis.Master m_axis,
    input logic select_i
);
    always_comb begin
        case (select_i)
        0: begin
            m_axis.data   = s0_axis.data;
            m_axis.sof    = s0_axis.sof;
            m_axis.eol    = s0_axis.eol;
            m_axis.valid  = s0_axis.valid;
            s0_axis.ready = m_axis.ready;
            s1_axis.ready = 0;
        end
        default: begin
            m_axis.data   = s1_axis.data;
            m_axis.sof    = s1_axis.sof;
            m_axis.eol    = s1_axis.eol;
            m_axis.valid  = s1_axis.valid;
            s1_axis.ready = m_axis.ready;
            s0_axis.ready = 0;            
        end
        endcase
    end
endmodule