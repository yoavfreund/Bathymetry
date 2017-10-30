#!/bin/bash

set -u
echo "`date`: starting land/$0 $@ "
purge
source ../../demPaths.sh

if [ "$#" != "5" ] ; then
	echo "usage: `basename $0` resolution tileWidth tileHeight srcDir dstDir "
	echo "  example: `basename $0` 3s 15 15 /Volumes/srtm15/DEM/CGIAR/ /Volumes/srtm15/doNotBackup/cgiarDownsampled6c/ "
	echo "  example: `basename $0` 6c 15 15 /Volumes/RAID/DEM/CGIAR/ /Volumes/RAID/doNotBackup/srtm15/cgiarDownsampledTo6c "
	exit
fi

resolution=$1;	shift
tileWidth=$1;	shift
tileHeight=$1;	shift
srcDir="$1"/;	shift
dstDir="$1"/;	shift

if [ ! -d "$srcDir" ]
then
       echo; echo; echo "ERROR: $srcDir is not mounted" ;
       echo; echo; echo "ABORTING..."; echo; echo; exit 1
fi
mkdir -p  $dstDir $dstDir/grd $dstDir/xyz $dstDir/logs

# cgiarDecodePath="/tmp/`basename $0`.cgiarNamesDecoderFile.$RANDOM"
# cgiarDecodePath="/tmp/`basename $0`.cgiarNamesDecoderFile"
cgiarDecodePath="$dstDir/.cgiarNamesDecoderFile"
echo "Using CGIAR decoder file $cgiarDecodePath"
if [ ! -f "$cgiarDecodePath" ]
then
	echo "decoding CGIAR names from $srcDir"
	rm -f $cgiarDecodePath
	mkdir -p `basename $cgiarDecodePath`
	touch $cgiarDecodePath
	find "$srcDir" -name "*.grd" -exec ./cgiarRenameGrd.sh '{}' \; > $cgiarDecodePath
fi

#stitch CGIAR files together. CGIAR coverage is +/-60N, +/-180E

for (( i=-180; i<180; i=i+$tileWidth ))
do
	for (( j=60; j>-60; j=j-$tileHeight ))
	do
		#pad values with 0s to three digits and determine e or w and n or s
		#e or w
		if [ "$i" -lt 0 ]; then
			i2=`echo $i | awk '{print substr($0, 2)}'`
			eorw="w"
		else
			i2=$i
			eorw="e"
		fi
		#pad m to 3 digits
		if [ ${#i2} == 2 ]; then
			i2="0"$i2
		elif [ ${#i2} == 1 ]; then
			i2="00"$i2
		fi

		#n or s
		if [ "$j" -lt 0 ]; then
			j2=`echo $j | awk '{print substr($0, 2)}'`
			nors="s"
		else
			j2=$j
			nors="n"
		fi
		#pad n to 2 digits
		if [ ${#j2} == 1 ]; then
			j2="0"$j2
		fi

		#file name of this tile:
		tile="$eorw""$i2""$nors""$j2"
# 		echo "CGIAR tile $tile"

		#if our width is even, we can use merge tiles even (faster, more parallelized), else we need to use odd
		rm $dstDir/logs/$tile".log" 2> /dev/null
		bash -x ./cgiarOddTilesMerge.sh $resolution $tileWidth $tileHeight $i $j $cgiarDecodePath $dstDir $tile > $dstDir/logs/$tile".log" 2>&1 &
		sleep 2
# echo "`ps | grep cgiarOddTilesMerge | grep -v grep | wc -l ` cgiarOddTilesMerge sub-processes running, `sysctl hw.activecpu | awk '{print $2 -0 }'` allowed"

		while [ `ps | grep cgiarOddTilesMerge | grep -v grep | wc -l ` -ge `sysctl hw.activecpu | awk '{print $2 -0 }'` ] ; do
# echo "`ps | grep cgiarOddTilesMerge | grep -v grep | wc -l ` cgiarOddTilesMerge sub-processes running, `sysctl hw.activecpu | awk '{print $2 -0 }'` allowed"
			sleep 15
		done
	done
	wait;wait;wait
	purge
done

wait

# make KMZ of all our tiles
(../dir2kmz.sh $dstDir/grd $dstDir/kmz  > $dstDir/logs/"dir2kmz.log" 2>&1)&

# cleanup
# rm -rf $dstDir/tmp
