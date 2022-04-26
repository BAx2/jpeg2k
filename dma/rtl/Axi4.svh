`ifndef AXI4_SVH_
`define AXI4_SVH_

enum logic [1:0]
{
    Fixed  = 'b00,
    Incr   = 'b01,
    Wrap   = 'b10,
    Reserv = 'b11
} BurstType;

enum logic [2:0] 
{
    Byte1   = 'b000,
    Byte2   = 'b001,
    Byte4   = 'b010,
    Byte8   = 'b011,
    Byte16  = 'b100,
    Byte32  = 'b101,
    Byte64  = 'b110,
    Byte128 = 'b111
} MaxTransferBytes;

enum logic [3:0] 
{
    DevNonBuff              = 'b0000,
    DevBuff                 = 'b0001,
    NormalNonCachNonBuff    = 'b0010,
    NormalNonCachBuff       = 'b0011
    // ... others :)
} MemType;

// enum logic [2:0] 
// {
//     Unprivileged    = 0 << 0,
//     Privileged      = 1 << 0,
//     Secure          = 0 << 1,
//     NonSecure       = 1 << 1,
//     Data            = 0 << 2,
//     Instruction     = 1 << 2
// } AccessPermissions;

`endif // AXI4_SVH_