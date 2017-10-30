#!/bin/bash

# bathymetry more shoal than a few meters is probably bad and isn't useful

if [ "$#" != "4" ] ; then
	echo "usage: `basename $0` maxZ cmDir hugeFile shoalFile "
	echo "  example: `basename $0` -10 cmFiles huge.xyzi huge.shoal.xyzi"
	exit
fi

maxZ=$1;		shift;
cmFileDir=$1;	shift;
oFile=$1;		shift;
badPing=$1;		shift;

rm -f $badPing $oFile; touch $badPing $oFile

cmFilePathList=`ls $cmFileDir/*.xyzi`
for cmFilePath in $cmFilePathList; do

	stem=`basename -s .xyzi $cmFilePath`

	case "$stem" in

	# lakes are above sea level, use all pings
	# 3DGBR has good data from 0 down, use all pings
        lakes | 3DGBR)
			echo "$stem : Using all pings"
			cat $cmFilePath >> $oFile;
			;;

        *) echo "$stem: Removing pings above $maxZ m (negative is below sea level)"
			# tmp file
			shoal=/tmp/`basename $0`.$stem.shoal.xyzi

			../../bin/selectSubAerial $cmFilePath $shoal /dev/stdout $maxZ >> $oFile
			minmax $shoal
			cat $shoal >> $badPing
			rm -f $shoal
			;;
	esac
done
