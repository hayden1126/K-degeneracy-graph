using ProgressBars

# Gets dictionary of links
function fetch_links(edgesfile::String)::Dict{Int32, Set{Int32}}
    print("Fetching links... [0.0%]\r")

    wglinks = Dict{Int32, Set{Int32}}()
    filelines = countlines(edgesfile)

    prime = parse(Int32, split(readline(edgesfile))[1])
    wglinks[prime] = Set{Int32}()

    # For each line in edges file
    for (index, line) = enumerate(eachline(edgesfile))

        pair = split(line)
        tmpprime = parse(Int32, pair[1])

        if tmpprime == prime
            push!(wglinks[prime], parse(Int32, pair[2]))
        else
            if !haskey(wglinks, tmpprime)
                wglinks[tmpprime] = Set{Int32}(parse(Int32, pair[2]))
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

# Writes edges to file
function write_edges(outputfile::String, wglinks::Dict{Int32, Set{Int32}})
    println("Writing edges...")

    open(outputfile, "w") do f
        for (prime, primelinks) in ProgressBar(wglinks)
            for subnode in sort(collect(primelinks))
                println(f, "$(prime) $(subnode)")
            end
        end
    end
end

function main()
    wglinks = @time fetch_links(EDGESFILE)
    write_edges(OUTPUTFILE, wglinks)
end

if abspath(PROGRAM_FILE) == @__FILE__
    if length(ARGS) != 2 || !isfile(ARGS[1])
        println("Usage: julia fix_edgeDuplicates.jl <edgesfile> <outputfile>")
        exit(1)
    end
    EDGESFILE = ARGS[1]
    OUTPUTFILE = ARGS[2]
    main()
end
