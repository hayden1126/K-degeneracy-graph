using ProgressBars

function get_primes(edgesfile::String)::Vector{Int32}
    println("Fetching primes...")

    primes = Int32[]
    prime::Int32 = -1
    filelines = countlines(edgesfile)

    print("Progress: [0.0%]\r")
    for (index, line) = enumerate(eachline(edgesfile))
        pair = split(line)
        tmpprime = parse(Int32, pair[1])
        if tmpprime != prime
            prime = tmpprime
            push!(primes, prime)
        end

        if index % 100 == 0
            print("Progress: [$(round(index/filelines*100, digits=1))%]\r")
        end
    end
    println("Progress: [100%] !")

    if length(primes) != length(Set(primes))
        println("File has duplicate primes!")
    end
    println("Primes: $(length(primes))")
    return primes
end

function get_titles(titlesfile::String)::Dict{Int32, String}
    println("Fetching titles...")

    titles = Dict{Int32, String}()
    filelines = countlines(titlesfile)

    print("Progress: [0.0%]\r")
    for (index, line) = enumerate(eachline(titlesfile))
        pair = split(line, limit=2)
        titles[parse(Int32, pair[1])] = pair[2]

        # Print progress
        if index % 100 == 0
            print("Progress: [$(round(index/filelines*100, digits=1))%]\r")
        end
    end
    println("Progress: [100%] !")

    println("Titles: $(length(titles))")
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
            println(f, "$prime\t$(titles[prime])\n")
        end
    end
end

function main()
    primes = get_primes(EDGESFILE)
    titles = get_titles(TITLESFILE)
    write_titles(OUTPUTFILE, primes, titles)
end

if length(ARGS) != 3 || !isfile(ARGS[1]) || !isfile(ARGS[2])
    println("Usage: julia edges2titles.jl <edgesfile> <titlesfile> <outputfile>")
    exit(1)
end
const EDGESFILE = ARGS[1]
const TITLESFILE = ARGS[2]
const OUTPUTFILE = ARGS[3]

main()