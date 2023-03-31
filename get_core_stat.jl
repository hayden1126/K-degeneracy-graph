# Fetch core numbers from all the log files and returns dictionary of core numbers 
function get_core_numbers(lower::Int32, upper::Int32)::Dict{Int32, Int32}
    println("Getting core numbers...")
    cores = Dict{Int32, Int32}()
    for k in lower:upper
        logfile = "./logs/$(k)_core_edges.log"
        corenum = undef
        
        # Find line in file
        for line in eachline(logfile)
            if startswith(line, "No. of Nodes in $k-core graph:")
                corenum = parse(Int32, split(line, ':')[2])
                break
            end
        end
        cores[k] = corenum
    end
    return cores
end

function write_core_numbers(outputfile::String, cores::Dict{Int32, Int32})
    println("Writing core numbers...")
    open(outputfile, "w") do f
        for (corenum, count) in sort(collect(cores), by=x->x[1])
            println(f, "$(corenum) $(count)")
        end
    end
end

function main()
    cores = @time get_core_numbers(LOWERBOUND, UPPERBOUND)
    @time write_core_numbers(OUTPUTFILE, cores)
end

if abspath(PROGRAM_FILE) == @__FILE__
    if len(ARGS) != 3
        println("Usage: julia get_core_stats.jl <K lowerbound> <K upperbound> <outputfile>")
        exit(1)
    end
    const LOWERBOUND = parse(Int32, ARGS[1])
    const UPPERBOUND = parse(Int32, ARGS[2])
    const OUTPUTFILE = ARGS[3]
    main()
end