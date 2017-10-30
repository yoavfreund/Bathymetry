#!/bin/bash

	# Use  "C" option on blockmedian because if there is a wild point that happens to have
	# median value we do not want to use its location. If there is no wild point and good
	# points do cluster in location, then the median of the location would make sense, as
	# would loc of pt with median value (-Q). Our goal is to find the most representative
	# depth of  block, which is the median, and we'll use that value at center of block.

if [ "$#" != "8" ]; then
	echo "usage: resolution xStep yStep minX maxY decoderFile destinationDir tileName "
	echo "  example: $0 15s 5 5 180 95 ./decodedCgiarNames ../cgiar/SRTM3/ w180n090 "
	exit
fi

resolution=$1;		shift
xStep=$1;			shift
yStep=$1;			shift
minX=$1;			shift
maxY=$1;			shift
cgiarDecodePath=$1;	shift
dstDir=$1;			shift
tile=$1;			shift

maxX=`expr $minX + $xStep`
minY=`expr $maxY - $yStep`

mkdir -p $dstDir/grd $dstDir/xyz $dstDir/kmz $dstDir/tmp

grd=$dstDir/grd/$tile.grd
xyz=$dstDir/xyz/$tile.xyz
tmp=$dstDir/tmp/$tile.xyz
rm -rf $grd $xyz $tmp

echo "downsampling CGIAR to create tile name: $dstDir/$tile"
date; echo;

# we know srtm3 tiles are in 5 deg tiles, just get the ones we assume will be there
#	if the tile is missing, that's ok "no data" is a valid answer over water!

for (( m=$minX; m< $maxX; m=m+5 ))
do
	for (( n=$maxY; n > $minY; n=n-5 ))
	do

		# pad values with 0s to three digits and determine e or w and n or s
		# e or w
		if [ "$m" -lt 0 ]; then
			m2=`echo $m | awk '{print substr($0, 2)}'`
			eorw="w"
		else
			m2=$m
			eorw="e"
		fi
		#pad m to 3 digits
		if [ ${#m2} == 2 ]; then
			m2="0"$m2
		elif [ ${#m2} == 1 ]; then
			m2="00"$m2
		fi

		# n or s
		if [ "$n" -lt 0 ]; then
			n2=`echo $n | awk '{print substr($0, 2)}'`
			nors="s"
		else
			n2=$n
			nors="n"
		fi
		# pad n to 2 digits
		if [ ${#n2} == 1 ]; then
			n2="0"$n2
		fi

		#if this CGIAR tile exists, stitch it to the output, which is
		# slightly tricky as grep returns nothing if the tile doesn't exist...

		cgiarFile="$eorw""$m2""$nors""$n2"
		cgiar=`grep $cgiarFile $cgiarDecodePath | awk '{ print $1 }'` ;
		if (( "${#cgiar}" > 0 )) ; then
			if [ -f $cgiar ] ; then
				echo "Adding $cgiar to $tmp"
				grd2xyz $cgiar -S -bo3 -V |
				blockmedian -bi3 -bo3 -I$resolution -R$minX/$maxX/$minY/$maxY -C -V >> $tmp
			fi
		fi

	done
done

# combine many small down sampled tiles

if [ -f $tmp ] ; then
minmax -bi3 $tmp
	# block median of xyz (probably unnecessary but xyz2grd moans with out some trick)...
	blockmedian -bi3 -bo3 $tmp -I$resolution -R$minX/$maxX/$minY/$maxY -C -V | \
	xyz2grd -bi -G$grd  -R$minX/$maxX/$minY/$maxY -I$resolution -V
# FIXME: use grdlandmask or not...
# 	grdLandMask_wrapper.sh $grd $grd "NaN/1"
	grd2xyz $grd -S -bo3 -V > $xyz

# 	../grd2kmz.sh $grd $dstDir/kmz ;
else
# 	touch   $tmp"
# 	xyz2grd $tmp" -G$grd -R$minX/$maxX/$minY/$maxY -I$resolution -V
# 	grd2xyz $grd -S -bo > $xyz
	echo "did NOT create empty tiles $grd $xyz"
fi

# rm -f $tmp
date
echo "Finished processing $dstDir/$tile"
