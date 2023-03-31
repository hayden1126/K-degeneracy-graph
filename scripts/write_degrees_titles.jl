include("EdgeUtils.jl")
using ProgressBars, .ReadUtils, .DegreeUtils, .TitleUtils

function write_titles_degrees(outputfile::String, degrees::Vector{Vector{Int32}}, titles::Dict{Int32, String})
    if all(isempty, degrees)
        println("\nWriting degrees... No nodes to write, skipping...")
        return
    end
    println("\nWriting degrees...")
    open(outputfile, "w") do f
        for node in ProgressBar(degrees)
            println(f, "$(titles[node[1]]) $(node[2])")
        end
    end
end

function main()
    (wglinks, degrees) = @time get_degreeslinks(EDGESFILE)
    maxdegree = get_maxdegree(degrees)[2]
    mindegree = get_mindegree(degrees)[2]
    absdiff = maxdegree - mindegree
    println("Max degree: $(maxdegree)")
    println("Min degree: $(mindegree)")
    println("Absolute difference: $(absdiff)")

    titles = read_titles(TITLESFILE)
    write_titles_degrees(OUTPUTFILE, sort(degrees, by=x->x[2], rev=true), titles)
end

if abspath(PROGRAM_FILE) == @__FILE__
    if length(ARGS) != 3 || !isfile(ARGS[1]) || !isfile(ARGS[2])
        println("Usage: julia write_degrees.jl <edgesfile> <outputfile>")
        exit(1)
    end
    const EDGESFILE = abspath(ARGS[1])
    const TITLESFILE = abspath(ARGS[2])
    const OUTPUTFILE = abspath(ARGS[3])
    main()
end
