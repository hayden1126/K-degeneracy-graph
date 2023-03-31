include("EdgeUtils.jl")
using .ReadUtils

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
    if endswith(EDGESFILE_1, ".txt")
        wglinks1 = @time read_links(EDGESFILE_1)
    elseif endswith(EDGESFILE_1, ".lgl")
        wglinks1 = @time read_lgllinks(EDGESFILE_1)
    else
        println("Only .lgl or .txt filetypes supported.")
        exit(1)
    end

    if endswith(EDGESFILE_2, ".txt")
        wglinks2 = @time read_links(EDGESFILE_2)
    elseif endswith(EDGESFILE_2, ".lgl")
        wglinks2 = @time read_lgllinks(EDGESFILE_2)
    else
        println("Only .lgl or .txt filetypes supported.")
        exit(1)
    end

    if compare(wglinks1, wglinks2)
        println("   Links are indentical.")
    else
        println("\nLinks are different.")
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    if length(ARGS) != 2 || !isfile(ARGS[1]) || !isfile(ARGS[2])
        println("Usage: julia compareEdges.jl <edgesfile 1> <edgesfile 2>")
        exit(1)
    end
    const EDGESFILE_1 = abspath(ARGS[1])
    const EDGESFILE_2 = abspath(ARGS[2])
    main()
end
