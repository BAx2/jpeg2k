module AxisReg #(
    parameter DataWidth = 16,
    parameter Transperent = 0,
    parameter Pipelined = 0
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
            if (!Pipelined) begin
                logic [DataWidth-1:0] data;
                logic                 valid;
            
                Dffenr #(
                    .Width(DataWidth),
                    .ResetVal(0)
                ) DataReg (
                    .clk_i(clk_i),
                    .rst_i(1'b0),
                    .en_i(s_ready_o),
                    .din_i(s_data_i),
                    .dout_o(data)
                );

                Dffenr #(
                    .Width(1),
                    .ResetVal(0)
                ) ValidReg (
                    .clk_i(clk_i),
                    .rst_i(rst_i),
                    .en_i(s_ready_o),
                    .din_i(s_valid_i),
                    .dout_o(valid)
                );
            
                assign s_ready_o = !valid | (valid & m_ready_i);
                assign m_data_o  = data;
                assign m_valid_o = valid;                    
            end else begin
                
                logic buffer_wr;
                logic [DataWidth-1:0] buffer_data;

                Dffenr #(
                    .Width(DataWidth),
                    .ResetVal(0)
                ) BufferInst (
                    .clk_i(clk_i),
                    .rst_i(1'b0),
                    .en_i(buffer_wr),
                    .din_i(s_data_i),
                    .dout_o(buffer_data)
                );

                logic output_wr;
                logic [DataWidth-1:0] selected_data;
                
                Dffenr #(
                    .Width(DataWidth),
                    .ResetVal(0)
                ) OutputRegInst (
                    .clk_i(clk_i),
                    .rst_i(1'b0),
                    .en_i(output_wr),
                    .din_i(selected_data),
                    .dout_o(m_data_o)
                );

                logic use_input_data;
                assign selected_data = use_input_data ? s_data_i : buffer_data;

                typedef enum { Empty, Half, Full } State;
                State state, next_state;

                logic has_input_data, has_output_data;
                assign has_input_data = s_valid_i & s_ready_o;
                assign has_output_data = m_valid_o & m_ready_i;

                always_ff @(posedge clk_i) begin
                    if (rst_i) begin
                        state <= Empty;
                    end else begin
                        state <= next_state;
                    end
                end

                always_comb begin
                    case (state)
                        Empty: begin
                            next_state = has_input_data ? Half : Empty;
                        end
                        Half: begin
                            case ({has_input_data, has_output_data})
                                2'b00: next_state = Half;
                                2'b01: next_state = Empty;
                                2'b10: next_state = Full;
                                default: next_state = Half;
                            endcase
                        end
                        Full: begin
                            next_state = has_output_data ? Half : Full;
                        end
                        default: begin
                            next_state = state; 
                        end
                    endcase
                end

                always_ff @(posedge clk_i) begin
                    if (rst_i) begin
                        s_ready_o <= 1;
                        m_valid_o <= 0;
                    end else begin
                        s_ready_o <= (next_state != Full);
                        m_valid_o <= (next_state != Empty); 
                    end
                end

                assign output_wr = ((state == Empty) &&  has_input_data && !has_output_data) ||
                                   ((state == Half)  &&  has_input_data &&  has_output_data) ||
                                   ((state == Full)  && !has_input_data &&  has_output_data);

                assign buffer_wr = (state == Half) &&  has_input_data && !has_output_data;
                assign use_input_data = !((state == Full) && !has_input_data &&  has_output_data);
            end
        end
    endgenerate
endmodule