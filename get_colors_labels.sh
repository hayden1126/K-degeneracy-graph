K=$1
LGLPATH=$2

if [ ! -f ./k_edges/${K}_core_edges.txt ]; then
    echo Edges file: ./k_edges/${K}_core_edges.txt not found
    exit 1
fi

if [ ! -f ./LGLfiles/${K}_core_edges.lgl ]; then
    julia edges2lgl.jl ./k_edges/${K}_core_edges.txt ./LGLfiles/${K}_core_edges.lgl
fi

edgesfile=./k_edges/${K}_core_edges.txt
julia edges2labels.jl $edgesfile ./id_titles/titles.txt 3 ./colorlabels/${K}.labels
julia edges2colors.jl $edgesfile ./colorlabels/${K}.colors
mkdir -p $LGLPATH/${K}-core
cp ./colorlabels/${K}.labels $LGLPATH/${K}-core/
cp ./colorlabels/${K}.colors $LGLPATH/${K}-core/

if [ ! -f $LGLPATH/${K}-core/${K}_core_edges.lgl ]; then
    cp ./LGLfiles/${K}_core_edges.lgl $LGLPATH/${K}-core/
fi

echo "./bin/lglayout2D -t 4 -L -e -l ${K}_core_edges.lgl"
echo "mv lgl.out ${K}-core/"
echo "java -Djava.awt.headless=false -Xmx8G -Xms6G -cp ./Java/jar/LGLLib.jar ImageMaker.GenerateImages 10000 10000 ./${K}-core/${K}_core_edges.lgl ./${K}-core/lgl.out -c ./${K}-core/${K}.colors -l ./${K}-core/${K}.labels -s 0.01"
