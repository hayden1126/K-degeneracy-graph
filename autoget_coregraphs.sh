for K in {89..126}; do
    OUTFILE=k_edges/${K}_core_edges.txt
    EDGESFILE=k_edges/88_core_edges.txt
    if test -f $OUTFILE; then
        EDGESFILE=k_edges/${K}_core_edges.txt
        echo "File $OUTFILE exists. Skipping."
        continue
    fi
    julia mapReduce.jl $EDGESFILE $K $OUTFILE > logs/${K}_core_edges.log
done