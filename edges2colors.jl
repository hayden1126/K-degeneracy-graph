include("EdgeUtils.jl")
using ProgressBars, .ReadUtils, .WriteUtils, .LinksUtils, .DegreeUtils

function get_edge_rgb(degree1::Int32, degree2::Int32, maxdegree::Int32, mindegree::Int32)::Vector{Float16}
    range = maxdegree - mindegree
    absdiff = abs(degree1-degree2)
    red = Float16(absdiff/range)
    green = Float16(0)
    blue = Float16(1-(absdiff/range))
    return Float16[red, green, blue]
end

function write_colorededges(outputfile::String, wglinks::Dict{Int32, Vector{Int32}}, degrees::Vector{Vector{Int32}})
    if isempty(wglinks)
        println("\nWriting colored edges... No nodes to write, skipping...")
        return
    end
    println("\nWriting colored edges...")
    maxdegree = get_maxdegree(degrees)[2]
    mindegree = get_mindegree(degrees)[2]
    indices = get_indices(degrees)
    open(outputfile, "w") do f
        for (prime, primelinks) in ProgressBar(wglinks)
            for subnode in primelinks
                if !haskey(wglinks, subnode)
                    color = get_edge_rgb(degrees[indices[prime]][2], mindegree, maxdegree, mindegree)
                else
                    color = get_edge_rgb(degrees[indices[prime]][2], degrees[indices[subnode]][2], maxdegree, mindegree)
                end
                println(f, "$(prime) $(subnode) $(join(color, ' '))")
            end
        end
    end
end

function main()
    (wglinks, degrees) = @time read_degreeslinks(EDGESFILE)
    write_colorededges(OUTPUTFILE, wglinks, degrees)
end

if abspath(PROGRAM_FILE) == @__FILE__
    if length(ARGS) != 2 || !isfile(ARGS[1])
        println("Usage: julia edges2colors.jl <edgesfile> <outputfile>")
        exit(1)
    end
    EDGESFILE = ARGS[1]
    OUTPUTFILE = ARGS[2]
    main()
end
