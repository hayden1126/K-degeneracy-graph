include("EdgeUtils.jl")
using ProgressBars, .ReadUtils, .TitleUtils

function get_topdegrees(degrees::Vector{Vector{Int32}}, topn::Int32)
    return sort(degrees, by=x->x[2], rev=true)[1:topn]
end

function write_labels(outputfile::String, titles::Dict{Int32, String}, topdegrees::Vector{Vector{Int32}})
    if isempty(topdegrees)
        println("Writing labels... No nodes to write, skipping...")
        return
    end
    println("\nWriting labels...")
    open(outputfile, "w") do f
        for node in ProgressBar(topdegrees)
            id, title, degree = node[1], titles[node[1]], node[2]
            line = "$id,circle,2,1,000000,000000,5,5,20,$(rand()*360),000000,/home/hayden1126/LGL/PT_Mono/PTMono-Regular.ttf,5,FFFFFF,000000,/home/hayden1126/LGL/PT_Mono/PTMono-Regular.ttf,5,FFFFFF,000000,$title,Deg $degree"
            println(f, line)
        end
    end
end

function main()
    (wglinks, degrees) = read_degreeslinks(EDGEFILE)
    titles = read_titles(TITLEFILE)
    topdegrees = get_topdegrees(degrees, TOPN)
    write_labels(OUTPUTFILE, titles, topdegrees)
end

if abspath(PROGRAM_FILE) == @__FILE__
    if length(ARGS) != 4 || !isfile(ARGS[1]) || !isfile(ARGS[2])
        println("Usage: julia edges2labels.jl <edgefile> <titlefile> <topn> <outputfile>")
        exit(1)
    end
    const EDGEFILE = abspath(ARGS[1])
    const TITLEFILE = abspath(ARGS[2])
    const TOPN = parse(Int32, ARGS[3])
    const OUTPUTFILE = abspath(ARGS[4])
    main()
end