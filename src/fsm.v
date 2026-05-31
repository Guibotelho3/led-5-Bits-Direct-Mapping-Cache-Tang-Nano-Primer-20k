// fsm.v - Cache FSM (Finite State Machine)
// States: RESET -> ReadTag -> ReadData -> ReadTag
//                          -> ReadBlk  -> UpdateTag -> ReadTag
//
// state_log: registrador de 3 bits que reflete o estado atual
//   ReadTag   = 3'b000
//   ReadData  = 3'b001
//   ReadBlk   = 3'b010
//   UpdateTag = 3'b011
//   RESET     = 3'b100
module fsm(
  input  wire clk, reset, c, v, END,
  output reg  Twr, Dwr, Rwr, Cnt, Mux, Done, Miss,
  output reg  [2:0] state_log
);

reg [2:0] state;

parameter ReadTag   = 3'b000,
          ReadData  = 3'b001,
          ReadBlk   = 3'b010,
          UpdateTag = 3'b011,
          RESET     = 3'b100;

always @(posedge clk or negedge reset) begin
  if (!reset) begin
    state     <= RESET;
    state_log <= 3'b100;
  end else begin
    case (state)
      RESET: begin
        state <= ReadTag; state_log <= 3'b000;
      end
      ReadTag: begin
        if (c && v) begin state <= ReadData;  state_log <= 3'b001; end
        else        begin state <= ReadBlk;   state_log <= 3'b010; end
      end
      ReadData: begin
        state <= ReadTag; state_log <= 3'b000;
      end
      ReadBlk: begin
        if (END) begin state <= UpdateTag; state_log <= 3'b011; end
        else     begin state <= ReadBlk;   state_log <= 3'b010; end
      end
      UpdateTag: begin
        state <= ReadTag; state_log <= 3'b000;
      end
    endcase
  end
end

always @(*) begin
  Cnt  = (state == ReadTag);
  Twr  = (state == UpdateTag);
  Dwr  = (state == ReadBlk);
  Rwr  = 0;
  Mux  = (state == ReadBlk);
  Done = (state == ReadData);
  Miss = (state == ReadTag) & ~(c & v);
end

endmodule
