// Mtag.v - Cache tag memory (4 registros explicitos, sem inferencia de RAM)
module Mtag (clk, line, din, wr, dout, reset);
parameter bitsLinesCache = 2;
parameter bitsTag        = 6;
parameter linesCache     = 4;

input clk;
input  [bitsLinesCache-1:0] line;
input  [bitsTag-1:0]        din;
input  wr;
output reg [bitsTag-1:0]    dout;
input  reset;

reg [bitsTag-1:0] m0, m1, m2, m3;

always @(posedge clk) begin
    if (reset) begin
        m0 <= 0; m1 <= 0; m2 <= 0; m3 <= 0;
    end else if (wr) begin
        case (line)
            2'd0: m0 <= din;
            2'd1: m1 <= din;
            2'd2: m2 <= din;
            2'd3: m3 <= din;
        endcase
    end
end

always @(*) begin
    case (line)
        2'd0: dout = m0;
        2'd1: dout = m1;
        2'd2: dout = m2;
        2'd3: dout = m3;
        default: dout = 0;
    endcase
end

endmodule