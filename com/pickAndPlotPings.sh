#!/bin/bash -x

if [ "$#" != "7" ] ; then
	echo "usage: `basename $0` name resolution west east south north pingFile "
	echo "  example: `basename $0` azores 300e -35 -25 30 40 /Volumes/RAID/doNotBackup/srtm15_plus/debug/huge.xyzi "
	exit
fi

name="$1";		shift
resolution=$1;	shift
w="$1";			shift
e="$1";			shift
s="$1";			shift
n="$1";			shift
srcPings="$1";	shift

# == Pick out pings of interest and make a KMZ ==

# median filter to a (typically) 300m grid, --PIXEL-- registered
# turn ASCII into a netCDF grid, , --PIXEL-- registered

cat $srcPings | \
	../bin/selectAndSort /dev/stdin /dev/stdout /dev/null $w $e $s $n | \
	blockmedian -R$w/$e/$s/$n -I$resolution -V -C -F | \
	xyz2grd -R$w/$e/$s/$n -I$resolution -V -F -G$name.pings.grd

# pray for more pings...
#
# in meantime use SRTM15+ data with pings and predicted all mixed, --PIXEL-- registered.

srtm15_plus="/Volumes/RAID/doNotBackup/srtm15/world.grd"
srtm15_plus="/Volumes/RAID/doNotBackup/srtm15/land.grd"

grdcut -R$w/$e/$s/$n -fg $srtm15_plus -V -G$name.srtm15.grd
grdsample $name.srtm15.grd -G$name.srtm15.300m.grd -I$resolution -V -fg -F

# make the KMZ file for Google Earth
#
# --GDAL Required--
grd2kmz.sh $name.pings.grd .		&
grd2kmz.sh $name.srtm15.grd .		&
grd2kmz.sh $name.srtm15.300m.grd .	&
wait
