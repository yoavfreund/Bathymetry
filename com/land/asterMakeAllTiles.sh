#!/bin/bash

set -u
echo "`date`: starting land/$0 $@ "
purge
source ../../demPaths.sh

echo "`date`: Create ASTER tiles..."

	# Use  "C" option on blockmedian because if there is a wild point that happens to have
	# median value we do not want to use its location. If there is no wild point and good
	# points do cluster in location, then the median of the location would make sense, as
	# would loc of pt with median value (-Q). Our goal is to find the most representative
	# depth of  block, which is the median, and we'll use that value at center of block.

if [ "$#" != "5" ] ; then
	echo "usage: `basename $0` resolution tileWidth tileHeight demDir dstDir"
	echo "  example: `basename $0` 6c 15 15 /Volumes/srtm15/DEM/ASTER/World /Volumes/srtm15/doNotBackup/asterDownsampledTo6c "
	echo "  example: `basename $0` 6c 15 15 /Volumes/RAID/DEM/ASTER/World /Volumes/RAID/doNotBackup//srtm15/asterDownsampledTo6c "
	exit
fi

resolution=$1;	shift
tileWidth=$1;	shift
tileHeight=$1;	shift
srcDir="$1"/;	shift
dstDir="$1"/;	shift

mkdir -p $dstDir $dstDir/grd $dstDir/xyz $dstDir/tmp $dstDir/logs

# Outer pair of for loops gets dimensions for new, lower resolution, tile
# ASTER filenames are opposite of CGIAR names, 2 digit lat first then 3 digit lon
# 	also 1 degree tiles for ASTER vs 5 for CGIAR

stem=`basename -s .sh $0`
cmdFile=$dstDir/$stem.cmd
echo "#!/bin/bash " > $cmdFile

for (( lat=90; lat>=-90+tileHeight; lat=lat-$tileHeight ))
do
# 	if [[ "$lat" -le -15 ||  "$lat" -gt 15 ]]; then
# 		continue
# 	fi
	for (( lon=-180; lon<=180-$tileWidth; lon=lon+$tileWidth ))
	do
		((jobsRunning=0));
# if [[ "$lon" -le 60 ||  "$lon" -gt 90 ]]; then
# 		continue
# fi
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
		tile="$eorw$lon2$nors$lat2"
