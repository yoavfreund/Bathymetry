#!/bin/bash
set -u
echo "`date`: starting bathymetry/$0 $@ "
purge
source ../../demPaths.sh

if [ "$#" != "2" ] ; then
	echo "usage: `basename $0` landDir dstDir"
	echo "  example: `basename $0` /geosat2/srtm15_data/land /geosat2/srtm15_data/topo "
	exit
fi

landDir="$1"/;	shift
topoDir="$1"/;	shift

#
# output data: topo grid with both land and bathymetry
#
topo=$topoDir/world
#
# input data : SRTM land grid (just stem, not stem.grd to keep code clear)...
# input data : edited sonar depths in "CM" format pointed to by demPaths.sh...
#
land=$landDir/land
dry=$landDir/dry
#
# keep code readable with some "aliases"
#
debugDir=$topoDir/debug
mkdir -p $topoDir $debugDir
logFile="/dev/stdout"
#
# logFile=$debugDir/"`basename $0`.log"
# rm -f $logFile; echo "`date`: $0 starting" > $logFile
# various tmp files
#
ping=$debugDir/ping
pred=$debugDir/predictedIBCAO
bath=$debugDir/polished
huge=$debugDir/huge
zero=$debugDir/zero
wet=$debugDir/wet
#
# surfaceOpts set in ../../demPaths.sh
#
# Convert the img file to predicted.xyz
#
if [ 6 == 6 ]; then
#
# Altimetry is used up to 70 N, also convert Altimetry data from 0/360 to +/-180.
#
# Block median filter Altimetry implicitly switching Altimetry
# grid from pixel to node registered.
#
	rm -f $pred.xyz
        ls -l $arcticXyz
	../../bin/img2web $img -90 $maxPred 0 360 1 | awk '{tmp=$1;if(tmp>180)tmp=tmp-360;printf "%.7lf %s %s\n",tmp,$2,$3}'  > $pred.xyz
fi
#
# interpolate predicted (and IBCAO) grid onto the final resolution grid
# -and- convert them from pixel to node registered
#
if [ 6 == 6 ]; then
#
#
# Use  "C" option on blockmedian because if there is a wild point that happens to have
# median value we do not want to use its location. If there is no wild point and good
# points do cluster in location, then the median of the location would make sense, as
# would loc of pt with median value (-Q). Our goal is to find the most representative
# depth of  block, which is the median, and we'll use that value at center of block.
# FIXME: tell OSX to free up unused memory and avoid swapping
#
	purge
#
# a 1 means wet, NaN means not wet, aka dry. This is slow, run in parallel"
#
       echo $land.grd
       echo $wet.grd
       grdlandmask	-R$land.grd -Df+ -N1/Nan -G$wet.grd > /dev/null 2>&1 
#
#   changed to 30 arcseconds
#
 	blockmedian $pred.xyz -V -fg -R-180/180/-90/90 -bod -I30c > $pred.median.xyz
        echo $pred.median.xyz $arcticXyz
 	surface_pred_arctic.csh $pred.median.xyz $arcticXyz $pred.unmasked.grd $surfaceOpts
 	wait;wait;
 	grdmath -V -fg $wet.grd $pred.unmasked.grd MUL = $pred.grd
fi
#
# FIXME: at this point we have -81 to +90 latitude covered in +/-180 longitude format.
# FIXME: still need to do something for -90 to -81 (maybe).
#
# create difference of measured (pings) and predicted (altimetry data)
#
#	median filter pings
#	determine altimetry value at ping location
#       difference ping and altimetry values (where there are pings)
# 	surface difference (everywhere)
# 	Hack in  zero over land and also data voids more than 10 km,
#	huge decrease in time to convergence of surface
#	need to block median that to keep surface from moaning about duplicate nodes...
#
# Hack in max delta between predicted and pings
# sigh: why is there no abs in awk...
#
((maxD=800))
awkString='{d=$3-$5; if((d<0?-d:d)<'$maxD') printf "%.16lg %.16lg %.16lg\n", $1, $2, $3-$5}'
#
if [ 6 == 6 ]; then
#
#  fill land areas and ocean data voids with zero
#
lowResZero=4m
xyz2grd $huge.xyzi -Rd -I$lowResZero -An -Gnum.grd -N0 -V
grdfilter num.grd -D3 -Fg20 -Ghit.grd -V
grdmath hit.grd 1 GE 1 NAN = $zero.grd
grd2xyz $zero.grd -S > $zero.xyz
#
fi
#
if [ 6 == 6 ]; then
#
# FIXME: tell OSX to free up unused memory and avoid swapping
#
purge
#
	../../bin/medianId  -V -fg -R$land.grd -C -bo4 $huge.xyzi > $ping.xyzi
#
	grdtrack $ping.xyzi -bi4 -V -fg -R$land.grd -G$pred.grd -S | tee $ping.xyzip 	|\
	awk "$awkString"					  | tee $ping.xyd	|\
	cat - $zero.xyz						>  $ping.xyd.landZeros 
#
	blockmedian $ping.xyd.landZeros -V -fg -R$land.grd -C -bo3 > $ping.xyd.landZeros.median
#
# FIXME: tell OSX to free up unused memory and avoid swapping
#
	purge
	surface_tile.csh $ping.xyd.landZeros.median $ping.xyd.grd $surfaceOpts
#
# add actual-predicted (diff) to predicted to get actual, where we have actual,
# but more importantly, to interpolate predicted data near the pings.
#
# basically this is result we want, (aka "polished bathymetry"),
#
	grdmath -V -fg $pred.grd $ping.xyd.grd	ADD = $bath.unmasked.grd
#
# mask bathy with "wet", we don't want any bathy nodes that are on land...
#
  	wait;
	grdmath -V -fg $wet.grd  $bath.unmasked.grd MUL = $bath.grd
#
# still need to place land on top of it...
#
	grdmath -V -fg $land.grd $bath.grd AND = $topo.grd
fi

# done.
if [ 6 == 9 ]; then
#
# make reasonable size tiles (15x15 deg) and then make kmz from them
#
bash ../carveUpWorld.sh 15 15 $topo.grd $topoDir/grd > $debugDir/carveUpWorld.log 2>&1
#
# possibly remove debug dir...
# rm -f $debugDir
#
# all done!
echo "`date`: finished bathymetry/$0 $@ "

echo "find pings that are on land (probably lakes) and check if the depth is reasonable"
grdtrack $ping.xyzip -V -fg -R$land.grd -G$land.grd -S > $debugDir/pingsOnLand.xyziph
((numLandPings=`wc -l $debugDir/pingsOnLand.xyziph | awk {'print $1'}`))
echo "$numLandPings land pings found"
if [ $numLandPings -gt 0 ]; then
	cat $debugDir/pingsOnLand.xyziph |\
		awk '{ printf "%s %.16lg %.16lg\n", $0, $3-$5, $3-$6 }' > $debugDir/pingsOnLand.xyziphdD
	# xyz2grd $debugDir/pingsOnLand.xyziphdD	-V 	-fg	-R$land.grd	-G$debugDir/pingsOnLand.xyziph.grd;
	# FIXME: need to sort the difference and see
fi

echo "`date`: pings on land checking done!"
fi
exit
