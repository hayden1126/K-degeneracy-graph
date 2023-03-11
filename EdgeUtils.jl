module ReadUtils
    # using ProgressBars
    export get_links, get_degreeslinks

    # Gets dictionary of links
    function get_links(edgesfile::String)::Dict{Int32, Vector{Int32}}
        print("\nFetching links... [0.0%]\r")

        wglinks = Dict{Int32, Vector{Int32}}()
        filelines = countlines(edgesfile)

        prime = parse(Int32, split(readline(edgesfile))[1])
        wglinks[prime] = Int32[]

        # For each line in edges file
        for (index, line) = enumerate(eachline(edgesfile))

            pair = split(line)
            tmpprime = parse(Int32, pair[1])

            if tmpprime == prime
                push!(wglinks[prime], parse(Int32, pair[2]))
            else
                if !haskey(wglinks, tmpprime)
                    wglinks[tmpprime] = Int32[parse(Int32, pair[2])]
                else
                    push!(wglinks[tmpprime], parse(Int32, pair[2]))
                end
                prime = tmpprime
            end

            if index % 1000000 == 0
                print("Fetching links... [$(round(index/filelines*100, digits=1))%]\r")
            end
        end

        # Process the last prime node
        println("Fetching links... [100%] !")    
        return wglinks
    end

    # Gets array of degrees and dictionary of links
    function get_degreeslinks(edgesfile::String)::Tuple{Dict{Int32, Vector{Int32}}, Vector{Vector{Int32}}}
        print("\nFetching links and degrees... [0.0%]\r")

        degrees = Vector{Vector{Int32}}()
        wglinks = Dict{Int32, Vector{Int32}}()
        filelines = countlines(edgesfile)

        prime = parse(Int32, split(readline(edgesfile))[1])
        wglinks[prime] = Vector{Int32}()
        degree::Int32 = 0

        # For each line in edges file
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
                print("Fetching links and degrees... [$(round(index/filelines*100, digits=1))%]\r")
            end
        end

        # Process the last prime node
        push!(degrees, [prime, degree])
        println("Fetching links and degrees... [100%] !")    
        return (wglinks, degrees)
    end
end

module LinksUtils
    using ProgressBars
    export get_degrees, get_indices, get_directedlinks, remove_links!

    # Gets the degrees of all nodes
    function get_degrees(wglinks::Dict{Int32, Vector{Int32}})
        print("\nFetching degrees... \r")
        degrees = Vector{Vector{Int32}}()
        for (prime, primelinks) in wglinks
            push!(degrees, [prime, length(primelinks)])
        end
        println("Fetching degrees... Done!")
        return degrees
    end
    
    # Gets the dictionary of indices of a node in the degrees array
    function get_indices(degrees::Vector{Vector{Int32}})::Dict{Int32, Int32}
        indices = Dict{Int32, Int32}()
        for (index, node) in enumerate(degrees)
            indices[node[1]] = index
        end
        return indices
    end

    # Gets dictionary of inbound links and set of nodes with no outbound links
    function get_directedlinks(wglinks::Dict{Int32, Vector{Int32}})::Tuple{Dict{Int32, Vector{Int32}}, Set{Pair{Int32}}, Int32}
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

    # Removes links from the adjacency list based on the array of nodes to remove
    function remove_links!(wglinks::Dict{Int32, Vector{Int32}}, remove::Vector{Int32}, inboundlinks::Dict{Int32, Vector{Int32}})
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
                        deleteat!(wglinks[prime], findfirst(==(node), wglinks[prime]))
                    end
                end
                delete!(inboundlinks, node)
            end
            
            # Remove links from node
            delete!(wglinks, node)
        end
    end
end

module DegreeUtils
    export get_maxdegree, get_mindegree
    function get_maxdegree(degrees::Vector{Vector{Int32}})::Vector{Int32}
        maxdegree = Int32[0, 0]
        for node in degrees
            if node[2] > maxdegree[2]
                maxdegree = node
            end
        end
        return maxdegree
    end

    function get_mindegree(degrees::Vector{Vector{Int32}})::Vector{Int32}
        mindegree = Int32[0, typemax(Int32)]
        for node in degrees
            if node[2] < mindegree[2]
                mindegree = node
            end
        end
        return mindegree
    end
end

module WriteUtils
using ProgressBars
    export write_degrees, write_edges

    # Writes the degrees to a new file
    function write_degrees(outputfile::String, degrees::Vector{Vector{Int32}})
        if all(isempty, degrees)
            println("\nWriting degrees... No nodes to write, skipping...")
            return
        end
        println("\nWriting degrees...")
        open(outputfile, "w") do f
            for node in ProgressBar(degrees)
                println(f, "$(node[1]) $(node[2])")
            end
        end
    end

    # Writes the adjacency list to a new file
    function write_edges(outputfile::String, wglinks::Dict{Int32, Vector{Int32}})
        if isempty(wglinks)
            println("Writing edges... No nodes to write, skipping...")
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
end
