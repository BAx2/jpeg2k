module Transpose #(
    parameter DataWidth = 16
) (
    input   logic                                   clk_i,
    input   logic                                   rst_i,

    output  logic                                   s_ready_o,
    input   logic                                   s_valid_i,
    input   logic                                   s_sof_i,
    input   logic                                   s_eol_i,
    input   logic   [2*DataWidth-1:0]               s_data_i,

    input   logic                                   m_ready_i,
    output  logic                                   m_valid_o,
    output  logic                                   m_sof_o,
    output  logic                                   m_eol_o,
    output  logic   [2*DataWidth-1:0]               m_data_o
);
    typedef enum {  
        Start,
        Middle,
        End
    } state_t;
    state_t state, next_state;

    logic [DataWidth-1:0] even, odd;
    assign even = s_data_i[DataWidth-1:0];
    assign odd  = s_data_i[2*DataWidth-1:DataWidth];

    logic new_input_sample;
    assign new_input_sample = s_ready_o & s_valid_i;

    logic [DataWidth-1:0] odd_reg [1:0];
    logic [DataWidth-1:0] even_reg;
    always_ff @(posedge clk_i) begin
        if (new_input_sample) begin
            if (state != End) begin
                even_reg <= even;
                odd_reg  <= { odd_reg[0], odd };                
            end
        end
    end

    logic output_src;

    logic sof, eol;
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            sof <= 0;
       end else begin
            if (new_input_sample) begin
                sof <= s_sof_i;
            end
        end
    end

    // fsm
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            state <= Start;
        end else begin
            state <= next_state;
        end
    end

    always_comb begin
        case (state)
            Start: begin
                next_state = new_input_sample ? Middle : Start;
            end
            Middle: begin
                next_state = (new_input_sample & s_eol_i) ? End : Middle;
            end
            default: begin
                next_state = (m_ready_i) ? Start : End;
            end 
        endcase
    end

    // 
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            output_src <= 0;
        end else begin
            case (state)
                Start:      output_src <= 0;
                Middle:     output_src <= new_input_sample ? ~output_src : output_src;
                default:    output_src <= m_ready_i ? 0 : output_src;
            endcase
        end
    end

    // output assign
    always_comb begin
        case (state)
            Start:      s_ready_o = 1;
            Middle:     s_ready_o = m_ready_i; 
            default:    s_ready_o = 1;
        endcase        
    end

    logic [DataWidth-1:0] even_out, odd_out;
    assign even_out = output_src ? odd_reg[1] : even_reg;
    assign odd_out  = output_src ? odd_reg[0] : even    ;
    assign m_data_o  = { odd_out, even_out };

    always_comb begin
        case (state)
            Start:      m_valid_o = 0;
            Middle:     m_valid_o = new_input_sample; 
            default:    m_valid_o = 1;
        endcase        
    end

    assign m_eol_o   = (state == End);
    assign m_sof_o   = sof;

endmodule