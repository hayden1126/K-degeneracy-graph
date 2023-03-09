using ProgressBars

# Gets dictionary of links
function get_links(edgesfile::String)::Dict{Int32, Vector{Int32}}
    println("\nFetching links...")

    wglinks = Dict{Int32, Vector{Int32}}()
    filelines = countlines(edgesfile)

    prime = parse(Int32, split(readline(edgesfile))[1])
    wglinks[prime] = Vector{Int32}()

    # For each line in edges file
    print("Progress: [0.0%]\r")
    for (index, line) = enumerate(eachline(edgesfile))

        pair = split(line)
        tmpprime = parse(Int32, pair[1])

        if tmpprime == prime
            push!(wglinks[prime], parse(Int32, pair[2]))
        else
            wglinks[tmpprime] = Int32[parse(Int32, pair[2])]
            prime = tmpprime
        end

        if index % 1000000 == 0
            print("Progress: [$(round(index/filelines*100, digits=1))%]\r")
        end
    end

    println("Progress: [100%] !")    
    return wglinks
end

# Gets dictionary of inbound links
function get_inboundlinks(wglinks::Dict{Int32, Vector{Int32}})::Set{Pair{Int32}}
    println("\nScanning for inbound links...")

    inboundlinks = Set{Pair{Int32}}()

    for (prime, primelinks) in ProgressBar(wglinks)
        for subnode in primelinks
            if prime in wglinks[subnode]
                continue
            end
            push!(inboundlinks, Pair(prime, subnode))
        end
    end
    return inboundlinks
end

# Converts directed graph to undirected graph
function get_undirected(wglinks::Dict{Int32, Vector{Int32}}, inboundlinks::Set{Pair{Int32}})::Dict{Int32, Vector{Int32}}
    println("\nConverting to undirected graph...")

    undirectedlinks = Dict{Int32, Vector{Int32}}()

    for (prime, primelinks) in ProgressBar(wglinks)
        undirectedlinks[prime] = Int32[]
        for subnode in primelinks
            # If link is in inboundlinks, add to undirectedlinks
            if Pair(prime, subnode) in inboundlinks
                push!(undirectedlinks[prime], subnode)

            # If link is both sided, only add to undirectedlinks if prime < subnode
            elseif prime > subnode
                push!(undirectedlinks[prime], subnode)
            end
        end
    end
    return undirectedlinks
end

# Writes the adjacency list to a new file
function write_edges(outputfile::String, wglinks::Dict{Int32, Vector{Int32}})
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

function main()
    wglinks = get_links(EDGESFILE)
    inboundlinks = get_inboundlinks(wglinks)
    undirectedlinks = get_undirected(wglinks, inboundlinks)
    write_edges(OUTPUTFILE, undirectedlinks)
end

if length(ARGS) != 2 || !isfile(ARGS[1])
    println("Usage: julia edges2undirected.jl <edgesfile> <outputfile>")
    exit()
end
const EDGESFILE = ARGS[1]
const OUTPUTFILE = ARGS[2]
main()