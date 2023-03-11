include("EdgeUtils.jl")
using ProgressBars, .ReadUtils, .WriteUtils, .LinksUtils, .DegreeUtils

function get_node_rgb(degree::Int32, maxdegree::Int32, mindegree::Int32)::Vector{Float16}
    range = maxdegree - mindegree
    red = Float16((degree-mindegree)/range)
    green = Float16(0)
    blue = Float16((maxdegree-degree)/range)
    return Float16[red, green, blue]
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
            colors = get_node_rgb(node[2], maxdegree, mindegree)
            println(f, "$(node[1]) $(join(colors, ' '))")
        end
    end
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
        templinks = sort!(collect(wglinks), by=x->x[1])
        for (prime, primelinks) in ProgressBar(templinks)
            color1 = get_node_rgb(degrees[indices[prime]][2], maxdegree, mindegree)
            for subnode in sort(primelinks)
                if !haskey(wglinks, subnode)
                    color2 = (0, 0, 0)
                else
                    color2 = get_node_rgb(degrees[indices[subnode]][2], maxdegree, mindegree)
                end
                # color = (color1+color2)/2
                color = (color1 - color2) * 2
                println(f, "$(prime) $(subnode) $(join(color, ' '))")
            end
        end
    end
end

function main()
    (wglinks, degrees) = @time get_degreeslinks(EDGESFILE)
    # write_colorednodes(OUTPUTFILE, degrees)
    write_colorededges(OUTPUTFILE, wglinks, degrees)
end

if abspath(PROGRAM_FILE) == @__FILE__
    if length(ARGS) != 2 || !isfile(ARGS[1])
        println("Usage: julia nodes2colors.jl <edgesfile> <outputfile>")
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