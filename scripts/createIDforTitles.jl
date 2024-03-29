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

if abspath(PROGRAM_FILE) == @__FILE__
    if length(ARGS) != 2 || !isfile(ARGS[1])
        println("Usage: julia createIDforTitles.jl <titlesfile> <outputfile>")
        exit(1)
    end
    const TITLESFILE = abspath(ARGS[1])
    const OUTPUTFILE = abspath(ARGS[2])

    main()
end