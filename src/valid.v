// valid.v - Cache valid bit memory
// One valid bit per cache line. Reset clears all valid bits.
module valid (clk, line, reset, wr, dout);
parameter bitsLinesCache = 2;
parameter linesCache     = 4;

input clk;
input [bitsLinesCache-1:0] line;
input reset;
input wr;
output wire dout;

reg memory [0:linesCache-1];

integer i;
always @(posedge clk) begin
  if (reset)
    for (i = 0; i < linesCache; i = i + 1)
      memory[i] <= 0;
  else if (wr)
    memory[line] <= 1;
end

assign dout = memory[line];

endmodule