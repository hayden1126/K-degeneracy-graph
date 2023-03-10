include("EdgeUtils.jl")
using ProgressBars, .ReadUtils, .WriteUtils, .LinksUtils

# Removes nodes with no outbound links
function remove_noOutbound!(wglinks::Dict{Int32, Vector{Int32}}, noOutboundlinks::Set{Pair{Int32}}, degrees::Vector{Vector{Int32}}, noOutboundcount::Int32)
    println("\nRemoving $noOutboundcount nodes with no outbound links...")
    indices = get_indices(degrees)
    for (prime, subnode) in ProgressBar(noOutboundlinks)
        deleteat!(wglinks[prime], findfirst(x->x==subnode, wglinks[prime]))
        degrees[indices[prime]][2] -= 1
    end
end

# K-core decomposition: gets array of nodes to remove (or keep)
function degenerate!(degrees::Vector{Vector{Int32}}, wglinks::Dict{Int32, Vector{Int32}}, inboundlinks::Dict{Int32, Vector{Int32}})::Vector{Int32}
    println("\nDegenerating graph...")

    # keep = Int32[]
    remove = Int32[]
    sort!(degrees, by=x->x[2])
    indices = get_indices(degrees)
    for node in ProgressBar(degrees)
        if !haskey(wglinks, node[1])
            continue
        end
        if node[2] < K
            push!(remove, node[1])
            for subnode in wglinks[node[1]]
                if haskey(wglinks, subnode) && node[1] in wglinks[subnode]
                    degrees[indices[subnode]][2] -= 1
                end
            end
            if haskey(inboundlinks, node[1])
                for prime in inboundlinks[node[1]]
                    degrees[indices[prime]][2] -= 1
                end
            end
        # else
        #     push!(keep, node[1])
        end
    end
    # println(remove, keep)

    # # Checking for errors of remove links' degrees
    # tmpcount = count(x->x[2] < 0, degrees)
    # if tmpcount > 0
    #     println("Error: Number of degree < 0 nodes: $tmpcount")
    #     println("This may be due to duplicate pairs in the edges file.")
    # end
    return remove
end

# Iterates entire process once
function oneiteration!(wglinks::Dict{Int32, Vector{Int32}}, degrees::Vector{Vector{Int32}})::Bool
    (inboundlinks, noOutboundlinks, noOutboundcount) = @time get_directedlinks(wglinks)
    ogcount = length(wglinks)
    if noOutboundcount == 0
        println("\nNo nodes with no outbound links to remove.")
    else
        @time remove_noOutbound!(wglinks, noOutboundlinks, degrees, noOutboundcount)
    end
    remove = @time degenerate!(degrees, wglinks, inboundlinks)

    if length(remove) == 0 && noOutboundcount == 0 
        println("\nNo. of Nodes in $K-core graph: $(length(wglinks))")
        return true 
    end

    @time remove_links!(wglinks, remove, inboundlinks)
    removecount = length(remove)
    println("Nodes Removed: $removecount out of $ogcount -> $(round(100*removecount/ogcount, digits=1))%")
    println("Nodes left: $(length(wglinks))")

    return isempty(wglinks)
end 

function main()
    (wglinks, degrees) = @time get_degreeslinks(EDGESFILE)
    
    iterations = 1
    println("\n\nIteration: $iterations")
    while !oneiteration!(wglinks, degrees)
        iterations += 1
        println("\n\nIteration: $iterations")
        degrees = get_degrees(wglinks)

        # If you want to write the graph after each iteration,
        # (which may extend the script's runtime by a lot, but you can use resume mapReduce with those logs files),
        # Uncomment the following line:
        # @time write_edges("$(@__DIR__)/logs/$(K)_core_itr_$iterations.txt", wglinks)
    end
    println("No more nodes to remove. Finished in $iterations iteration(s).")
    @time write_edges(OUTPUTFILE, wglinks)
end

if abspath(PROGRAM_FILE) == @__FILE__
    if length(ARGS) < 2 || !isfile(ARGS[1]) || !all(isnumeric, ARGS[2])
        println("Usage: julia mapReduce.jl <edgesfile> <K> <optional: outputfile>")
        exit(1)
    end
    const EDGESFILE = ARGS[1]
    const K = parse(Int32, ARGS[2])
    if length(ARGS) == 3
        const OUTPUTFILE = ARGS[3]
    else
        const OUTPUTFILE = "$(@__DIR__)/k_edges/$(K)_core_edges.txt"
    end

    @time main()
end
