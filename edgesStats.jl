include("EdgeUtils.jl")
using ProgressBars, .ReadUtils, .LinksUtils, .StatUtils

# Plots graph of frequency of nodes against number of outbound links (outdegrees), image outputted in the stats directory
function main()
    (wglinks, degrees) = read_degreeslinks(EDGESFILE)
    fwdCounts, fwdCountIDs = [degree[2] for degree in degrees], [degree[1] for degree in degrees]

    logHistogram(fwdCounts, 1000, "stats/$OUTPUTFILE", "Distribution of Outdegrees")
    logHistogramScaled(fwdCounts, 1000, "stats/scaled_$OUTPUTFILE", "Distribution of Outdegrees")
    analyse(fwdCounts, "Outdegrees")

    E = sum(fwdCounts)
    V = length(fwdCounts)
    density = sum(fwdCounts) / (V * (V - 1))
    print("Density of Wikipedia links: $(density)")
end

if abspath(PROGRAM_FILE) == @__FILE__
    if length(ARGS) != 2 || !isfile(ARGS[1])
        println(ARGS[1])
        println(isfile(ARGS[1]))
        println("Usage: julia edgesStats.jl <edgesfile> <imageprefix.png>")
        exit(1)
    end
    const EDGESFILE = ARGS[1]
    const OUTPUTFILE = ARGS[2]
    main()
end