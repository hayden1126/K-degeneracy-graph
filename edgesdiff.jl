# Get dictionary of links
function get_links(edgesfile::String)::Dict{Int32, Vector{Int32}}
    println("\nFetching links from $edgesfile...")

    wglinks = Dict{Int32, Vector{Int32}}()
    filelines = countlines(edgesfile)

    prime = parse(Int32, split(readline(edgesfile))[1])
    wglinks[prime] = Vector{Int32}()

    # For each line in edges file
    print("Progress: [0.0%]\r")
    for (index, line) = enumerate(eachline(edgesfile))

        pair = split(line)
        tmpprime = parse(Int32, pair[1])

        if tmpprime == prime
            push!(wglinks[prime], parse(Int32, pair[2]))
        else
            wglinks[tmpprime] = Int32[parse(Int32, pair[2])]

            # Update to new prime node
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

# Compare two dictionaries of links
function compare(wglinks1::Dict{Int32, Vector{Int32}}, wglinks2::Dict{Int32, Vector{Int32}})::Bool
    returnstatus = true
    println("\nComparing primes...")
    primesdiff1 = setdiff(keys(wglinks1), keys(wglinks2))
    primesdiff2 = setdiff(keys(wglinks2), keys(wglinks1))
    if  !isempty(primesdiff1)
        println("   Primes in file 1 but not file 2:")
        println("       $(join(primesdiff1, ", "))")
        return false
    end
    if !isempty(primesdiff2)
        println("   Primes in file 2 but not file 1:")
        println("       $(join(primesdiff2, ", "))")
        return false
    end
    println("   Primes are indentical.")

    println("\nComparing links...")
    for (prime, primelinks) in wglinks1
        linksdiff1 = setdiff(primelinks, wglinks2[prime])
        linksdiff2 = setdiff(wglinks2[prime], primelinks)
        if isempty(linksdiff1) && isempty(linksdiff2)
            continue
        end
        returnstatus = false
        println("   Prime $prime has different links:")
        if !isempty(linksdiff1)
            println("       In File 1 but not File 2: $(join(linksdiff1, ", "))")
        end
        if !isempty(linksdiff2)
            println("       In File 2 but not File 1: $(join(linksdiff2, ", "))")
        end
    end
    return returnstatus
end

function main()
    wglinks1 = @time get_links(EDGESFILE_1)
    wglinks2 = @time get_links(EDGESFILE_2)
    if compare(wglinks1, wglinks2)
        println("\nLinks are indentical.")
    else
        println("\nLinks are different.")
    end
end

if length(ARGS) != 2 || !isfile(ARGS[1]) || !isfile(ARGS[2])
    println("Usage: julia edgesdiff.jl <edgesfile 1> <edgesfile 2>")
    exit(1)
end
const EDGESFILE_1 = ARGS[1]
const EDGESFILE_2 = ARGS[2]

main()