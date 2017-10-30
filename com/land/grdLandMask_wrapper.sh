#!/bin/bash

if [ "$#" != "3" ] ; then
	echo "usage: `basename $0` ifilePath ofilePath maskValue"
	echo "  example: $0 /foo/e165s30.grd /foo/e165s30.grd NaN/NaN/NaN/1/NaN "
	exit
fi

ifilePath=$1;	shift
ofilePath=$1;	shift
maskValue=$1;	shift

stem=`basename -s .grd $ifilePath`
workingDir="/tmp/`basename -s .sh $0`"$RANDOM
mkdir -p $workingDir

grdlandmask -R$ifilePath -G$workingDir/$stem.mask.grd -N$maskValue -Df > /dev/null 2>&1
# avoid issues with ifile = ofile in the grdmath step by making copy of ifile
cp $ifilePath $workingDir/$stem.cp.grd
grdmath $workingDir/$stem.mask.grd $workingDir/$stem.cp.grd MUL = $ofilePath
rm -rf $workingDir

exit

#
# maskDistance='5-k'
# maskResolution="120c"
#
# grdmask can be very slow on fine pitch grid, given we just want to mask ocean from land
# make coarse mask and then resample to match input grd

# grd2xyz $ifilePath	-S | \
# blockmedian 									-R$ifilePath -I$maskResolution -bo3	| \
# grdmask		-S$maskDistance -NNaN/1/1		-R$ifilePath -I$maskResolution -bi3	-G$workingDir/$stem.mask.grd
# grdsample		-Q $workingDir/$stem.mask.grd	-R$ifilePath  						-G$workingDir/$stem.mask.upsampled.grd
#
# up sampling grd means we lost binary 0 or 1 values in mask, use GT 0 so mask is 0 or 1 again,
# 	and then turn 0 into NaN...
#
# grdmath $workingDir/$stem.mask.upsampled.grd 0.5 GT $ifilePath MUL DUP 3 GT MUL 0 NAN = $ofilePath
