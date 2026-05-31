// mux.v - Block address multiplexer
// Selects between request block address and internal block counter.
module mux(
  din_0,   // Mux first input
  din_1,   // Mux second input
  sel,     // Select input
  mux_out  // Mux output
);
parameter bitsBlock = 3;

input  [bitsBlock-1:0] din_0;
input  [bitsBlock-1:0] din_1;
input  sel;
output [bitsBlock-1:0] mux_out;

assign mux_out = (sel) ? din_1 : din_0;

endmodule
