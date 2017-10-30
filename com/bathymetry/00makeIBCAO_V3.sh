#!/bin/bash
set -u
echo "`date`: starting bathymetry/$0 $@ "
purge
source ../../demPaths.sh

# surfaceOpts set in ../../demPaths.sh
#
#   sandwell's method for making IBCAO
#
echo $arcticGrd
echo $arcticXyz
grd2xyz	$arcticGrd -S -V	| blockmedian -R-180/180/65/90 -fg -I1m/.5m > $arcticXyz

exit
