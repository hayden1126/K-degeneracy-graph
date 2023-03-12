EDGESFILE=$1
FILEPREFIX=${EDGESFILE%.*}
LGLPATH=$2

if [ ! -f EDGESFILE ]; then
    echo Edges file: $EDGESFILE not found
    exit 1
fi

mkdir -p $FILEPREFIX
julia edges2lgl.jl $EDGESFILE ./$FILEPREFIX/$FILEPREFIX.lgl
julia edges2labels.jl $EDGESFILE ./id_titles/titles.txt 3 ./$FILEPREFIX/$FILEPREFIX.labels
julia edges2colors.jl $EDGESFILE ./$FILEPREFIX/$FILEPREFIX.colors

$LGLPATH/bin/lglayout2D -t 4 -L -e -l $FILEPREFIX/$FILEPREFIX.lgl
mv $LGLPATH/lgl.out* $FILEPREFIX/
java -Djava.awt.headless=false -Xmx8G -Xms6G -cp $LGLPATH/Java/jar/LGLLib.jar ImageMaker.GenerateImages 10000 10000 $FILEPREFIX/$FILEPREFIX.lgl $FILEPREFIX/lgl.out -c $FILEPREFIX/$FILEPREFIX.colors -l ./$FILEPREFIX/$FILEPREFIX.labels -s 0.01
for f in $FILEPREFIX/lgl.out_10000x10000*.png; do mv "$f" "$(echo "$f" | sed s/lgl.out_10000x10000/${FILEPREFIX}_10k/)"; done
