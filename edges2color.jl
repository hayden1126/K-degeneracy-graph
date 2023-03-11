function write_coloredlinks(outputfile::String, wglinks::Dict{Int32, Vector{Int32}})
    if isempty(wglinks)
        println("\nWriting colored edges... No nodes to write, skipping...")
        return
    end
    println("\nWriting colored edges...")
    open(outputfile, "w") do f
        templinks = sort!(collect(wglinks), by=x->x[1])
        for (prime, primelinks) in ProgressBar(templinks)
            for subnode in sort(primelinks, by=x->x[1])
                println(f, "$(prime) $(subnode)")
            end
        end
    end
end
