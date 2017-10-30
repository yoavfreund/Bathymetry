#!/bin/bash

set -u
echo "`date`: starting land/$0 $@ "
purge
source ../../demPaths.sh

if [ "$#" != "5" ] ; then
	echo "usage: `basename $0` resolution tileWidth tileHeight srcDir dstDir "
	echo "  example: `basename $0` 15s 15 15 /Volumes/srtm15/DEM/GLAS/ /Volumes/srtm15/doNotBackup/glasDownsampled"
	echo "  example: `basename $0` 6c 15 15 /Volumes/RAID/DEM/GLAS/ /Volumes/RAID/doNotBackup/srtm15/glasDownsampled6c "
	exit
fi

resolution=$1;	shift
tileWidth=$1;	shift
tileHeight=$1;	shift
srcDir="$1"/;	shift
dstDir="$1"/;	shift

# surfaceOpts set in ../../demPaths.sh

echo "`date`: GLAS tiles..."

	# Use  "C" option on blockmedian because if there is a wild point that happens to have
	# median value we do not want to use its location. If there is no wild point and good
	# points do cluster in location, then the median of the location would make sense, as
	# would loc of pt with median value (-Q). Our goal is to find the most representative
	# depth of  block, which is the median, and we'll use that value at center of block.


tmpDir=$dstDir/tmp
mkdir -p  $dstDir $dstDir/grd $dstDir/xyz $dstDir/logs $tmpDir

