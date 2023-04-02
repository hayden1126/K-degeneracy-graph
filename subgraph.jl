include("$(@__DIR__)/scripts/EdgeUtils.jl")
using ProgressBars, .ReadUtils, .WriteUtils

# Recursive: gets sublinks of nodes and updates sublinks, limitation: doesn't work for noOutbound links
function get_sublinks!(sublinks::Dict{Int32, Vector{Int32}}, wglinks::Dict{Int32, Vector{Int32}}, nodes::Vector{Int32}, level::Int64)
    if level == 0
        for node in nodes

            if !haskey(sublinks, node)
                sublinks[node] = Int32[]
            end
            if !haskey(wglinks, node)
                continue
            end

            for subnode in wglinks[node]
                if haskey(sublinks, subnode) && !in(subnode, sublinks[node])
                    push!(sublinks[node], subnode)
                end
            end
        end
        return
    end
    for node in nodes
        if !haskey(sublinks, node)
            sublinks[node] = Int32[]
        end
        if !haskey(wglinks, node)
            continue
        end
        union!(sublinks[node], wglinks[node])
        get_sublinks!(sublinks, wglinks, wglinks[node], level-1)
    end
end

# Gets edges file of subgraph of all nodes with distance <= LEVELS from ROOTNODE
function main()
        wglinks = @time read_links(EDGES_FILE)
        # Inbound links are ignored so no function is needed to get them
        if !haskey(wglinks, ROOTNODE)
            println("Error: Root node not found in edges file.")
            exit(1)
        end
        sublinks = Dict{Int32, Vector{Int32}}()
        println("Fetching sublinks...")
        @time get_sublinks!(sublinks, wglinks, Int32[ROOTNODE], LEVELS)
        println("No. of nodes: $(length(sublinks))")
        @time write_edges(OUTPUT_FILE, sublinks)
end

if abspath(PROGRAM_FILE) == @__FILE__
    if length(ARGS) != 4
        println("Usage: julia subgraph.jl <edgesfile> <rootnode> <levels> <outputfile>")
        exit(1)
    elseif !isfile(ARGS[1])
        println("Error: Edgesfile \'$(ARGS[1])\' not found.")
        exit(1)
    elseif !all(isnumeric, ARGS[2])
        println("Error: Rootnode \'$(ARGS[2])\' should be an integer.")
        exit(1)
    end
    const EDGES_FILE = ARGS[1]
    const ROOTNODE = parse(Int32, ARGS[2])
    const LEVELS = parse(Int64, ARGS[3])
    const OUTPUT_FILE = ARGS[4]
    main()
end