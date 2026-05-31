TESTBENCH PARA RODAR NO TERMINAL

cd "C:\Users\Guilherme\Desktop\Cache\map_direto(ledFSM+hitmiss)"
# No WSL/Linux:
iverilog -o sim.out tb_cache.v main.v valid.v mux.v datacache.v ram.v
vvp sim.out
gtkwave tb_cache.vcd