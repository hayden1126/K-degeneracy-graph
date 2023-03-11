include("EdgeUtils.jl")
using .ReadUtils, .WriteUtils, .DegreeUtils

function main()
    (wglinks, degrees) = @time get_degreeslinks(EDGESFILE)
    maxdegree = get_maxdegree(degrees)[2]
    mindegree = get_mindegree(degrees)[2]
    absdiff = maxdegree - mindegree
    println("Max degree: $(maxdegree)")
    println("Min degree: $(mindegree)")
    println("Absolute difference: $(absdiff)")

    write_degrees(OUTPUTFILE, degrees)
end

if abspath(PROGRAM_FILE) == @__FILE__
    if length(ARGS) != 2 || !isfile(ARGS[1])
        println("Usage: julia write_degrees.jl <edgesfile> <outputfile>")
        exit(1)
    end
    const EDGESFILE = ARGS[1]
    const OUTPUTFILE = ARGS[2]
    main()
end
