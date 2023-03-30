include("EdgeUtils.jl")
using ProgressBars, .ReadUtils, .LinksUtils, .StatUtils

function main()
    (wglinks, degrees) = read_degreeslinks(EDGESFILE)
    fwdCounts, fwdCountIDs = [degree[2] for degree in degrees], [degree[1] for degree in degrees]

    logHistogram(fwdCounts, 1000, "output/$OUTPUTFILE", "Distribution of Outdegrees")
    logHistogramScaled(fwdCounts, 1000, "output/scaled_$OUTPUTFILE", "Distribution of Outdegrees")
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
        println("Usage: julia edgesStats.jl <edgesfile> <output image .png>")
        exit(1)
    end
    const EDGESFILE = ARGS[1]
    const OUTPUTFILE = ARGS[2]
    main()
end