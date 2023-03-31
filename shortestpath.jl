include("$(@__DIR__)/scripts/EdgeUtils.jl")
using .ReadUtils, .WriteUtils, .LinksUtils, .TitleUtils

# Gets shortest path from one node to another using modified BFS algorithm
function get_shortestpath(wglinks::Dict{Int32, Vector{Int32}}, rootnode::Int32, goal::Int32)::Vector{Int32}
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

function main()
    wglinks = @time read_links(EDGESFILE)
    titles = @time read_titles("id_titles/50_core_titles.txt")
    ids = Dict{String, Int32}()
    for (id, title) in titles
        ids[title] = id
    end
    if INTERACTIVE
        while true
            println('-'^displaysize(stdout)[2])
            print("Start node: ")
            root = readline()
            print("End node: ")
            goal = readline()

            if root == "exit" || goal == "exit"
                println("Exiting.")
                exit()
            end

            if !haskey(ids, root)
                println("-Invalid node: $root-")
                continue
            elseif !haskey(ids, goal)
                println("-Invalid node: $goal-")
                continue
            end

            path = @time get_shortestpath(wglinks, ids[root], ids[goal])
            for node in path 
                println(titles[node]) 
            end
        end
    else
        path = @time get_shortestpath(wglinks, ids[root], ids[goal])
        for node in path 
            println(titles[node]) 
        end
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    if length(ARGS) == 3
        const INTERACTIVE = false
        const ROOTNODE = ARGS[2]
        const GOAL = ARGS[3]
    elseif length(ARGS) == 1 || isfile(ARGS[1])
        const INTERACTIVE = true
    else
        println("Usage: julia shortestpath.jl <edgesfile> <optional: startnode endnode>")
        exit(1)
    end
    const EDGESFILE = ARGS[1]
    main()
end