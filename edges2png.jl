include("$(@__DIR__)/scripts/EdgeUtils.jl")
using ProgressBars, .LglUtils, .ReadUtils, .TitleUtils, .DegreeUtils

function write_labels(outputfile::String, titlefile::String, degrees::Vector{Vector{Int32}})
    if isempty(degrees)
        println("Writing labels... No nodes to write, skipping...")
        return
    end

    titles = read_titles(titlefile)

    println("\nWriting labels...")
    open(outputfile, "w") do f
        for node in ProgressBar(degrees)
            id, title, degree = node[1], titles[node[1]], node[2]
            line = "$id,circle,2,1,000000,000000,5,5,20,$(rand()*360),000000,/home/hayden1126/LGL/PT_Mono/PTMono-Regular.ttf,5,FFFFFF,000000,/home/hayden1126/LGL/PT_Mono/PTMono-Regular.ttf,5,FFFFFF,000000,$title,Deg $degree"
            println(f, line)
        end
    end
end

function get_edge_rgb(degree1::Int32, degree2::Int32, maxdegree::Int32, mindegree::Int32)::Vector{Float16}
    range = maxdegree - mindegree
    absdiff = abs(degree1-degree2)
    red = Float16(absdiff/range)
    green = Float16(0)
    blue = Float16(1-(absdiff/range))
    return Float16[red, green, blue]
end

function write_colorededges(outputfile::String, wglinks::Dict{Int32, Vector{Int32}}, degrees::Vector{Vector{Int32}})
    if isempty(wglinks)
        println("\nWriting colored edges... No nodes to write, skipping...")
        return
    end
    println("\nWriting colored edges...")
    maxdegree = get_maxdegree(degrees)[2]
    mindegree = get_mindegree(degrees)[2]
    indices = get_indices(degrees)
    open(outputfile, "w") do f
        for (prime, primelinks) in ProgressBar(wglinks)
            for subnode in primelinks
                if !haskey(wglinks, subnode)
                    color = get_edge_rgb(degrees[indices[prime]][2], mindegree, maxdegree, mindegree)
                else
                    color = get_edge_rgb(degrees[indices[prime]][2], degrees[indices[subnode]][2], maxdegree, mindegree)
                end
                println(f, "$(prime) $(subnode) $(join(color, ' '))")
            end
        end
    end
end

function main()
    mkpath(DIRPATH)
    (wglinks, degrees) = read_degreeslinks(EDGESFILE)

    # write .lgl file from edges file
    write_lgl("$DIRPATH/$FILEPREFIX.lgl", wglinks, sorted=false)

    # write .labels file with "NUMBEROFLABELS" of nodes with the largest degrees
    if !isfile("$DIRPATH/$FILEPREFIX.labels")
        write_labels("$DIRPATH/$FILEPREFIX.labels", TITLEFILE, sort(degrees, by=x->x[2], rev=true)[1:NUMBEROFLABELS])
    end

    # write .colors file from dictionary of links
    write_colorededges("$DIRPATH/$FILEPREFIX.colors", wglinks, degrees)

    println("Changing directory to $DIRPATH")
    cd(DIRPATH)
    println("Fetching coordinates: $LGLPATH/bin/lglayout2D -t 4 -e -l $FILEPREFIX.lgl")
    run(`$LGLPATH/bin/lglayout2D -t $THREADS -I $FILEPREFIX.lgl`)
    # ^ Add -e to write MST used, -l to write edge level map around root node

    println("Generating images:")
    run(`java -Djava.awt.headless=false -Xmx8G -Xms1G -cp $LGLPATH/Java/jar/LGLLib.jar ImageMaker.GenerateImages 6200 6200 $DIRPATH/$FILEPREFIX.lgl $DIRPATH/lgl.out -c $DIRPATH/$FILEPREFIX.colors -l $DIRPATH/$FILEPREFIX.labels -s 0.01`) 
    # ^ edit parameters as needed
end

if abspath(PROGRAM_FILE) == @__FILE__
    if length(ARGS) != 4 || !isfile(ARGS[1]) || !isdir(ARGS[3]) || !isfile(ARGS[4])
        println("Usage: julia edges2png.jl <edgesfile> <fileprefix> <LGLpath> <titlesfile>")
        exit(1)
    end
    EDGESFILE = abspath(ARGS[1])
    FILEPREFIX = ARGS[2]
    LGLPATH = abspath(ARGS[3])
    TITLEFILE = abspath(ARGS[4])
    DIRPATH = "$(@__DIR__)/visualisation/$FILEPREFIX"
    NUMBEROFLABELS = 3
    THREADS = 4
    main()
end
