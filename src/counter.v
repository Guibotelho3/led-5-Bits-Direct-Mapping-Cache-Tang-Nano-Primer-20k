// counter.v - Parameterized block counter (0 to blockSize-1)
// Generates sequential addresses to fill a cache line from RAM.
module counter(out, clk, reset, End);
parameter bitsBlock = 3;
parameter blockSize = 8;

output [bitsBlock-1:0] out;
input                  clk, reset;
output                 End;

reg [bitsBlock-1:0] out;
reg                 End;
wire [bitsBlock-1:0] limitCounter = blockSize - 1;

always @(posedge clk) begin
  if (reset) begin
    out <= 0;
    End <= 0;
  end else begin
    out <= out + {{(bitsBlock-1){1'b0}}, 1'b1};
    End <= (out == limitCounter - 1); // End sobe 1 ciclo antes, fica 1 quando out==limitCounter
  end
end

endmodule