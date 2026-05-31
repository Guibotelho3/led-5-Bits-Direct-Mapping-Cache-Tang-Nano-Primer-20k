`timescale 1ns/1ps

// Testbench para cache_read_only
// Usa $force no slow_cnt para acelerar a simulacao sem modificar main.v
module tb_cache;

    reg clk, reset;

    wire led_hit, led_miss, led_mid;
    wire led_unused1, led_unused2, led_unused5;

    cache_read_only #(
        .cacheSize(16), .ramSize(32), .blockSize(2),
        .cacheLines(8), .cacheLineBits(3), .ramBits(5),
        .blockBits(1),  .tagBits(1)
    ) dut (
        .clk(clk), .reset(reset),
        .led_hit(led_hit),
        .led_unused1(led_unused1), .led_unused2(led_unused2),
        .led_mid(led_mid),
        .led_miss(led_miss),
        .led_unused5(led_unused5)
    );

    // Clock 10ns (100 MHz) - rapido para simulacao
    always #5 clk = ~clk;

    // Sinais internos para observacao
    wire [4:0] address   = dut.address;
    wire [0:0] tag       = dut.tag;
    wire [2:0] line      = dut.line;
    wire [2:0] state     = dut.state;
    wire       hit       = dut.Done;
    wire       miss      = dut.Miss;
    wire [7:0] cache_out = dut.Cache2out;
    wire [7:0] ram_out   = dut.Ram2Cache;
    wire       valid_bit = dut.v;
    wire       tag_match = dut.c;

    // Dump VCD - apenas o nivel do tb para nao poluir com internos de submodulos
    initial begin
        $dumpfile("tb_cache.vcd");
        $dumpvars(1, tb_cache);          // nivel 1: sinais do tb (inclui os wires acima)
        $dumpvars(1, tb_cache.dut);      // nivel 1 do DUT: state, address, etc.
    end

    // Tarefa: dispara um slow_rise forcando slow_cnt ao valor maximo
    task tick;
        begin
            // Forca slow_cnt para 27_000_000 -> slow_rise vai a 1 no proximo clk
            force dut.slow_cnt = 27'd27_000_000;
            @(posedge clk);
            release dut.slow_cnt;
            @(posedge clk); // deixa a FSM e os registradores atualizarem
        end
    endtask

    // Sequencia de enderecos esperada (do main.v):
    // idx: 0->22, 1->26, 2->22, 3->26, 4->16, 5->3, 6->16, 7->18
    // Analise de hit/miss (cache fria no inicio):
    //   addr=22: tag=1 line=3 -> MISS (fria)
    //   addr=26: tag=1 line=5 -> MISS (fria)
    //   addr=22: tag=1 line=3 -> HIT
    //   addr=26: tag=1 line=5 -> HIT
    //   addr=16: tag=1 line=0 -> MISS (fria)
    //   addr=3:  tag=0 line=1 -> MISS (fria)
    //   addr=16: tag=1 line=0 -> HIT
    //   addr=18: tag=1 line=1 -> MISS (conflito: line=1 tinha tag=0, agora tag=1)

    integer i;
    initial begin
        clk   = 0;
        reset = 0;
        repeat(4) @(posedge clk);
        reset = 1;
        repeat(2) @(posedge clk);

        $display("\n=== Cache Mapeamento Direto - Simulacao ===");
        $display("%-5s %-6s %-7s  led_hit led_miss  Resultado",
                 "Tick", "Addr", "State");

        tick;

        for (i = 0; i < 24; i = i + 1) begin
            $display("%-5d %-6d %-7s    %b       %b       %s",
                     i, address,
                     (state==3'b000 ? "RdTag" :
                      state==3'b001 ? "RdData":
                      state==3'b010 ? "RdBlk" :
                      state==3'b011 ? "UpdTag": "RESET"),
                     ~led_hit, ~led_miss,
                     (hit  ? "<<< HIT"  :
                      miss ? "<<< MISS" : ""));
            tick;
        end

        $display("\n=== Fim da simulacao ===\n");
        $finish;
    end

endmodule