# 		echo "writing cmdFile for ASTER tile " $tile

		/bin/rm -f $dstDir/tmp/$tile.xyz $dstDir/tmp/$tile.cmd
		echo "/bin/rm -f $dstDir/tmp/$stem.$tile.xyz" >> $dstDir/tmp/$tile.cmd
		echo "touch $dstDir/tmp/$stem.$tile.xyz" >> $dstDir/tmp/$tile.cmd
		foundFileCnt=0;
		#we know aster tiles are in 1 deg tiles, just get the ones we assume will be there
		for (( i=$lon; i<lon+tileWidth; i=i+1 ))
		do
			#echo "outer $i"
			for (( j=$lat-1; j >= lat-tileHeight; j=j-1 ))
			do
				#echo "inner $j"

				#pad values with 0s to three digits and determine e or w and n or s
				#e or w
				if [ "$i" -lt 0 ]; then
					m2=`echo $i | awk '{print substr($0, 2)}'`
					eorw="W"
				else
					m2=$i
					eorw="E"
				fi
				#pad i to 3 digits
				if [ ${#m2} == 2 ]; then
					m2="0"$m2
				elif [ ${#m2} == 1 ]; then
					m2="00"$m2
				fi

				#n or s
				if [ "$j" -lt 0 ]; then
					n2=`echo $j | awk '{print substr($0, 2)}'`
					nors="S"
				else
					n2=$j
					nors="N"
				fi
				#pad j to 2 digits
				if [ ${#n2} == 1 ]; then
					n2="0"$n2
				fi

				fileName="$nors$n2$eorw$m2.hgt"

				#if this ASTER tile exists, stitch it to the output
				if [ -f $srcDir$fileName ] ; then
					((foundFileCnt=$foundFileCnt+1));
					((e=`expr $i+1`));
					((n=`expr $j+1`));
					# byte swap the binary file, convert it to a grid
					# convert grid to xyz because median filter needs xyz triplets,
					# e.g blockmedian can -NOT- read -ZTLh

					echo "( " \
						" xyz2grd -R$i/$e/$j/$n -I1c $srcDir$nors$n2$eorw$m2.hgt -ZTLh -S | xyz2grd -R$i/$e/$j/$n -I1c -G$dstDir/tmp/$nors$n2$eorw$m2.grd -ZTLh -N-9999 ; " \
						" grd2xyz $dstDir/tmp/$nors$n2$eorw$m2.grd -S -bo3 | blockmedian -C -R$i/$e/$j/$n -I$resolution -bi3 -bo3 > $dstDir/tmp/$stem.$tile.$i.$j.xyz ;" \
						" /bin/rm -f $dstDir/tmp/$nors$n2$eorw$m2.grd ) &" >> $dstDir/tmp/$tile.cmd
					((jobsRunning=$jobsRunning+1));
					if [ $jobsRunning -ge `sysctl hw.activecpu | awk '{print $2 -1}'` ]; then
						echo "wait" >> $dstDir/tmp/$tile.cmd
						((jobsRunning=0));
					fi
# 				else
# 					echo "$fileName: Not Found"
				fi
			done
		done
		if [[ "$foundFileCnt" -gt 0 ]]; then
			echo "wait; wait; wait; purge; cat $dstDir/tmp/$stem.$tile.*.*.xyz >> $dstDir/tmp/$stem.$tile.xyz; /bin/rm -f $dstDir/tmp/$stem.$tile.*.*.xyz" >> $dstDir/tmp/$tile.cmd
		else
			rm $dstDir/tmp/$tile.cmd
		fi

		#finished compiling list of ASTER xyz files, block median to $resolution
		if [ -f $dstDir/tmp/$tile.cmd ] ; then
			((w=`expr $lon`));
			((e=`expr $lon+$tileWidth`));
			((s=`expr $lat-tileHeight`));
			((n=`expr $lat`));
			echo "cat $dstDir/tmp/$stem.$tile.xyz | blockmedian -C -R$w/$e/$s/$n -I$resolution -bi3 -bo3 > $dstDir/xyz/$tile.xyz ;" >> $dstDir/tmp/$tile.cmd
			echo "xyz2grd $dstDir/xyz/$tile.xyz -bi3 -R$w/$e/$s/$n -I$resolution -G$dstDir/grd/$tile.grd ;" >> $dstDir/tmp/$tile.cmd
# FIXME: use grdlandmask or not...
# 			echo "grdLandMask_wrapper.sh $dstDir/grd/$tile.grd $dstDir/grd/$tile.grd NaN/1; " >> $dstDir/tmp/$tile.cmd
			echo "grd2xyz -S $dstDir/grd/$tile.grd -bo3 > $dstDir/xyz/$tile.xyz ;" >> $dstDir/tmp/$tile.cmd
			echo "/bin/rm -f  $dstDir/tmp/$stem.$tile.xyz " >> $dstDir/tmp/$tile.cmd
# echo "../grd2kmz.sh $dstDir/grd/$tile.grd $dstDir/kmz &" >> $dstDir/tmp/$tile.cmd
			echo "bash -x $dstDir/tmp/$tile.cmd > $dstDir/logs/$tile".log" 2>&1 " >> $cmdFile
#  			cat $dstDir/tmp/$tile.cmd >> $cmdFile
# 			/bin/rm -f $dstDir/tmp/$tile.cmd
		else
			echo "/bin/rm -f  $dstDir/tmp/$stem.$tile.xyz $dstDir/tmp/$stem.$tile.*.*.xyz " >> $cmdFile
		fi
		# some HGT files exist, but are empty. We don't want any empty tiles.
		echo "if [ -f $dstDir/xyz/$tile.xyz ]; then" >> $cmdFile
			echo "	if [ \`ls -al $dstDir/xyz/$tile.xyz | awk '{ print \$5 }'\` -le 0 ]; then" >> $cmdFile
				echo "		/bin/rm -f  $dstDir/grd/$tile.grd $dstDir/xyz/$tile.xyz " >> $cmdFile
			echo "	fi" >> $cmdFile
		echo "else" >> $cmdFile
		echo "	/bin/rm -f  $dstDir/grd/$tile.grd $dstDir/xyz/$tile.xyz " >> $cmdFile
		echo "fi" >> $cmdFile
		echo "" >> $cmdFile
	done
done

echo "" >> $cmdFile
chmod a+x $cmdFile
/bin/bash -x $cmdFile > $dstDir/logs/"`basename $0`.cmdFile.log" 2>&1

# make KMZ of all our tiles
(../dir2kmz.sh $dstDir/grd $dstDir/kmz  > $dstDir/logs/"dir2kmz.log" 2>&1)&

# cleanup
# rm -rf $dstDir/tmp
