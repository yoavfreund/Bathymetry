#! /bin/csh

# IMPORTANT!
#
# Smith and Sandwell img file format does NOT go above latitudes ~80 degrees
#
# If cm file has latitudes higher than about +/-80 those pings will be lost.
#
# As a workaround, use grid that converts img file to grd file and pastes it over IBCAO
#	in other words use "surface" on output of img2grd and grdpaste with IBCAO grid

if [ "$#" != "2" ] ; then
	echo "usage: `basename $0` cmFile predictedTopography "
	echo "  example: `basename $0` NOAA_geodas.cm /Volumes/RAID/doNotBackup/srtm15_plus/debug/predictedIBCAO.unmasked.grd"
	exit
fi

cmFile=$1;		shift
predicted=$1;	shift

t=$cmFile.timeStamp
xyzufip=$cmFile.xyzufip

# grdtrack must have x,y in first 2 cols...
# grdtrack must have x,y in same principle value (0-360 or +/-180) as grid being sampled
#
# save column 1 (aka time), then slice column 1 off and convert longitude to +/-180
# 	and -then- sample predicted from grid
# paste pieces back together

cut -f 1 -d ' ' $cmFile > $t
awkString='{x=$2;if(x>180)x=x-360;printf "%.7lf %s %s %s %s %s\n",x,$3,$4,$5,$6,$7}'
awk "$awkString" < $cmFile | grdtrack -G$predicted -V > $xyzufip
paste $t $xyzufip > $cmFile.corrected

# make versions with one extra column  of difference between ping and predicted depth

awk '{print $0,$4-$8}' < $cmFile.corrected	> $cmFile.corrected.diff
awk '{if ($6 == 9999) {print $0 } }'		< $cmFile.corrected.diff > $cmFile.corrected.diff.bad
awk '{if ($6 != 9999) {print $0 } }'		< $cmFile.corrected.diff > $cmFile.corrected.diff.good

# make histograms

histogramCmFile.sh NOAA_geodas.cm.corrected.diff "All Corrected NOAA_geodas"
histogramCmFile.sh NOAA_geodas.cm.corrected.diff.good "Bad Pings in Corrected NOAA_geodas"
histogramCmFile.sh NOAA_geodas.cm.corrected.diff.bad "Good Pings in Corrected NOAA_geodas"

# clean up

$t $xyzufip
exit

