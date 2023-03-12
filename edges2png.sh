#!/bin/sh
EDGESFILE=$1
FILEPREFIX=${EDGESFILE%.*}
LGLPATH=$2
DIRPATH=./visualisation/$FILEPREFIX

# if [ ! -f EDGESFILE ]; then
#     echo Edges file: $EDGESFILE not found
#     exit 1
# fi

mkdir -p $DIRPATH
julia edges2lgl.jl $EDGESFILE $DIRPATH/$FILEPREFIX.lgl
if [ ! -f $DIRPATH/$FILEPREFIX.labels ]; then
    julia edges2labels.jl $EDGESFILE ./id_titles/titles.txt 3 $DIRPATH/$FILEPREFIX.labels
fi
julia edges2colors.jl $EDGESFILE $DIRPATH/$FILEPREFIX.colors

$LGLPATH/bin/lglayout2D -t 4 -L -e -l $DIRPATH/$FILEPREFIX.lgl
mv ./lgl.out* $DIRPATH/
java -Djava.awt.headless=false -Xmx8G -Xms6G -cp $LGLPATH/Java/jar/LGLLib.jar ImageMaker.GenerateImages 10000 10000 $DIRPATH/$FILEPREFIX.lgl $DIRPATH/lgl.out -c $DIRPATH/$FILEPREFIX.colors -l $DIRPATH/$FILEPREFIX.labels -s 0.01
cd $DIRPATH
for f in lgl.out_10000x10000*.png; do mv "$f" "$(echo "$f" | sed s/lgl.out_10000x10000/$(FILEPREFIX)_10k/)"; done
