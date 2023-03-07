using ProgressBars

# Gets array of degrees and dictionary of links
function fetch_links()::Dict{Int32, Set{Int32}}
    println("Fetching links")

    wglinks = Dict{Int32, Set{Int32}}()
    filelines = countlines(EDGESFILE)

    prime = parse(Int32, split(readline(EDGESFILE))[1])
    wglinks[prime] = Set{Int32}()

    # For each line in edges file
    print("Progress: [0.0%]\r")
    for (index, line) = enumerate(eachline(EDGESFILE))

        pair = split(line)
        tmpprime = parse(Int32, pair[1])

        # If it is the same prime node, add 1 to degree
        if tmpprime == prime
            push!(wglinks[prime], parse(Int32, pair[2]))
        # If it is a new prime node, update the degree of the old prime node, then update temp variables to new prime node
        else
            if !haskey(wglinks, tmpprime)
                wglinks[tmpprime] = Set{Int32}(parse(Int32, pair[2]))
            else
                println("Separated")
                push!(wglinks[tmpprime], parse(Int32, pair[2]))
            end
            prime = tmpprime
        end

        # Print progress
        if index % 1000000 == 0
            print("Progress: [$(round(index/filelines*100, digits=1))%]\r")
        end
    end

    # Process the last prime node
    println("Progress: [100%] !")    
    return wglinks
end

function write_edges(wglinks::Dict{Int32, Set{Int32}})
    println("Writing edges...")

    open("./graph/edges0.txt", "w") do f
        for (prime, primelinks) in ProgressBar(wglinks)
            for subnode in primelinks
                println(f, "$(prime) $(subnode)")
            end
        end
    end
end

function main()
    wglinks = @time fetch_links()
    write_edges(wglinks)
end

EDGESFILE = ARGS[1]
main()