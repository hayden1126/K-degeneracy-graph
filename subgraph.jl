include("EdgeUtils.jl")
using ArgParse, ProgressBars, .ReadUtils, .WriteUtils, .LinksUtils

# Recursive: gets sublinks of ndoes and updates sublinks, limitation: doesn't work for noOutbound links
function get_sublinks!(sublinks::Dict{Int32, Vector{Int32}}, wglinks::Dict{Int32, Vector{Int32}}, nodes::Vector{Int32}, level::Int64)
    if level == 0
        # for nodes in last level, if their links is in sublinks, add to sublinks, think here, separate function?
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
        union!(sublinks[node], wglinks[node])
        get_sublinks!(sublinks, wglinks, wglinks[node], level-1)
    end
end

function main()
        # Read in edges file
        (wglinks, degrees) = @time get_degreeslinks(EDGES_FILE)
        # Inbound links are ignored so no function is needed to get them
        if !haskey(wglinks, ROOTNODE)
            println("Error: Root node not found in edges file.")
            exit(1)
        end
        sublinks = Dict{Int32, Vector{Int32}}()
        println("Fetching sublinks...")
        @time get_sublinks!(sublinks, wglinks, Int32[ROOTNODE], LEVELS)
        
        # Write out new edges file
        @time write_edges(OUTPUT_FILE, sublinks)
end

function parse_commandline()
    s = ArgParseSettings()
    @add_arg_table s begin
        "--levels"
            help = "level of the edges around rootnode"
            default = '3'
        "edgesfile"
            help = "the edgesfile to fetch links from"
            required = true
        "rootnode"
            help = "the id of the rootnode"
            required = true
        "outputfile"
            help = "the file to write the output to"
            required = true
    end

    return parse_args(s)
end

if abspath(PROGRAM_FILE) == @__FILE__
    FILEARGS = parse_commandline()
    if !isfile(FILEARGS["edgesfile"])
        println("Error: Edgesfile \'$(FILEARGS["edgesfile"])\' not found.")
        exit(1)
    elseif !all(isnumeric, FILEARGS["rootnode"])
        println("Error: Rootnode \'$(FILEARGS["rootnode"])\' should be an integer.")
        exit(1)
    end
    const EDGES_FILE = FILEARGS["edgesfile"]
    const ROOTNODE = parse(Int32, FILEARGS["rootnode"])
    const OUTPUT_FILE = FILEARGS["outputfile"]
    const LEVELS = parse(Int64, FILEARGS["levels"])

    main()
end


# # BFS algorithm for nodes in a graph
# function bfs(wglinks::Dict{Int32, Vector{Int32}}, start::Int32)::Vector{Int32}
#     visited = Set{Int32}()
#     queue = Vector{Int32}()
#     push!(queue, start)
#     while !isempty(queue)
#         node = popfirst!(queue)
#         if node in visited
#             continue
#         end
#         push!(visited, node)
#         for neighbor in wglinks[node]
#             push!(queue, neighbor)
#         end
#     end
#     return collect(visited)
# end