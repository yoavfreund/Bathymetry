#!/bin/bash -x

# ASTER data is in a crazy file: the data is pixel registered but has an extra pixel
#
# The reason for this is that they started in node registered (e.g. 3601x3601) switched
# to node registered, but kept the same number of pixels; which is one too many.
#
# This would be a problem if we planned on using the 1c data, but we always downsample to
# 6c or even 15c grids and the half pixel horizontal error is noise...

# convert GEOTIFF to SRTM HGT format (no header, 3601x3601 2 byte integers) using GDAL

srcDir=/Volumes/RAID/DEM/ASTGTM_V2
dstDir=/Volumes/RAID/DEM/ASTGTM_V2_HGT;		mkdir -p $dstDir
tmpDir=/tmp/foobar;							rm -rf $tmpDir

for tile in  $srcDir/UNIT_*; do
	echo Processing tile $tile;
	for f in $tile/*.zip; do
		echo Processing file $f;
		unzip $f -d $tmpDir/
		g=`basename $tmpDir/*_dem.tif`
		h="${g%%_dem.tif}"
		stem="${h#*_}"
		gdal_translate -of SRTMHGT $tmpDir/$g $tmpDir/$stem.hgt
# gdalinfo $tmpDir/$stem.hgt | tail -8
		mv -f $tmpDir/$stem.hgt $dstDir
		rm $tmpDir/*
	done
done
