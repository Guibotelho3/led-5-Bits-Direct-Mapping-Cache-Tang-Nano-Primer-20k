// ram.v - Main RAM memory
module ram (clk, addr, din, wr, dout, reset);
parameter bitsRam = 11;
parameter ramSize = 2048;

input clk;
input  [bitsRam-1:0] addr;
input  [7:0]         din;
input  wr;
output [7:0]         dout;
input  reset;

reg [7:0] memory [0:ramSize-1];
reg [7:0] dout;

initial $readmemh("ram_init.hex", memory);

always @(posedge clk)
    if (wr) memory[addr] <= din;

always @(*)
    dout <= memory[addr];

endmodule