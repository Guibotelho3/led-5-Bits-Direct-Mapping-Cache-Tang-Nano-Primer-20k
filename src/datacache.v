// datacache.v - Cache data memory
// Stores data blocks. Address = {line, blk}.
module datacache (clk, line, blk, din, wr, dout);
parameter bitsBlock     = 3;  // 2^3 = 8 bytes per block
parameter bitLinesCache = 2;  // 2^2 = 4 lines
parameter cacheSize     = 32; // 4 lines * 8 bytes = 32 bytes

input clk;
input  [bitLinesCache-1:0] line;
input  [bitsBlock-1:0]     blk;
input  [7:0]               din;
input  wr;
output [7:0]               dout;

reg [7:0] memory [0:cacheSize-1];
reg [7:0] dout;

always @(posedge clk)
  if (wr)
    memory[{line, blk}] <= din;

always @(*)
  dout <= memory[{line, blk}];

endmodule