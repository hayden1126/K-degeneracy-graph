#!/bin/sh
K=$1
LGLPATH=$2
DIRPATH=./visualisation/${K}-core

mkdir -p $DIRPATH

if [ ! -f ./k_edges/${K}_core_edges.txt ]; then
    echo Edges file: ./k_edges/${K}_core_edges.txt not found
    exit 1
fi

if [ ! -f ./LGLfiles/${K}_core_edges.lgl ]; then
    julia edges2lgl.jl ./k_edges/${K}_core_edges.txt $DIRPATH/${K}_core_edges.lgl
fi

edgesfile=./k_edges/${K}_core_edges.txt
julia edges2labels.jl $edgesfile ./id_titles/titles.txt 3 $DIRPATH/${K}.labels
julia edges2colors.jl $edgesfile $DIRPATH/${K}.colors

$LGLPATH/bin/lglayout2D -t 4 -L -e -l $DIRPATH/${K}_core_edges.lgl
mv lgl.out* $DIRPATH
java -Djava.awt.headless=false -Xmx8G -Xms6G -cp $LGLPATH/Java/jar/LGLLib.jar ImageMaker.GenerateImages 10000 10000 $DIRPATH/${K}_core_edges.lgl $DIRPATH/lgl.out -c $DIRPATH/${K}.colors -l $DIRPATH/${K}.labels -s 0.01
for f in $DIRPATH/lgl.out_10000x10000*.png; do mv "$f" "$(echo "$f" | sed s/lgl.out_10000x10000/${K}_core_10k/)"; done
