# include("EdgeUtils.jl")
include("bfs.jl")
# using .ReadUtils, .WriteUtils, .TitleUtils

# Get level 1 subgraph of each node in the path from bfs and combine them into a single graph
function combine_edges(path::Vector{Int32}, wglinks::Dict{Int32, Vector{Int32}}, titles::Dict{Int32, String})
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

function write_labels(filename::String, path::Vector{Int32}, titles::Dict{Int32, String}, graph::Dict{Int32, Vector{Int32}})
    open("$(dirname(filename))/combined.labels", "w") do f
        for node in path
            line = "$node,circle,2,1,000000,000000,5,5,20,$(rand()*360),000000,/home/hayden1126/LGL/PT_Mono/PTMono-Regular.ttf,5,FFFFFF,000000,/home/hayden1126/LGL/PT_Mono/PTMono-Regular.ttf,5,FFFFFF,000000,$(titles[node]),Deg $(length(graph[node]))"
            println(f, line)
        end
    end
end

function main()
    wglinks = @time get_links(EDGESFILE)
    titles = @time get_titles("id_titles/50_core_titles.txt")
    path = @time bfs(wglinks, ROOTNODE, GOAL)
    for node in path
        println(titles[node])
    end
    graph = @time combine_edges(path, wglinks, titles)
    write_edges(OUTPUTFILE, graph)
    write_labels(OUTPUTFILE, path, titles, graph)
end

if abspath(PROGRAM_FILE) == @__FILE__
    if length(ARGS) != 4 || !isfile(ARGS[1]) || !all(isnumeric, ARGS[2]) || !all(isnumeric, ARGS[3]) 
        println("Usage: julia combine_edges.jl <edgesfile> <startnode> <goal> <outputfile>")
        exit(1)
    end
    const EDGESFILE = ARGS[1]
    const ROOTNODE = parse(Int32, ARGS[2])
    const GOAL = parse(Int32, ARGS[3])
    const OUTPUTFILE = ARGS[4]
    main()
end