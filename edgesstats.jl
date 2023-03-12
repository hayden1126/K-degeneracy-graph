include("EdgeUtils.jl")
using ProgressBars, .ReadUtils, .LinksUtils, .StatUtils

function main()
    (wglinks, degrees) = get_degreeslinks(EDGESFILE)
    fwdCounts, fwdCountIDs = [degree[2] for degree in degrees], [degree[1] for degree in degrees]

    logHistogram(fwdCounts, 1000, "output/outdegree.png", "Distribution of Outdegree")
    logHistogramScaled(fwdCounts, 1000, "output/scaled_outdegree.png", "Distribution of Outdegree")
    analyse(fwdCounts, "Outdegrees")

    E = sum(fwdCounts)
    V = length(fwdCounts)
    density = sum(fwdCounts) / (V * (V - 1))
    print("Density of Wikipedia links: $(density)")
end

if abspath(PROGRAM_FILE) == @__FILE__
    if length(ARGS) != 1 || !isfile(ARGS[1])
        println("Usage: julia graphstats.jl <edgesfile>")
        exit(1)
    end
    EDGESFILE = ARGS[1]
    main()
end