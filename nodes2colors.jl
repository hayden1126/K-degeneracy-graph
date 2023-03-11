include("EdgeUtils.jl")
using ProgressBars, .ReadUtils, .WriteUtils, .LinksUtils, .DegreeUtils

function get_rgb(degree::Int32, maxdegree::Int32, mindegree::Int32)::Tuple{Float16, Float16, Float16}
    range = maxdegree - mindegree
    red = Float16((degree-mindegree)/range)
    blue = Float16((maxdegree-degree)/range)
    green = Float16(0)
    return (red, blue, green)
end

function write_colorednodes(outputfile::String, degrees::Vector{Vector{Int32}})
    if isempty(degrees)
        println("\nWriting colored nodes... No nodes to write, skipping...")
        return
    end

    println("\nWriting colored edges...")
    maxdegree = get_maxdegree(degrees)[2]
    mindegree = get_mindegree(degrees)[2]
    open(outputfile, "w") do f
        for node in ProgressBar(degrees)
            colors = get_rgb(node[2], maxdegree, mindegree)
            println(f, "$(node[1]) $(join(colors, ' '))")
        end
    end
end

function main()
    (wglinks, degrees) = @time get_degreeslinks(EDGESFILE)
    write_colorednodes(OUTPUTFILE, degrees)
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


"
coloring
difference in degrees of edges
+ve: blue
-ve: red
"