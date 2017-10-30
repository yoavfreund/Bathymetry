#!/bin/bash

if [ "$#" != "2" ] ; then
	echo "usage: `basename $0` srcDir dstFilePath"
	echo "  example: `basename $0` /Volumes/RAID/doNotBackup/srtm15/grd /Volumes/RAID/doNotBackup/srtm15/land.grd"
	exit
fi

srcDir=$1;		shift
grdPath="$1";	shift
dstDir=`dirname $grdPath`

firstGrd=`ls -1 $srcDir/*.grd | head -1` 2>&1
tileWidth=` grdinfo $firstGrd -C 2>/dev/null | awk '{print $3-$2}'`
tileHeight=`grdinfo $firstGrd -C 2>/dev/null | awk '{print $5-$4}'`
echo "`date`: paste tiles along into a $tileHeight degree tall horizontal strip..."

tmpDir="$dstDir/`basename -s .sh $0`.tmp.$RANDOM"
mkdir -p $tmpDir
pasteTiles="$tmpDir/pasteTiles.cmd"
rm -f $pasteTiles
echo "#!/bin/bash " > $pasteTiles

echo "purge"			>> $pasteTiles

for (( j=90; j>-90; j=j-$tileHeight ))
do
	if [ "$j" -lt 0 ]; then j2=`echo $j | awk '{print substr($0, 2)}'` ; nors="s" ; else j2=$j ; nors="n" ; fi
	if [ ${#j2} == 1 ]; then j2="0"$j2 ; fi
	echo "( "	>> $pasteTiles
	echo "cp -f $srcDir/w180"$nors""$j2".grd $tmpDir/"$nors""$j2".grd; "	>> $pasteTiles
		for (( i=-180+$tileWidth; i<180; i=i+$tileWidth ))
		do
			if [ "$i" -lt 0 ]; then i2=`echo $i | awk '{print substr($0, 2)}'` ; eorw="w" ; else i2=$i ; eorw="e" ; fi
			if [ ${#i2} == 2 ]; then i2="0"$i2 ; elif [ ${#i2} == 1 ]; then i2="00"$i2 ; fi
			tile="$eorw""$i2""$nors""$j2"
	# 		echo "world tile " $tile
			echo "grdpaste $tmpDir/"$nors""$j2".grd $srcDir/$tile.grd -G$tmpDir/tmp"$nors""$j2".grd -fg;"	>> $pasteTiles
			echo "mv $tmpDir/tmp"$nors""$j2".grd $tmpDir/"$nors""$j2".grd ;"	>> $pasteTiles
		done
	echo ") & "			>> $pasteTiles
done
echo "wait;wait;wait"	>> $pasteTiles
echo "purge"			>> $pasteTiles

echo "`date`: paste vertical strips along latitudes into single global grid..."
echo "mv -f $tmpDir/n90.grd $grdPath ; "	>> $pasteTiles
for (( j=90-$tileHeight; j>-90; j=j-$tileHeight ))
do
	if [ "$j" -lt 0 ]; then j2=`echo $j | awk '{print substr($0, 2)}'` ; nors="s" ; else j2=$j ; nors="n" ; fi
	if [ ${#j2} == 1 ]; then j2="0"$j2 ; fi
	tile="$nors""$j2"
# 	echo "world stripe " $tile
	echo "grdpaste $grdPath $tmpDir/$tile.grd -G$tmpDir/tmpland.grd -fg;"	>> $pasteTiles
	echo "purge;"	>> $pasteTiles
	echo "mv $tmpDir/tmpland.grd $grdPath ; rm $tmpDir/$tile.grd"	>> $pasteTiles
done
echo "wait;wait;wait"	>> $pasteTiles
echo "purge;"	>> $pasteTiles

echo "`date`: make sure global grid is clean using grdedit..."
echo "grdedit -R/-180/180/-90/90 $grdPath -S  -fg"	>> $pasteTiles
# FIXME: grdedit needs 3 passes to run clean for some reason
echo "grdedit -R/-180/180/-90/90 $grdPath -S  -fg"	>> $pasteTiles
echo "grdedit -R/-180/180/-90/90 $grdPath -S  -fg"	>> $pasteTiles

chmod a+x $pasteTiles
$pasteTiles	> $tmpDir/"`basename -s .sh $0`.log" 2>&1
rm -rf $tmpDir
exit
