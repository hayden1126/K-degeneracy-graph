using ProgressBars

# Gets array of degrees and dictionary of links
function fetch_links(edgesfile::String)::Tuple{Vector{Vector{Int32}}, Dict{Int32, Vector{Int32}}}
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
function degenerate(degrees::Vector{Vector{Int32}}, wglinks::Dict{Int32, Vector{Int32}}, inboundlinks::Dict{Int32, Vector{Int32}})::Vector{Int32}
    println("\nDegenerating graph...")

    # keep = Int32[]
    remove = Int32[]
    sorteddegrees = sort(degrees, by=x->x[2])
    indices = get_indices(sorteddegrees)
    for node in ProgressBar(sorteddegrees)
        if node[2] < K
            push!(remove, node[1])
            for subnode in wglinks[node[1]]
                if haskey(wglinks, subnode) && node[1] in wglinks[subnode]
                    sorteddegrees[indices[subnode]][2] -= 1
                end
            end
            if haskey(inboundlinks, node[1])
                for prime in inboundlinks[node[1]]
                    sorteddegrees[indices[prime]][2] -= 1
                end
            end
        # else
        #     push!(keep, node[1])
        end
    end
    # println(remove, keep)

    # # Checking for errors of remove links' degrees
    # tmpcount = count(x->x[2] < 0, sorteddegrees)
    # if tmpcount < 0
    #     println("Error: Number of degree < 0 nodes: $tmpcount")
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
function write_edges(wglinks::Dict{Int32, Vector{Int32}}, outputfile::String)
    println("\nWriting edges...")
    open(outputfile, "w") do f
        for (prime, primelinks) in ProgressBar(wglinks)
            for subnode in primelinks
                println(f, "$(prime) $(subnode)")
            end
        end
    end
end

# Iterates entire process once
function oneiteration(edgesfile::String, outputfile::String)::Bool
    (degrees, wglinks) = @time fetch_links(edgesfile)
    (inboundlinks, noOutboundlinks, noOutboundcount) = @time get_inboundlinks(wglinks)
    ogcount = length(wglinks)
    @time remove_noOutbound!(noOutboundlinks, wglinks, degrees, noOutboundcount)
    remove = @time degenerate(degrees, wglinks, inboundlinks)

    if length(remove) == 0 && noOutboundcount == 0 
        println("\nNo. of Nodes in $K-core graph: $(length(wglinks))")
        return true 
    end

    @time remove_links!(remove, wglinks, inboundlinks)
    removecount = length(remove)
    println("Nodes Removed: $removecount out of $ogcount -> $(round(100*removecount/ogcount, digits=1))%")
    # try to see how remove count differs

    @time write_edges(wglinks, outputfile)
    println("Nodes left: $(length(wglinks))")

    return false
end 

function main()
    iterations = 1
    edgesfile = EDGESFILE
    outputfile = "$(@__DIR__)/logs/$K_core_itr_$iterations.txt"

    println("Iteration: $iterations")
    while !oneiteration(edgesfile, outputfile)
        edgesfile = outputfile
        iterations += 1
        outputfile = "$(@__DIR__)/logs/$K_core_itr_$iterations.txt"
        println("\n\nIteration: $iterations")
    end
    println("No more nodes to remove. Finished in $iterations iteration(s).")
end

if length(ARGS) != 2 || !isfile(ARGS[1]) || !all(isnumeric, ARGS[2])
    println("Usage: julia mapReduce.jl <edgesfile> <K>")
    exit(1)
end
const EDGESFILE = ARGS[1]
const K = parse(Int32, ARGS[2])

main()

