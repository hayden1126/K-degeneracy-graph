include("EdgeUtils.jl")
using .LglUtils

function main()
    write_edges2lgl(EDGESFILE, OUTPUTFILE)
end

if abspath(PROGRAM_FILE) == @__FILE__
    if length(ARGS) != 2 || !isfile(ARGS[1])
        println("Usage: julia edges2lgl.jl <edgesfile> <outputfile>")
        exit(1)
    end
    const EDGESFILE = ARGS[1]
    const OUTPUTFILE = ARGS[2]
    main()
end
