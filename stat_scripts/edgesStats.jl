include("$(dirname(@__DIR__))/scripts/EdgeUtils.jl")
using ProgressBars, .ReadUtils, .StatUtils

# Plots graph of frequency of nodes against number of outbound links (outdegrees), image outputted in the stats directory
function main()
    degrees = read_degrees(EDGESFILE)
    fwdCounts = [degree[2] for degree in degrees]

    logHistogram(fwdCounts, 1000, "$STATSDIRPATH/$OUTPUTFILEPREFIX.png", "Distribution of Outdegrees")
    logHistogramScaled(fwdCounts, 1000, "$STATSDIRPATH/scaled_$OUTPUTFILEPREFIX.png", "Distribution of Outdegrees")
    analyse(fwdCounts, "Outdegrees")

    E = sum(fwdCounts)
    V = length(fwdCounts)
    density = sum(fwdCounts) / (V * (V - 1))
    print("Density of Wikipedia links: $(density)")
end

if abspath(PROGRAM_FILE) == @__FILE__
    if length(ARGS) != 2 || !isfile(ARGS[1])
        println("Usage: julia edgesStats.jl <edgesfile> <imagefileprefix>")
        exit(1)
    end
    const EDGESFILE = abspath(ARGS[1])
    const OUTPUTFILEPREFIX = ARGS[2]
    const STATSDIRPATH = abspath("$(dirname(@__DIR__))/stats")
    main()
end