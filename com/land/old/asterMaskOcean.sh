#!/bin/bash

# gmtset GMT_VERBOSE = quiet
# gmtset VERBOSE = FALSE

# source ../../demPaths.sh

if [ "$#" != "3" ] ; then
	echo "usage: `basename $0` asterDir cgiarDir outputDir"
	echo "  example: `basename $0` /Volumes/RAID/doNotBackup/srtm15/asterDownsampledTo6c /Volumes/RAID/doNotBackup/srtm15/cgiarDownsampledTo6c /tmp "
	exit
fi

asterDir="$1"/;	shift
cgiarDir="$1"/;	shift
dstDir="$1"/;	shift

mkdir -p $dstDir $dstDir/grd $dstDir/xyz $dstDir/tmp
cmdFile="$dstDir/tmp/"`basename -s .sh $0`".cmd"
logFile="$dstDir/tmp/"`basename -s .sh $0`".log"
rm -f $cmdFile $logFile; date > $logFile

echo "`date`: Mask ASTER with CGIAR tiles."
echo "	-NOT- making empty grids for tiles without any land..."

firstGrd=`ls -1 $asterDir/grd/*.grd | head -1` 2>&1
tileWidth=` grdinfo $firstGrd -C 2>/dev/null | awk '{print $3-$2}'`
tileHeight=`grdinfo $firstGrd -C 2>/dev/null | awk '{print $5-$4}'`

echo "#!/bin/bash " > $cmdFile
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
		echo "land tile " $tile >> $logFile 2>&1

		if [ -f $asterDir/xyz/$tile.xyz ] ; then
			echo "( "	>> $cmdFile
			# Use CGIAR land mask where we have CGIAR, otherwise use GMT (GSHHS) landmask
			if [ -f $cgiarDir/grd/$tile.grd ] ; then
				echo " grdmath 1 $cgiarDir/grd/$tile.grd OR $asterDir/grd/$tile.grd MUL = $dstDir/grd/$tile.grd"	>> $cmdFile
			else
				echo " grdLandMask_wrapper.sh $asterDir/grd/$tile.grd $dstDir/grd/$tile.grd NaN/1; "	>> $cmdFile
			fi
			echo " grd2xyz -S $dstDir/grd/$tile.grd -bo3 > $dstDir/xyz/$tile.xyz ;"	>> $cmdFile
			echo " ) & "	>> $cmdFile
			((jobsRunning=$jobsRunning+1));
		fi

		if [ $jobsRunning -gt `sysctl hw.activecpu | awk '{print $2 -1}'` ]; then
			echo "wait "															>> $cmdFile
			((jobsRunning=0));
		fi
	done
done

# make KMZ of all our tiles
# echo "../dir2kmz.sh $dstDir/grd $dstDir/kmz" >> $cmdFile

chmod a+x $cmdFile
$cmdFile >> $logFile 2>&1
# rm -f $cmdFile

date  >> $logFile 2>&1
echo done!
