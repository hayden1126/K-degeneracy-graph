include("$(dirname(@__DIR__))/scripts/EdgeUtils.jl")
using ProgressBars, .StatUtils

function read_kcorenums(filename::String)::Tuple{Vector{Int32}, Vector{Int32}}
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

# Reads kcorenums file and plots graph of Relationship between K-core number and number of nodes
function main()
    kcores, degrees = read_kcorenums(KCORENUMSFILE)
    scat(kcores, degrees, "$STATSDIRPATH/k_corenums.png", "Relationship between K-core number and number of nodes"; xlab="K-core", ylab="Degree")
end

if abspath(PROGRAM_FILE) == @__FILE__
    if length(ARGS) != 1 || !isfile(ARGS[1])
        println("Usage: julia kcorestats.jl <kcorenums file>")
    end 
    const KCORENUMSFILE = ARGS[1]
    const STATSDIRPATH = "$(dirname(@__DIR__))/stats"
    main()
end
