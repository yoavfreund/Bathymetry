#!/bin/bash

if [ "$#" != "8" ]; then
    echo "usage: W E S N tileSizeInDegX tileSizeInDegY sidDir oDir "
    echo "  example: -130 -120 30 35 15 15 ../../test15c/grd/ ../../"
    exit
fi

((w=$1));			shift
((e=$1));			shift
((s=$1));			shift
((n=$1));			shift
((tileSizeX=$1));	shift
((tileSizeY=$1));	shift
sidTileDir=$1;		shift
oDir=$1;			shift

source ../../demPaths.sh

mkdir -p $oDir

for (( x = $w; x < $e; x = $x + $tileSizeX ))
    do
	for (( y=$n; y> $s; y=$y-$tileSizeY ))
        do

        #pad x with 0s to three digits and determine e or w
        #e or w
        if [ "$x" -lt 0 ]; then
            ew=`echo $x | awk '{print substr($0, 2)}'`
            eorw="w"
        else
            ew=$x
            eorw="e"
        fi
        #pad ew string to 3 digits
        if [ ${#ew} == 2 ]; then
            ew="0"$ew
        elif [ ${#ew} == 1 ]; then
            ew="00"$ew
        elif [ ${#ew} == 0 ]; then
            ew="000"$ew
        fi

        #n or s?
        if [ "$y" -lt 0 ]; then
            ns=`echo $y | awk '{print substr($0, 2)}'`
            nors="s"
        else
            ns=$y
            nors="n"
        fi
        #pad ns string to 2 digits
        if [ ${#ns} == 1 ]; then
            ns="0"$ns
        elif [ ${#ns} == 0 ]; then
            ns="00"$ns
        fi

        sidFile="$sidTileDir/$eorw""$ew""$nors""$ns.sid.grd"
        stem=`basename -s .sid.grd $sidFile`
echo $stem
        hitFile=$oDir/$stem.hit.grd

#         ( grdmath $sidFile 0 NAN DUP $arcticSid NEQ MUL 0 GT = $hitFile ;
        ( grdmath $sidFile $arcticSid NAN 0 NAN 0 GT = $hitFile ;
          ../grd2kmz.sh $hitFile $oDir ;
#           rm -f $hitFile )&
    done
	wait
done
# rm -rf $oDir/grd2KmlFiles
