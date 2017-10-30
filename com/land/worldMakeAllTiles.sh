#!/bin/bash
set -u
echo "`date`: starting land/$0 $@ "
purge
source ../../demPaths.sh

if [ "$#" != "4" ] ; then
	echo "usage: `basename $0` resolution tileWidth tileHeight outputDir"
	echo "  example: `basename $0` 6c 15 15 /Volumes/RAID/doNotBackup/srtm15 "
	exit
fi

resolution=$1;	shift
tileWidth=$1;	shift
tileHeight=$1;	shift
dstDir="$1"/;	shift

# surfaceOpts set in ../../demPaths.sh

glasDir="$dstDir"/glasDownsampledTo6c/
cgiarDir="$dstDir"/cgiarDownsampledTo6c/
asterDir="$dstDir"/asterDownsampledTo6c/

mkdir -p $dstDir $dstDir/grd $dstDir/unmaskedGrd $dstDir/tmp
cmdFile="$dstDir/"`basename -s .sh $0`".cmd"
rm -f $cmdFile
# logFile="/dev/stdout"
mkdir -p $dstDir/log
logFile="$dstDir/log/"`basename -s .sh $0`".log"
rm -f $logFile; echo "`date`: $0 starting" > $logFile

if [ 6 == 6 ]; then
	echo "`date`: Create a global dry mask to trim land and for later use in bathymetry..."
	# a 1 means dry, NaN means not dry, aka wet. This is slow, run in parallel"
	grdlandmask	-Rd -I$resolution -Df+ -NNan/1 -G$dstDir/dry.grd > $dstDir/log/grdlandmask.log 2>&1 &
fi

# downsample all DEM to roughly same intermediate resolution,
# because otherwise the DEM with finest pitch swamps other DEM during block median step
intermediateResolution=6c
# FIXME: remove hard code 6c for intermediate resolution
# FIXME: we should automatically pick something like $finalResolution/3 or such,
# FIXME: but GMT moans if tile width -and- height are not exact multiple of resolution...
#
# make intermediate resolution land
# These 3 steps will take about 8 hours on a 2011 era MacBook Pro desktop with 16 GB ram...
if [ 6 == 6 ]; then
	echo "`date`: Create intermediate resolution land data at $intermediateResolution ..."
	bash -x cgiarMakeAllTiles.sh $intermediateResolution $tileWidth $tileHeight $cgiarDEM	$cgiarDir	>> $logFile 2>&1
	bash -x asterMakeAllTiles.sh $intermediateResolution $tileWidth $tileHeight $asterDEM	$asterDir	>> $logFile 2>&1
	bash -x glasMakeAllTiles.sh  $intermediateResolution $tileWidth $tileHeight $glasDEM 	$glasDir	>> $logFile 2>&1
fi

echo "`date`: blockmedian GLAS, masked ASTER, and CGIAR together at $resolution."
echo "	making empty grids for tiles without any land..."
#
# CGIAR coverage is +/-60NS, +/-180EW
# ASTER coverage is +/-83NS, +/-180EW
# GLAS  coverage is -60 to -90NS, +/-180EW (Antarctica)
# GLAS  coverage is +60N to 90NS,  -75-0EW (Greenland)
echo "#!/bin/bash "																> $cmdFile
((jobsRunning=0));
for (( i=-180; i<180; i=i+$tileWidth ))
do
	for (( j=90; j>-90; j=j-$tileHeight ))
	do
		#pad values with 0s to three digits and determine e or w and n or s
		if [ "$i" -lt 0 ]; then i2=`echo $i | awk '{print substr($0, 2)}'` ; eorw="w" ; else i2=$i ; eorw="e" ; fi
		if [ ${#i2} == 2 ]; then i2="0"$i2 ; elif [ ${#i2} == 1 ]; then i2="00"$i2 ; fi
		if [ "$j" -lt 0 ]; then j2=`echo $j | awk '{print substr($0, 2)}'` ; nors="s" ; else j2=$j ; nors="n" ; fi
		if [ ${#j2} == 1 ]; then j2="0"$j2 ; fi
		tile="$eorw""$i2""$nors""$j2"
		echo "land tile " $tile	>> $logFile 2>&1

		# find all the tiles that have data in this region
		tmpFile=$dstDir/tmp/$tile.unmasked.xyz
		echo "( rm -f $tmpFile; touch $tmpFile ;  "							>> $cmdFile
		for (( n=0; n<3; n=n+1 ))
		do
			case $n in
				0) dir=$asterDir									;;
				1) dir=$cgiarDir 									;;
				2) dir=$glasDir
# FIXME: GLAS data isn't good enough to use
					continue										;;
# FIXME: GLAS is all we have in ANT
# 					if (( "$j" > -90+$tileHeight)) ; then continue ; fi	;;
			esac
			if [ -f $dir/xyz/$tile.xyz ] ; then
				echo "cat $dir/xyz/$tile.xyz >> $tmpFile ; "				>> $cmdFile
			fi
		done

		# make every tile, even if it's empty.
		# e.g. w150s30 (15x15 deg tile) has no land at all
		((w=`expr $i`)) ; ((e=`expr $i+$tileWidth`)) ; ((s=`expr $j-tileHeight`)) ; ((n=`expr $j`));
		echo "blockmedian -bi3 $tmpFile -R/$w/$e/$s/$n -I$resolution -Q -bo3 | "	>> $cmdFile
		echo "xyz2grd -bi3 -R/$w/$e/$s/$n -I$resolution -G$dstDir/unmaskedGrd/$tile.grd;"	>> $cmdFile
		echo "rm -f $tmpFile ; ) & "										>> $cmdFile

		((jobsRunning=$jobsRunning+1));
# 		echo "launched job #"$jobsRunning
		if [ $jobsRunning -gt `sysctl hw.activecpu | awk '{print $2 -1}'` ]; then
# 			echo "echo launched paste tile job #"$jobsRunning", waiting..."	>> $cmdFile
			echo "wait "													>> $cmdFile
			((jobsRunning=0));
		fi

	done
done

chmod a+x	$cmdFile
bash -x		$cmdFile	> $dstDir/log/cmdFile.log 2>&1
rm -f		$cmdFile

# wait for grdlandmask to finish, then make land pings for use in bathymetry polish steps
wait; wait; wait
echo "`date`: ...global dry mask comlete"

echo "`date`: Paste all the tiles together into a huge global file..."
bash -x ../pasteWorldTogether.sh $dstDir/unmaskedGrd $dstDir/land.unmasked.grd		>> $dstDir/log/pasteWorldTogether.log 2>&1

# mask wet areas out of land...
echo "`date`: Use grdlandmask to mask wet areas from SRTM, ASTER, and GLAS land data"
grdmath -V -fg $dstDir/dry.grd $dstDir/land.unmasked.grd	MUL		= $dstDir/land.grd

# make reasonable size -MASKED- tiles (15x15 deg) and  make kmz of them
bash ../carveUpWorld.sh $tileWidth $tileHeight $dstDir/land.grd $dstDir/grd			>> $dstDir/log/carveUpWorld.log 2>&1

# echo "`date`: Make kmz of combined tiles, but NOT huge global grid created from them..."
(bash -x ../dir2kmz.sh $dstDir/grd $dstDir/kmz										>> $dstDir/log/dir2kmz.log 2>&1)&

echo "`date`: finished land/$0 $@ "
