using ProgressBars

# Gets array of degrees and dictionary of links
function get_links(edgesfile::String)::Tuple{Vector{Vector{Int32}}, Dict{Int32, Vector{Int32}}}
    println("\nFetching links and degrees...")

    degrees = Vector{Vector{Int32}}()
    wglinks = Dict{Int32, Vector{Int32}}()
    filelines = countlines(edgesfile)

    prime = parse(Int32, split(readline(edgesfile))[1])
    wglinks[prime] = Vector{Int32}()
    degree::Int32 = 0

    # For each line in edges file
    print("Progress: [0.0%]\r")
    for (index, line) = enumerate(eachline(edgesfile))

        pair = split(line)
        tmpprime = parse(Int32, pair[1])

        # If it is the same prime node, add 1 to degree
        if tmpprime == prime
            push!(wglinks[prime], parse(Int32, pair[2]))
            degree += 1
        # If it is a new prime node, update the degree of the old prime node, then update temp variables to new prime node
        else
            wglinks[tmpprime] = Int32[parse(Int32, pair[2])]
            push!(degrees, [prime, degree])

            # Update to new prime node
            degree = 1
            prime = tmpprime
        end

        # Print progress
        if index % 1000000 == 0
            print("Progress: [$(round(index/filelines*100, digits=1))%]\r")
        end
    end

    # Process the last prime node
    push!(degrees, [prime, degree])
    println("Progress: [100%] !")    
    return (degrees, wglinks)
end

# Gets dictionary of inbound links and set of nodes with no outbound links
function get_inboundlinks(wglinks::Dict{Int32, Vector{Int32}})::Tuple{Dict{Int32, Vector{Int32}}, Set{Pair{Int32}}, Int32}
    println("\nScanning for inbound links...")
    inboundlinks = Dict{Int32, Vector{Int32}}()
    noOutboundlinks = Set{Pair{Int32}}()
    noOutbound = Set{Int32}()

    # For every subnode
    for (prime, primelinks) in ProgressBar(wglinks)
        for subnode in primelinks
            # If subnode has no outbound links, add to noOutbound
            if !haskey(wglinks, subnode)
                push!(noOutboundlinks, Pair(prime, subnode))
                push!(noOutbound, subnode)

            # If subnode has outbound links, but not to prime, add to inboundlinks
            elseif !(prime in wglinks[subnode])
                if !haskey(inboundlinks, subnode)
                    inboundlinks[subnode] = Int32[prime]
                else
                    push!(inboundlinks[subnode], prime)
                end
            end
        end
    end
    return (inboundlinks, noOutboundlinks, length(noOutbound))
end

# Gets the dictionary of indices of a node in the degrees array
function get_indices(degrees::Vector{Vector{Int32}})::Dict{Int32, Int32}
    indices = Dict{Int32, Int32}()
    for (index, node) in enumerate(degrees)
        indices[node[1]] = index
    end
    return indices
end

# Removes nodes with no outbound links
function remove_noOutbound!(noOutboundlinks::Set{Pair{Int32}}, wglinks::Dict{Int32, Vector{Int32}}, degrees::Vector{Vector{Int32}}, noOutboundcount::Int32)
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

# Removes links from the adjacency list based on the array of nodes to remove
function remove_links!(remove::Vector{Int32}, wglinks::Dict{Int32, Vector{Int32}}, inboundlinks::Dict{Int32, Vector{Int32}})
    println("\nRemoving links...")
    for node in ProgressBar(remove)
        
        # Remove links
        for subnode in wglinks[node]
            if haskey(wglinks, subnode) && node in wglinks[subnode]
                deleteat!(wglinks[subnode], findfirst(==(node), wglinks[subnode]))
            end
        end

        # Remove links from inbound links
        if haskey(inboundlinks, node)
            for prime in inboundlinks[node]
                if haskey(wglinks, prime)
                    deleteat!(wglinks[prime], findfirst(==(node), wglinks[prime])) # key 1968215 not found
                end
            end
            delete!(inboundlinks, node)
        end
        
        # Remove links from node
        delete!(wglinks, node)
    end
end

# Writes the adjacency list to a new file
function write_edges(outputfile::String, wglinks::Dict{Int32, Vector{Int32}})
    if isempty(wglinks)
        println("Writing edges... No nodes left, skipping...")
        return
    end
    println("\nWriting edges...")
    open(outputfile, "w") do f
        templinks = sort!(collect(wglinks), by=x->x[1])
        for (prime, primelinks) in ProgressBar(templinks)
            for subnode in sort(primelinks)
                println(f, "$(prime) $(subnode)")
            end
        end
    end
end

# Gets the degrees of all nodes
function get_degrees(wglinks::Dict{Int32, Vector{Int32}})
    degrees = Vector{Vector{Int32}}()
    for (prime, primelinks) in wglinks
        push!(degrees, [prime, length(primelinks)])
    end
    return degrees
end

# Iterates entire process once
function oneiteration!(degrees::Vector{Vector{Int32}}, wglinks::Dict{Int32, Vector{Int32}})::Bool
    
    (inboundlinks, noOutboundlinks, noOutboundcount) = @time get_inboundlinks(wglinks)
    ogcount = length(wglinks)
    if noOutboundcount == 0
        println("\nNo nodes with no outbound links to remove.")
    else
        @time remove_noOutbound!(noOutboundlinks, wglinks, degrees, noOutboundcount)
    end
    remove = @time degenerate!(degrees, wglinks, inboundlinks)

    if length(remove) == 0 && noOutboundcount == 0 
        println("\nNo. of Nodes in $K-core graph: $(length(wglinks))")
        return true 
    end

    @time remove_links!(remove, wglinks, inboundlinks)
    removecount = length(remove)
    println("Nodes Removed: $removecount out of $ogcount -> $(round(100*removecount/ogcount, digits=1))%")
    println("Nodes left: $(length(wglinks))")

    if isempty(wglinks)
        return true
    end

    return false
end 

function main()
    (degrees, wglinks) = @time get_links(EDGESFILE)
    
    iterations = 1
    println("\n\nIteration: $iterations")
    while !oneiteration!(degrees, wglinks)
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