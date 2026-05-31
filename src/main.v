// main.v
module cache_read_only(
  clk, reset,
  led_hit,                  // LED0: pisca no HIT
  led_unused1, led_unused2, // LED1 LED2: apagados
  led_mid,                  // LED3: ancora cache
  led_miss,                 // LED4: pisca no MISS
  led_unused5               // LED5: apagado
);
parameter cacheSize     = 8;
parameter ramSize       = 32;
parameter blockSize     = 2;
parameter cacheLines    = 4;
parameter cacheLineBits = 2;
parameter ramBits       = 5;
parameter blockBits     = 1;
parameter tagBits       = 2;

input  clk, reset;
output led_hit;
output led_unused1, led_unused2;
output led_mid;
output led_miss;
output led_unused5;

// slow_rise: pulso de 1 ciclo a cada 1s
reg [26:0] slow_cnt;
wire slow_rise = (slow_cnt == 27'd27_000_000);
always @(posedge clk or negedge reset) begin
  if (!reset) slow_cnt <= 0;
  else        slow_cnt <= slow_rise ? 27'd0 : slow_cnt + 27'd1;
end

// Sequencia de enderecos — avanca so quando o acesso atual terminou (Done)
reg [2:0] seq_idx;
reg [ramBits-1:0] address;
always @(posedge clk or negedge reset) begin
  if (!reset) begin seq_idx <= 0; address <= 5'd22; end
  else if (Done & slow_rise) begin
    seq_idx <= (seq_idx == 3'd7) ? 3'd0 : seq_idx + 3'd1;
    case (seq_idx)
      0: address <= 5'd22;
      1: address <= 5'd26;
      2: address <= 5'd22;
      3: address <= 5'd26;
      4: address <= 5'd16;
      5: address <= 5'd3;
      6: address <= 5'd16;
      7: address <= 5'd18;
    endcase
  end
end

wire [cacheLineBits-1:0] line;
wire [blockBits-1:0]     blk;
wire [tagBits-1:0]       tag;

assign tag  = address[ramBits-1 : blockBits+cacheLineBits];
assign line = address[blockBits+cacheLineBits-1 : blockBits];
assign blk  = address[blockBits-1 : 0];

// --- FSM com enable ---
wire Twr, Dwr, Rwr, END, Cnt, c, v, MuxSel, Done, Miss;
wire [2:0]           state_log;
wire [7:0]           Ram2Cache;
wire [blockBits-1:0] Mux1, Muxout;
wire [tagBits-1:0]   Tout;
wire [7:0]           Cache2out;

// FSM: roda no clk principal, avanca so no slow_rise
reg [2:0] state;
parameter ReadTag   = 3'b000,
          ReadData  = 3'b001,
          ReadBlk   = 3'b010,
          UpdateTag = 3'b011,
          RESET_ST  = 3'b100;

reg [2:0] state_log_r;
assign state_log = state_log_r;

always @(posedge clk or negedge reset) begin
  if (!reset) begin
    state       <= RESET_ST;
    state_log_r <= 3'b100;
  end else if (slow_rise) begin
    case (state)
      RESET_ST: begin state <= ReadTag;  state_log_r <= 3'b000; end
      ReadTag:  begin
        if (c && v) begin state <= ReadData;  state_log_r <= 3'b001; end
        else        begin state <= ReadBlk;   state_log_r <= 3'b010; end
      end
      ReadData: begin state <= ReadTag;  state_log_r <= 3'b000; end
      ReadBlk:  begin
        if (END) begin state <= UpdateTag; state_log_r <= 3'b011; end
        else     begin state <= ReadBlk;   state_log_r <= 3'b010; end
      end
      UpdateTag: begin state <= ReadTag; state_log_r <= 3'b000; end
    endcase
  end
end

// Saidas combinacionais da FSM
assign Cnt  = (state == ReadTag);
assign Twr  = (state == UpdateTag);
assign Dwr  = (state == ReadBlk);
assign Rwr  = 1'b0;
assign MuxSel = (state == ReadBlk);
assign Done = (state == ReadData);
assign Miss = (state == ReadTag) & ~(c & v);

// Valid memory com enable
valid #(cacheLineBits, cacheLines)
  V(.clk(clk), .line(line), .reset(!reset), .wr(Twr & slow_rise), .dout(v));

// Mtag inline com enable
reg [tagBits-1:0] tag_mem0, tag_mem1, tag_mem2, tag_mem3;
always @(posedge clk or negedge reset) begin
  if (!reset) begin
    tag_mem0<=0; tag_mem1<=0; tag_mem2<=0; tag_mem3<=0;
  end
  else if (Twr & slow_rise) case (line)
    2'd0: tag_mem0 <= tag;
    2'd1: tag_mem1 <= tag;
    2'd2: tag_mem2 <= tag;
    2'd3: tag_mem3 <= tag;
  endcase
end
assign Tout = (line==0) ? tag_mem0 : (line==1) ? tag_mem1 :
              (line==2) ? tag_mem2 : tag_mem3;
assign c = (tag == Tout);

datacache #(blockBits, cacheLineBits, cacheSize)
  dcache(.clk(clk), .line(line), .blk(Muxout), .din(Ram2Cache), .wr(Dwr & slow_rise), .dout(Cache2out));

ram #(ramBits, ramSize)
  R(.clk(clk), .addr({tag, line, Mux1}), .din(8'd0), .wr(Rwr), .dout(Ram2Cache), .reset(!reset));

mux #(blockBits)
  DataMux(.din_0(blk), .din_1(Mux1), .sel(MuxSel), .mux_out(Muxout));

// Counter com enable
reg [blockBits-1:0] cnt_out;
reg cnt_end;
always @(posedge clk or negedge reset) begin
  if (!reset) begin cnt_out <= 0; cnt_end <= 0; end
  else if (slow_rise) begin
    if (Cnt) begin cnt_out <= 0; cnt_end <= 0; end
    else begin
      cnt_out <= cnt_out + 1'b1;
      cnt_end <= (cnt_out == (blockSize - 2));
    end
  end
end
assign Mux1 = cnt_out;
assign END  = cnt_end;

// Timers de hit e miss: seguram o LED aceso por 2 ciclos de slow_rise (~2s)
reg [1:0] timer_hit, timer_miss;
always @(posedge clk or negedge reset) begin
  if (!reset) begin timer_hit <= 0; timer_miss <= 0; end
  else begin
    if (Done & slow_rise)       timer_hit  <= 2'd3;
    else if (slow_rise & |timer_hit)  timer_hit  <= timer_hit  - 1'b1;
    if (Miss & slow_rise)       timer_miss <= 2'd3;
    else if (slow_rise & |timer_miss) timer_miss <= timer_miss - 1'b1;
  end
end

// Tang Nano: LEDs ativos em baixo (0 = aceso, 1 = apagado)
assign led_hit      = ~|timer_hit;
assign led_unused1  = 1'b1;
assign led_unused2  = 1'b1;
assign led_mid      = 1'b1;
assign led_miss     = ~|timer_miss;
assign led_unused5  = |Cache2out;  // ancora: impede sweep; quase sempre 1 (apagado)

endmodule
