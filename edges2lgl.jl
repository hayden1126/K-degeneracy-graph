function write2LGL(edgesfile::String, outputfile::String)
    print("Converting to LGL format... [0.0%]\r")
    filelines = countlines(edgesfile)

    prime = split(readline(edgesfile))[1]
    primelinks = String[]

    # For each line in edges file
    for (index, line) = enumerate(eachline(edgesfile))

        pair = split(line)

        if pair[1] == prime
            push!(primelinks, pair[2])
        else
            # Write to file
            open(outputfile, "a") do f
                println(f, "# $prime\n$(join(primelinks, '\n'))")
            end
            prime = pair[1]
            primelinks = String[pair[2]]
        end

        # Print progress
        if index % 1000000 == 0
            print("Converting to LGL format... [$(round(index/filelines*100, digits=1))%]\r")
        end
    end

    # Process the last prime node
    open(outputfile, "a") do f
        println(f, "# $prime\n$(join(primelinks, '\n'))")
    end
    println("Converting to LGL format... [100%] !")    
end

function main()
    write2LGL(ARGS[1], ARGS[2])
end

if abspath(PROGRAM_FILE) == @__FILE__
    if length(ARGS) != 2 || !isfile(ARGS[1])
        println("Usage: julia edges2lgl.jl <edgesfile> <outputfile>")
        exit(1)
    end
    main()
end
