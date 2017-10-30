#!/bin/bash -x

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
		mv -f $tmpDir/$stem.hgt $dstDir
		rm $tmpDir/*
	done
done
