#! /bin/bash

# Make a histogram of the difference of good and bad ping in the input file
#
# Input file format is the 9 column file: "cm format" plus extra column with $4-$8


if [ "$#" != "7" ] ; then
	echo "usage: `basename $0` file title xLabel yLabel col binWidth histoType "
	echo "  example: `basename $0` NOAA_geodas.cm Bad \"Ping (m)\" \"Log10 Count\" 4 250 4"
	exit
fi

iFile=$1;			shift;
title=$1;			shift;
xLabel=$1;			shift;
yLabel=$1;			shift;
((col=$1-1));		shift;
binWidth=$1;		shift;
histogramType=$1;	shift;

ps=$iFile.hist.ps
rm -f $ps

# Type of Histogram

# histogramType="0"
# yLabel="Count"
# histogramType="1"
# yLabel="Frequencey"
# histogramType="4"
# yLabel="Log10 Count"
# binWidth=250
# col=3				# first column is 0 so this is ping depth
# xLabel="Ping (m)"
# col=7				# first column is 0 so this is pred depth
# xLabel="Predicted at CLAIMED ping location (m)"
# col=8				# first column is 0 so this is ping-pred depth
# xLabel="Difference of Ping and Predicted at CLAIMED ping location (m)"

# Range of data used for X axis

minDepth=-12000
maxDepth=+12000
depthTick=2000
depthMinorTick=1000

# Range of data used for X axis

minFrequency=0
maxFrequency=10

# Figure parameters

figureOverlay=""
# figureOverlay="-O"
Sides="WSne"

plotWidth="4.8i"
plotHeight="2.4i"
plotOriginX="0"
plotOriginY="0"
plotOriginX="1.5i"
plotOriginY="1.0i"
fillColor="gray"
lineThickness="thinner"

xMin=$minDepth
xMax=$maxDepth
xStep=$depthTick
xTick=$depthMinorTick

yMin=$minFrequency
yMax=$maxFrequency
yStep=1
yTick=1

pshistogram	$iFile -T$col -F \
	-Z$histogramType -W$binWidth -G$fillColor -L$lineThickness \
    -R$xMin/$xMax/$yMin/$yMax \
	-Ba"$xStep"f"$xTick":"$xLabel":/a"$yStep"f"$yTick":"$yLabel"::,::."$title":$Sides \
	-JXh$plotWidth/$plotHeight -Y"$plotOriginY" -X"$plotOriginX" \
	$figureOverlay -V > $ps
open $ps
