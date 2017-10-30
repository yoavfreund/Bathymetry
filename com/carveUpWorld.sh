#!/bin/bash

if [ "$#" != "4" ] ; then
	echo "usage: `basename $0` tileWidth (deg) tileHeight (deg) srcFile dstDir"
	echo "  example: `basename $0` 15 15 /Volumes/RAID/doNotBackup/srtm15_plus/world/land.bath.grd /Volumes/RAID/doNotBackup/srtm15_plus/world/grd "
	exit
fi
date

tileWidth=$1;	shift
tileHeight=$1;	shift
srcFile="$1";	shift
dstDir="$1"/;	shift

mkdir -p $dstDir

for (( lat=90; lat>=-90+tileHeight; lat=lat-$tileHeight ))
do
	for (( lon=-180; lon<=180-$tileWidth; lon=lon+$tileWidth ))
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
		#pad n to 2 digits
		if [ ${#lat2} == 1 ]; then
			lat2="0"$lat2
		fi

		#file name of this tile:
		tileName="$eorw$lon2$nors$lat2"
		w=$lon;let e=lon+$tileWidth;
		n=$lat;let s=lat-$tileHeight;
		region="-R/$w/$e/$s/$n"

		echo "tile " $tileName $region
		grdcut $srcFile -G$dstDir/$tileName.grd $region > /dev/null 2>&1 &

		# do NOT launch 288 jobs at once. But they are light so maybe two 2 per thread
		((jobsRunning=`ps -C | grep grdcut | grep -v grep | wc -l`))
		while [ $jobsRunning -ge `sysctl hw.activecpu | awk '{print $2 *2}'` ]
		do
			echo "$jobsRunning grdcut jobs are running..."
			sleep 10
			((jobsRunning=`ps -C | grep grdcut | grep -v grep | wc -l`))
		done

	done
done
wait
wait
date
