#!/bin/bash
# Compila e simula a cache de mapeamento direto
set -e

iverilog -o sim.out \
    tb_cache.v \
    main.v \
    valid.v \
    mux.v \
    datacache.v \
    ram.v \
    && echo "Compilacao OK"

vvp sim.out && echo "Simulacao OK"

gtkwave tb_cache.vcd &
