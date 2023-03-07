using ProgressBars

function main()
    titles = readlines(TITLESFILE)
    sort!(titles)
    open(OUTPUTFILE, "w") do f
        for (id, title) in ProgressBar(enumerate(titles))
            println(f, "$id $(strip(title))")
        end
    end
end

if length(ARGS) != 2 || !isfile(ARGS[1])
    println("Usage: julia createIDforTitles.jl <titlesfile> <outputfile>")
    exit(1)
end
const TITLESFILE = ARGS[1]
const OUTPUTFILE = ARGS[2]

main()