#!/bin/zsh

a=40
b=120
for K in {$a..$b..10}; do
    echo "K = $K"
    OUTFILE=../logs/stats.log
    EDGESFILE=../k_edges/${K}_core_edges.txt

    julia edgesStats.jl $EDGESFILE ${K}core >> $OUTFILE
done