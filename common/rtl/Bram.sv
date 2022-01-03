module Bram #(
    parameter DataWidth = 16,
    parameter AddrWidth = 9
) (
    input   logic                       clka_i,
    input   logic                       clkb_i,

    input   logic   [AddrWidth-1:0]     addra_i,
    input   logic                       wea_i,
    input   logic   [DataWidth-1:0]     dina_i, 
    output  logic   [DataWidth-1:0]     douta_o,
    
    input   logic   [AddrWidth-1:0]     addrb_i,
    input   logic                       web_i,
    input   logic   [DataWidth-1:0]     dinb_i,
    output  logic   [DataWidth-1:0]     doutb_o
);

    logic [DataWidth-1:0] ram [0:2**AddrWidth-1];

    always_ff @(posedge clka_i) begin
        if (wea_i) begin
            ram[addra_i] <= dina_i;
        end
        douta_o <= ram[addra_i];
    end

    always_ff @(posedge clkb_i) begin
        if (web_i) begin
            ram[addrb_i] <= dinb_i;
        end
        doutb_o <= ram[addrb_i];
    end

endmodule