for (( iteration=0; iteration<2; iteration=iteration+1 ))
do
	if [ "$iteration" -eq 1 ]; then
		stem=NSIDC_Ant500m_wgs84_elev ; projection='+init=epsg:3412'
		minX=-180; maxX=180
		minY=-90;  maxY=-60
	else
		stem=NSIDC_Grn1km_wgs84_elev  ; projection='+init=epsg:3413'
		minX=-75; maxX=0
		minY=60;  maxY=90
	fi


	NSIDC_remainder=$tmpDir/$stem.remainder.xyz
	echo "Projecting "$srcDir/$stem"_cm.dat from $projection to Mercator..."
	grdmath "$srcDir/$stem"_cm.dat=gd 0.01 MUL 0 MAX = "$tmpDir/$stem"_m.nc -V
	grd2xyz "$tmpDir/$stem"_m.nc -S | invproj "$projection" -f "%.9f" |
		../../bin/convertInvprojAsciiToBinary /dev/stdin $NSIDC_remainder
	((jobsRunning=0));
	for (( lon=$minX; lon<=$maxX-$tileWidth; lon=lon+$tileWidth ))
	do
		for (( lat=$maxY; lat>=$minY+tileHeight; lat=lat-$tileHeight ))
		do
			#pad values with 0s to three digits and determine e or w and n or s
			#e or w
			if [ "$lon" -lt 0 ]; then
				lon2=`echo $lon | awk '{print substr($0, 2)}'`
				eorw="w"
			else
				lon2=$lon
				eorw="e"
			fi
			#pad i to 3 digits
			if [ ${#lon2} == 2 ]; then
				lon2="0"$lon2
			elif [ ${#lon2} == 1 ]; then
				lon2="00"$lon2
			fi

			#n or s
			if [ "$lat" -lt 0 ]; then
				lat2=`echo $lat | awk '{print substr($0, 2)}'`
				nors="s"
			else
				lat2=$lat
				nors="n"
			fi
			#pad n to 3 digits
			if [ ${#lat2} == 1 ]; then
				lat2="00"$lat2
			fi

			#file name of this tile:
			tile="$eorw$lon2$nors$lat2"
# 			echo "GLAS tile " $tile

			#block median to $resolution
			((w=`expr $lon`));
			((e=`expr $lon+$tileWidth`));
			((s=`expr $lat-tileHeight`));
			((n=`expr $lat`));

# pick pings of interest out of larger xyz file, then write a script to process it.
			region="$w/$e/$s/$n"
			xyz=$tmpDir/$tile.xyz
			../../bin/selectAndSortBinary $NSIDC_remainder $xyz $tmpDir/$stem.else.xyz $w $e $s $n
			mv $tmpDir/$stem.else.xyz $NSIDC_remainder
			minmax -bi3 $xyz > $dstDir/logs/$tile".log" 2>&1
			grd=$tmpDir/$stem.$tile.grd
			xyzMedianFiltered=$tmpDir/$stem.$tile.blockmedian.xyz


			cmdFile=$tmpDir/$tile.cmd
			rm -f $cmdFile
			echo "#!/bin/bash " >> $cmdFile
			echo "blockmedian -C $xyz -R$region -I$resolution  -bi3 -bo3 > $xyzMedianFiltered"		>> $cmdFile
			echo "surface $xyzMedianFiltered -G$grd -fg -R$region -I$resolution -bi3 $surfaceOpts"	>> $cmdFile
# save the -UN-masked grd and xyz
			echo "mv $grd $dstDir/grd/$tile.grd " 													>> $cmdFile
			echo "grd2xyz $dstDir/grd/$tile.grd -S -bo3 > $dstDir/xyz/$tile.xyz "					>> $cmdFile

# unfortunately NSIDC data is polluted with sea level data
# go thru a lot of gyrations to remove marine data
#
# grdmask can be very slow on fine pitch grid, given we just want to mask ocean from land
# make coarse mask and then upsample mask to match input grd
# up sampling grd means we lost binary 0 or 1 values in mask, use GT 0 so mask is 0 or 1 again,
# 	and then turn 0 into NaN...
# 			echo "echo unfortunately NSIDC data is polluted with sea level data"					>> $cmdFile
# 			echo "echo go thru a lot of gyrations to remove marine data"							>> $cmdFile
# 			maskDistance='5-k'
# 			maskResolution="120c"
# 			mask=$tmpDir/$stem.$tile.grdmask.grd
# 			upsampledMask=$tmpDir/$stem.$tile.grdmask.upsampledMask.grd
# 			echo "blockmedian -C $xyzMedianFiltered -R$region -I$maskResolution -bi3 -bo3 | "		>> $cmdFile
# 			echo "	grdmask -S$maskDistance -NNaN/1/1 -R$region -I$maskResolution -bi3 -G$mask"		>> $cmdFile
# 			echo "grdsample -Q $mask -R$grd -G$upsampledMask"										>> $cmdFile
# 			echo "grdmath $upsampledMask 0.5 GT $grd MUL DUP 3 GT MUL 0 NAN = $dstDir/grd/$tile.grd" >>$cmdFile
# FIXME: use grdlandmask or not...
# 			echo "grdLandMask_wrapper.sh $grd $dstDir/grd/$tile.grd NaN/NaN/NaN/1/NaN "				>> $cmdFile
# 			echo "grdLandMask_wrapper.sh $grd $dstDir/grd/$tile.grd NaN/1             "				>> $cmdFile
#
#
# # save the -UN-masked grd and xyz
# 			echo "mv $grd $dstDir/grd/$tile.grd " 													>> $cmdFile
# 			echo "grd2xyz $dstDir/grd/$tile.grd -S -bo3 > $dstDir/xyz/$tile.xyz "					>> $cmdFile
# delete any empty tiles
# 			echo "minmax -bi3 $dstDir/xyz/$tile.xyz "												>> $cmdFile
# 			echo "if [ \`ls -al $dstDir/xyz/$tile.xyz | awk '{ print \$5 }'\` -le 0 ]; then "		>> $cmdFile
# 			echo "echo $tile.xyz is empty, deleting it..."											>> $cmdFile
# 			echo "rm -f $dstDir/xyz/$tile.xyz $dstDir/grd/$tile.grd "								>> $cmdFile
# 			echo "else"																				>> $cmdFile
# 			echo "echo > /dev/null"																	>> $cmdFile
# 			echo "fi"																				>> $cmdFile



# cleanup run from inside our processing script
			echo "rm -rf $xyz $xyzMedianFiltered $grd"	>> $cmdFile

# run the script
			chmod a+x $cmdFile
			bash $cmdFile > $dstDir/logs/$tile".log" 2>&1 &

# script is medium weight jobs that we can run a few at a time, but do not overwhelm the machine
			((jobsRunning=$jobsRunning+1));
# echo "launched job #"$jobsRunning" GLAS tile $tile"
			if [ $jobsRunning -ge `sysctl hw.activecpu | awk '{print $2 -0}'` ]; then
# echo "$jobsRunning jobs running, waiting for all to finish before launching another batch..."
				wait;wait;wait
				purge
				((jobsRunning=0));
			fi
		done
	done

# We should have used all the data in the NSIDC file...
	echo "Please check this to see if there is something fishy about the input data. Remainder of points should be bathymetry..."
	echo "	e.g. check if the range of elevation (last column) is <0/0> meaning the satellite measured only sea level..."
	minmax -bi3 $NSIDC_remainder > $dstDir/logs/$tile".log" 2>&1
	wait;wait;wait
	purge
done
wait;wait;wait
purge

# make KMZ of all our tiles
(../dir2kmz.sh $dstDir/grd $dstDir/kmz  > $dstDir/logs/"dir2kmz.log" 2>&1)&

# cleanup
# rm -rf $dstDir/tmp
exit
