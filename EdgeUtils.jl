module ReadUtils
    # using ProgressBars
    export get_links, get_degreeslinks, get_lgllinks

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

    # Gets dictionary of links from LGL file format
    function get_lgllinks(edgesfile::String)::Dict{Int32, Vector{Int32}}
        print("\nFetching links... [0.0%]\r")

        wglinks = Dict{Int32, Vector{Int32}}()
        filelines = countlines(edgesfile)
        
        prime = parse(Int32, split(readline(edgesfile))[2])
        wglinks[prime] = Int32[]

        # For each line in edges file
        for (index, line) = enumerate(eachline(edgesfile))

            if '#' in line
                prime = parse(Int32, split(line)[2])
                wglinks[prime] = Int32[]
                continue
            end
            subnode = parse(Int32, line)
            push!(wglinks[prime], subnode)
            if index % 1000000 == 0
                print("Fetching links... [$(round(index/filelines*100, digits=1))%]\r")
            end
        end
        return wglinks
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

module TitleUtils
using ProgressBars
export get_titles, write_titles

    function get_titles(titlesfile::String)::Dict{Int32, String}
        print("Fetching titles... [0.0%]\r")

        titles = Dict{Int32, String}()
        filelines = countlines(titlesfile)

        for (index, line) = enumerate(eachline(titlesfile))
            pair = split(line, limit=2)
            titles[parse(Int32, pair[1])] = pair[2]

            # Print progress
            if index % 100 == 0
                print("Fetching titles... [$(round(index/filelines*100, digits=1))%]\r")
            end
        end
        println("Fetching titles... [100%] !")

        println("Titles provided: $(length(titles))")
        return titles
    end

    function write_titles(outfile::String, primes::Vector{Int32}, titles::Dict{Int32, String})
        println("Writing titles to file...")
        open(outfile, "w") do f
            for prime in ProgressBar(sort(primes))
                if !haskey(titles, prime)
                    println("Missing title for prime: $prime")
                    continue
                end
                println(f, "$prime\t$(titles[prime])")
            end
        end
    end
end

module StatUtils
    using PyPlot, Statistics
    export logHistogram, logHistogramScaled, scat, analyse

    function logHistogram(
            data, bins, fname, ttl; 
            xlab="Number of links", ylab="Frequency density", dpi=1000, ysc="log"
        )
        hist(data, bins=bins)
        yscale(ysc)
        title(ttl)
        xlabel(xlab)
        ylabel(ylab)
        savefig(fname, dpi=dpi)
        cla()
    end

    function logHistogramScaled(
            data, bins, fname, ttl; 
            xlab="Number of links", ylab="Frequency density", dpi=1000, ysc="log",
            yl=1e+7, xl=3e+5
        )
        hist(data, bins=bins)
        yscale(ysc)
        ylim(0, yl)
        xlim(-2500, xl)
        title(ttl)
        xlabel(xlab)
        ylabel(ylab)
        savefig(fname, dpi=dpi)
        cla()
    end

    function scat(
            outdegrees, indegrees, fname, ttl;
            xlab="x", ylab="y", dpi=1000, sz=0.05, dims=(9, 12)
        )
        plt = scatter(outdegrees, indegrees, s=sz, marker=".")
        plt.set_sizes(dims, dpi=dpi)
        # yscale(ysc)
        title(ttl)
        xlabel(xlab)
        ylabel(ylab)
        savefig(fname, dpi=dpi)
        cla()
    end

    function analyse(arr, name)
        println("> $(name) <")
        println("| Length:\t$(length(arr))")
        println("| 0-Count:\t$(count(i->(i==0), arr))")
        println("| Sum:\t\t$(sum(arr))")
        println("| Mean:\t\t$(mean(arr))")
        println("| Median:\t$(median(arr))")
        println("| Stddv:\t$(std(arr))")
        println("| Variance:\t$(var(arr))")
    end

end

module LglUtils
    using ProgressBars
    export write_edges2lgl

    # Converts and writes edges txt file format to .lgl format
    function write_edges2lgl(edgesfile::String, outputfile::String)
        print("Converting and writing edges to LGL format... [0.0%]\r")
        filelines = countlines(edgesfile)

        prime = split(readline(edgesfile))[1]
        primelinks = String[]

        # For each line in edges file
        for (index, line) = enumerate(eachline(edgesfile))

            pair = split(line)

            if pair[1] == prime
                push!(primelinks, pair[2])
            else
                # Write to file
                open(outputfile, "a") do f
                    println(f, "# $prime\n$(join(primelinks, '\n'))")
                end
                prime = pair[1]
                primelinks = String[pair[2]]
            end

            # Print progress
            if index % 1000000 == 0
                print("Converting and writing edges to LGL format... [$(round(index/filelines*100, digits=1))%]\r")
            end
        end

        # Process the last prime node
        open(outputfile, "a") do f
            println(f, "# $prime\n$(join(primelinks, '\n'))")
        end
        println("Converting and writing edges to LGL format... [100%] !")    
    end

    # Writes links to a new .lgl file
    function write_lgl(outputfile::String, wglinks::Dict{Int32, Vector{Int32}})
        println("Writing LGL file...")
        open(outputfile, "w") do f
            for (prime, primelinks) in ProgressBar(sort!(collect(wglinks), by=x->x[1]))
                println(f, "# $prime")
                for subnode in sort(primelinks)
                    println(f, subnode)
                end
            end
        end
    end
end