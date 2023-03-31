include("EdgeUtils.jl")
using ProgressBars, .TitleUtils

function read_primes(edgesfile::String)::Vector{Int32}
    print("Fetching primes... [0.0%]\r")

    primes = Int32[]
    prime::Int32 = -1
    filelines = countlines(edgesfile)

    for (index, line) = enumerate(eachline(edgesfile))
        pair = split(line)
        tmpprime = parse(Int32, pair[1])
        if tmpprime != prime
            prime = tmpprime
            push!(primes, prime)
        end

        if index % 100 == 0
            print("Fetching primes... [$(round(index/filelines*100, digits=1))%]\r")
        end
    end
    println("Fetching primes... [100%] !")

    if length(primes) != length(Set(primes))
        println("File has duplicate primes!")
    end
    println("Primes: $(length(primes))")
    return primes
end

function main()
    primes = read_primes(EDGESFILE)
    titles = read_titles(TITLESFILE)
    write_titles(OUTPUTFILE, primes, titles)
end

if abspath(PROGRAM_FILE) == @__FILE__
    if length(ARGS) != 3 || !isfile(ARGS[1]) || !isfile(ARGS[2])
        println("Usage: julia edges2titles.jl <edgesfile> <titlesfile> <outputfile>")
        exit(1)
    end
    const EDGESFILE = abspath(ARGS[1])
    const TITLESFILE = abspath(ARGS[2])
    const OUTPUTFILE = abspath(ARGS[3])
    
    main()
end
