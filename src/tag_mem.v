// tag_mem.v - Tag memory + valid bits (Mtag + valid combinados)
module tag_mem(
    input  wire        clk, reset, wr,
    input  wire [1:0]  line,
    input  wire [5:0]  tag_in,
    output wire [5:0]  tag_out,
    output wire        valid_out
);

reg [5:0] tag_m0, tag_m1, tag_m2, tag_m3;
reg       val_m0, val_m1, val_m2, val_m3;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        val_m0<=0; val_m1<=0; val_m2<=0; val_m3<=0;
        tag_m0<=0; tag_m1<=0; tag_m2<=0; tag_m3<=0;
    end else if (wr) begin
        case (line)
            2'd0: begin tag_m0 <= tag_in; val_m0 <= 1; end
            2'd1: begin tag_m1 <= tag_in; val_m1 <= 1; end
            2'd2: begin tag_m2 <= tag_in; val_m2 <= 1; end
            2'd3: begin tag_m3 <= tag_in; val_m3 <= 1; end
        endcase
    end
end

assign tag_out   = (line==0) ? tag_m0 : (line==1) ? tag_m1 : (line==2) ? tag_m2 : tag_m3;
assign valid_out = (line==0) ? val_m0 : (line==1) ? val_m1 : (line==2) ? val_m2 : val_m3;

endmodule
