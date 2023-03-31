include("EdgeUtils.jl")
using ProgressBars, .ReadUtils, .WriteUtils

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

function main()
    wglinks = read_links(EDGESFILE)
    inboundlinks = get_inboundlinks(wglinks)
    undirectedlinks = get_undirected(wglinks, inboundlinks)
    write_edges(OUTPUTFILE, undirectedlinks)
end

if abspath(PROGRAM_FILE) == @__FILE__
    if length(ARGS) != 2 || !isfile(ARGS[1])
        println("Usage: julia edges2undirected.jl <edgesfile> <outputfile>")
        exit()
    end
    const EDGESFILE = abspath(ARGS[1])
    const OUTPUTFILE = abspath(ARGS[2])
    main()
end