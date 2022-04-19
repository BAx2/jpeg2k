
interface Axis #(
    parameter DataWidth = 8
)(
    // input logic clk,
    // input logic rst
);

logic [DataWidth-1 : 0] data;
logic valid;
logic ready;
logic sof;
logic eol;

modport Master (
    // input clk,
    // input rst,
    output data,
    output sof,
    output eol,
    output valid,
    input ready
);

modport Slave (
    // input clk,
    // input rst,
    input data,
    input valid,
    input sof,
    input eol,
    output ready
);

modport Monitor (
    // input clk,
    // input rst,
    input data,
    input sof,
    input eol,
    input valid,
    input ready
);
    
endinterface : Axis //Axis