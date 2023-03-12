include("EdgeUtils.jl")
using ProgressBars, .ReadUtils, .LinksUtils, .StatUtils

function read_kcorenums(filename::String)
    cores = Dict{Int32, Int32}()
    open(filename) do f
        for line in eachline(f)
            pair = split(line)
            cores[parse(Int32, pair[1])] = parse(Int32, pair[2])
        end
    end
    return cores
end

function main()
    cores = read_kcorenums(EDGESFILE)
    scat(values(cores), keys(cores), "output/k_corenums.png", "Relationship between K-core number and number of nodes of Wikipedia Pages")
end

if abspath(PROGRAM_FILE) == @__FILE__
    if length(ARGS) != 1 || !isfile(ARGS[1])
        println("Usage: julia kcorestats.jl <edgesfile>")
    end 
    EDGESFILE = ARGS[1]
    main()
end
