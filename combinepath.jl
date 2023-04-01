# include("$(@__DIR__)/scripts/EdgeUtils.jl")
include("shortestpath.jl")
# using .ReadUtils, .WriteUtils, .TitleUtils

# Get all nodes 1 distance away from each node in the path and combine them into a single graph
function combine_edges(path::Vector{Int32}, wglinks::Dict{Int32, Vector{Int32}})
    nodes = Set(path)
    for node in path
        union!(nodes, wglinks[node])
    end

    graph = Dict{Int32, Vector{Int32}}()
    for node in path
        graph[node] = wglinks[node]
        for subnode in wglinks[node]
            if haskey(graph, subnode)
                continue
            end
            graph[subnode] = Int32[]
            for subsubnode in wglinks[subnode]
                if subsubnode in nodes
                    push!(graph[subnode], subsubnode)
                end
            end
        end
    end
    return graph
end

# Write labels in the format required by LGL
function write_labels(filename::String, path::Vector{Int32}, titles::Dict{Int32, String}, graph::Dict{Int32, Vector{Int32}})
    open(filename, "w") do f
        for node in path
            line = "$node,circle,2,1,000000,000000,5,5,20,$(rand()*360),000000,/home/hayden1126/LGL/PT_Mono/PTMono-Regular.ttf,5,FFFFFF,000000,/home/hayden1126/LGL/PT_Mono/PTMono-Regular.ttf,5,FFFFFF,000000,$(titles[node]),Deg $(length(graph[node]))"
            println(f, line)
        end
    end
end

function main()
    ROOTNODE = ARGS[3]
    GOAL = ARGS[4]
    wglinks = @time read_links(EDGESFILE)
    titles = @time read_titles(TITLESFILE)
    ids = Dict{String, Int32}()
    for (id, title) in titles
        ids[title] = id
    end
    while !haskey(ids, ROOTNODE)
        print("-Invalid root node: $ROOTNODE- \nInput start node: ")
        ROOTNODE = readline()
    end
    while !haskey(ids, GOAL)
        print("-Invalid goal node: $GOAL- \nInput goal: ")
        GOAL = readline()
    end
    path = @time get_shortestpath(wglinks, ids[ROOTNODE], ids[GOAL])
    for node in path
        println(titles[node])
    end
    graph = @time combine_edges(path, wglinks)
    mkpath(DIRPATH)
    write_edges("$DIRPATH/$FILEPREFIX.txt", graph)
    write_labels("$DIRPATH/$FILEPREFIX.labels", path, titles, graph)
end

if abspath(PROGRAM_FILE) == @__FILE__
    if length(ARGS) != 5 || !isfile(ARGS[1]) || !isfile(ARGS[2])
        println("Usage: julia combinepath.jl <edgesfile> <titlesfile> <startnode> <goal> <outputfileprefix>")
        exit(1)
    end
    const EDGESFILE = abspath(ARGS[1])
    const TITLESFILE = abspath(ARGS[2])
    const FILEPREFIX = ARGS[5]
    const DIRPATH = "$(@__DIR__)/visualisation/$FILEPREFIX"
    main()
end