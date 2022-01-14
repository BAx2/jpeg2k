module AxisReg #(
    parameter DataWidth = 16,
    parameter Transperent = 0
) (
    input   logic                       clk_i,
    input   logic                       rst_i,

    input   logic   [DataWidth-1:0]     s_data_i,
    input   logic                       s_valid_i,
    output  logic                       s_ready_o,

    input   logic                       m_ready_i,
    output  logic                       m_valid_o,
    output  logic   [DataWidth-1:0]     m_data_o
);
    generate
        if (Transperent) begin
            assign m_valid_o = s_valid_i,
                   m_data_o = s_data_i,
                   s_ready_o = m_ready_i;
                   
        end else begin
            logic [DataWidth-1:0] data;
            logic                 valid;
        
            always_ff @(posedge clk_i) begin
                if (rst_i) begin
                    data <= 0;
                    valid <= 0;
                end else begin
                    if (s_ready_o) begin
                        data <= s_data_i;
                        valid <= s_valid_i;
                    end
                end
            end
        
            assign s_ready_o = !valid | (valid & m_ready_i);
            assign m_data_o  = data;
            assign m_valid_o = valid;                    
        end
    endgenerate
    
endmodule