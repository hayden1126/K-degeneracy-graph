include("EdgeUtils.jl")
using ProgressBars, .ReadUtils, .LinksUtils, .StatUtils

function read_kcorenums(filename::String)
    kcores = Int32[]
    degrees = Int32[]
    open(filename) do f
        for line in eachline(f)
            pair = split(line)
            push!(kcores, parse(Int32, pair[1]))
            push!(degrees, parse(Int32, pair[2]))
        end
    end
    return kcores, degrees
end

function main()
    kcores, degrees = read_kcorenums(EDGESFILE)
    scat(kcores, degrees, "output/k_corenums.png", "Relationship between K-core number and number of nodes"; xlab="K-core", ylab="Degree")
end

if abspath(PROGRAM_FILE) == @__FILE__
    if length(ARGS) != 1 || !isfile(ARGS[1])
        println("Usage: julia kcorestats.jl <edgesfile>")
    end 
    const EDGESFILE = ARGS[1]
    main()
end
