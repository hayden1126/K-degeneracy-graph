include("EdgeUtils.jl")
using .ReadUtils, .WriteUtils, .LinksUtils, .TitleUtils

function bfs(wglinks::Dict{Int32, Vector{Int32}}, rootnode::Int32, goal::Int32)::Vector{Int32}
    visited = Set{Int32}()
    queue = [Pair(rootnode, rootnode)]
    paths = Dict{Int32, Vector{Int32}}(rootnode=>Int32[])
    distance = Dict{Int32, Int32}(rootnode=>0)
    prevnode = rootnode
    while !isempty(queue)
        edge = popfirst!(queue)
        if edge[2] in visited
            continue
        end
        push!(visited, edge[2])
        prevnode = edge[1]
        tmpnode = edge[2]
        distance[tmpnode] = distance[prevnode] + 1
        paths[tmpnode] = [paths[prevnode]..., tmpnode]
        if tmpnode == goal
            break
        end
        if !haskey(wglinks, tmpnode)
            continue
        end
        for node in wglinks[tmpnode]
            if node ∉ visited
                push!(queue, Pair(tmpnode, node))
            end
        end
    end
    return paths[goal]
end

function lol(root::String, goal::String)
    path = @time bfs(wglinks, ids[root], ids[goal])
    for node in path println(titles[node]) end
end

function main()
    wglinks = @time get_links(EDGESFILE)
    titles = @time get_titles("id_titles/50_core_titles.txt")
    ids = Dict{String, Int32}()
    for (id, title) in titles
        ids[title] = id
    end
    rootnode = ids[ROOTNODE]
    goal = ids[GOAL]
    path = @time bfs(wglinks, rootnode, goal)
    for node in path
        println(titles[node])
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    if length(ARGS) != 3 || !isfile(ARGS[1]) # || !all(isnumeric, ARGS[2]) || !all(isnumeric, ARGS[3]) 
        println("Usage: julia bfs.jl <edgesfile> <startnode> <goal>")
        exit(1)
    end
    const EDGESFILE = ARGS[1]
    const ROOTNODE = ARGS[2]
    const GOAL = ARGS[3]
    main()
end