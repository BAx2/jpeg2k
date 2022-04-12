module Bram #(
    parameter DataWidth = 16,
    parameter Size = 512
) (
    input  logic clka,
    input  logic wea,
    input  logic ena,
    input  logic [$clog2(Size)-1:0] addra,
    input  logic [DataWidth-1:0] dina,
    output logic [DataWidth-1:0] douta,

    input  logic clkb,
    input  logic web,
    input  logic enb,
    input  logic [$clog2(Size)-1:0] addrb,
    input  logic [DataWidth-1:0] dinb,
    output logic [DataWidth-1:0] doutb
);

typedef logic [DataWidth-1:0] Data_t;
Data_t ram [0:Size-1];

always_ff @(posedge clka) begin
    if (ena) begin
        if (wea)
            ram[addra] <= dina;
        douta <= ram[addra];
    end
end

always_ff @(posedge clkb) begin
    if (enb) begin
        if (web)
            ram[addrb] <= dinb;
        doutb <= ram[addrb];
    end
end

endmodule