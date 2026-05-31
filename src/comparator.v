// comparator.v - Tag comparator
// Compares current address tag to the tag stored in cache.
module comparator(out, tag, tag_in);
parameter bitsTag = 6;

output  out;
input   [bitsTag-1:0] tag;
input   [bitsTag-1:0] tag_in;

assign out = (tag == tag_in) ? 1 : 0;

endmodule