#!/bin/sh
gmtset VERBOSE = TRUE

# This seems obvious, except you are assuming KML files are DEM. They are in fact just
# photographs draped over topography. The trick to turning a grid into a KML is
# visualizing a grid as a descriptive image.
#
# For example, a ping map image is very different than a contour plot of a DEM.
#
# But once you have visualized the grid, NASA image2qtree does a nice job; albeit slowly.

if [ "$#" != "2" ] ; then
	echo "usage: `basename $0` srcDir dstDir"
    echo "  example: /Path/To/File.grd . "
    echo "  example: /Path/To/File.grd /tmp/foo/ "
    exit
fi

srcGrd=$1; shift
# cp $srcGrd /tmp/minga.grd
# srcGrd=/tmp/minga.grd
# grdedit /tmp/minga.grd -T
if [ -f $srcGrd ] ; then
	stem="`basename -s .grd $srcGrd`"
else
	echo "ERROR `basename $0`: GRD file $srcGrd not found"
	exit 1
fi

# clean up file paths to a standard form. the slashes always are a mess
# convert file paths to absolute
dstDir=$1"/"; shift; mkdir -p $dstDir;
dstDir="`cd $dstDir; pwd`"

# output file name is KMZ
kmzFilePath=$dstDir/$stem.kmz

# create working dirs
logFile=$kmzFilePath.$RANDOM.log
tmpDir=$kmzFilePath.$RANDOM.tmp
mkdir -p $tmpDir

date >> $logFile
# make the picture!
shaderSettings="-A300 "
west=`grdinfo -C  $srcGrd 2>> $logFile | awk '{print $2}'`
east=`grdinfo -C  $srcGrd 2>> $logFile | awk '{print $3}'`
south=`grdinfo -C $srcGrd 2>> $logFile | awk '{print $4}'`
north=`grdinfo -C $srcGrd 2>> $logFile | awk '{print $5}'`
((W=`gmtmath -Q -fg $east $west SUB =		`	))	> /dev/null 2>&1
((H=`gmtmath -Q -fg $north $south SUB =	`		))	> /dev/null 2>&1

echo "WESN $west/$east/$south/$north" >> $logFile
# find min z
minZ=`grdinfo $srcGrd 2>> $logFile | grep "z_min:" |
 awk '{print substr($0,index($0,"z_min:")+7,index($0,"z_max:")-(index($0,"z_min:")+8))}'|
	awk '{if (index($0, ".") != 0) {print substr($0,0,index($0,".")-1)} else {print $0}}'`
echo "minZ $minZ" >> $logFile
# find max z
maxZ=`grdinfo $srcGrd 2>> $logFile | grep "z_max:" |
	awk '{print substr($0,index($0,"z_max:")+7,index($0,"name:")-(index($0,"z_max:")+8))}'|
	awk '{if (index($0, ".") != 0) {print substr($0,0,index($0,".")-1)} else {print $0}}'`
echo "maxZ $maxZ" >> $logFile

# check for empty grd
((deltaZ=$maxZ-$minZ));
if [ $deltaZ -eq "0" ] ; then
# THis case assumes a ping map for 0 elevation change, obviously not general
#   echo "0      36  60  83     0.5  36  60  83">  $tmpDir"/$stem.cpt"
#   echo "0.5   194 185 147     1   194 185 147">> $tmpDir"/$stem.cpt"
#   echo "B 0   0   0"                          >> $tmpDir"/$stem.cpt"
#   echo "F 255 255 255"                        >> $tmpDir"/$stem.cpt"
#   echo "N -"                                  >> $tmpDir"/$stem.cpt"
    echo "0   0   0   0         1     0   0   0" > $tmpDir"/$stem.cpt"
    echo "B - "                                 >> $tmpDir"/$stem.cpt"
    echo "F - "                                 >> $tmpDir"/$stem.cpt"
    echo "N - "                                 >> $tmpDir"/$stem.cpt"
elif [ $deltaZ -lt "20" ] ; then
    makecpt -Cwysiwyg -T$minZ/$maxZ/1 -V > $tmpDir"/$stem.cpt" 2>> $logFile
else
	# FIXME: use non-adaptive Sandwell cpt so SRTM30+ tiles match...
    # could create "optimal" color map from grd, but then each grd has unique color map
    # grd2cpt -Ctopo $srcGrd -V > $tmpDir"/$stem.cpt" 2>> $logFile
	# makecpt -Ctopo -T-11000/9000/100 > $tmpDir"/$stem.cpt" 2>> $logFile
    cp ~/topo.cpt $tmpDir"/$stem.cpt"
fi

# FIXME: use non-adaptive Sandwell cpt so SRTM30+ tiles match...
cp ~/topo.cpt $tmpDir"/$stem.cpt"

# if there is a shader used, compute it
if [ -z "$shaderSettings" ] ; then
    echo "no shader used"
    shaderCmd=""
else
	# Normally I'd pick an adaptive intensity that depends on the data in grid;
	#	choose cumulative Laplace distribution with amplitude of +/- 0.8  e.g.
	#
	#     grdgradient $srcGrd -G$tmpDir"/$stem-s.grd" -Ne0.8 -V $shaderSettings >> $logFile 2>&1
	#
	# But for tiles in a global grid,
	#	its more attractive to use the same intensity file everywhere.
	# 		so I picked the approximate values given by -Ne0.6 for SRTM30+ tile
	#			 (w135n45) which is typical with land and bathy, used everywhere...
	#
	# BTW man page for grdgradient is wrong; code inspection demonstrates that
	# 	it does NOT calculate anything in L1 norm, it's all averages...
	#
	amp=0.6
	#
	# 	The other parameters of that distribution can calculated with using
	#		grdgradient with --NO-- normalization,  using grdmath
	#
	#		offset is mean of unnormalized gradient(grid in -A direction)
	#
	#		grdgradient w135n45.grd -A300 -Gtmp1.grd
	#		grdmath tmp1.grd MEAN = tmp2.grd
	#		grd2xyz tmp2.grd -S | head -1
	#
	offset=88.
	offset=0.
	#
	#		sigma is (in reality) just the mean of the abs of gradient
	#
	#		grdmath tmp1.grd ABS MEAN = tmp3.grd
	#		grd2xyz tmp3.grd -S | head -1
	#
	sigma=2770.
	sigma=2500.
	#
    grdgradient $srcGrd -G$tmpDir"/$stem-s.grd" -Ne$amp/$sigma/$offset -V $shaderSettings >> $logFile 2>&1
    shaderCmd="-I$tmpDir/"$stem"-s.grd"
fi

# convert grd into eps
# Google Earth can not open a huge kmz...
# 	do -NOT- make DPI more than about 1200 or so...
# DPI=240
# DPI=600
DPI=1200
imgFile=$tmpDir"/$stem.grdimage"
rm -f $imgFile
grdimage $srcGrd -Jx1id -C$tmpDir"/$stem.cpt" -fg $shaderCmd -V -P -X0 -Y0 -S- \
		--PAPER_MEDIA=Custom_${W}ix${H}i --DOTS_PR_INCH=${DPI} --ELLIPSOID=WGS-84 \
		>> $imgFile 2>> $logFile

# convert eps into geo TIFF (not TIF with one "f")
# This is tricky!
# After ps2raster creates whatever file format you request with the -T option
#		the -W+g comand will convert that file format into a geo TIFF
#
# 	ignore jpeg or other image files ps2raster creates...
#		also ignore "world" files with "w" jammed into filename extensions...
# 			you want geotiff with extension TIFF that is created by -W+g...
#
# So you can pick any raster format you want and it will be turned into a geotiff
#
# The GMT4.5.9 documentations states
#
#		ps2raster uses the loss-less Flate compression technique when creating
#			JPEG, PNG and TIFF images.
#
# so one of those 3 would be the natural choice. Adding "e" copies the EPS too...
#
#	in some lame tests I did...
#		JPEG seemed to make smallest tmp file, and (hence) fastest,
#			but PNG seemed to have less sub-pxel noise artifacts when really zoomed in...
#
# img2qtree seems to ignore transparency information, or maybe GDAL did that,
#	but in any case transparent PNG doesn't generate transparent kml...
#
# ps2raster $imgFile   -E${DPI} -W+g      -P -V -S -Qg1 >> $logFile 2>&1
ps2raster $imgFile   -E${DPI} -W+g -TGe -P -V -S -Qg1 >> $logFile 2>&1
geoTiffFile=$tmpDir"/$stem.tiff" ;
mv $tmpDir"/$stem.eps" $tmpDir"/$stem.georegistation.eps"

# convert geo TIFF to kml ...
# 	note that we output to a dir called files, as it will be a zillion small kml.
# 		after we have all the quad trees in files dir,
#			then we'll make a legal kmz dir...
kmlDir=$tmpDir"/$stem"
image2qtree $geoTiffFile -m kml -o $kmlDir/files >> $logFile 2>&1

# convert directory with many many many kml quad trees into legal kmz.
# root image of the qtree needs to get moved up one level in dir.
# root kml points to the wrong place as we made it in dir files, (not exactly but...).
# 	just add string "files" to path of all 4 qtrees we point to in root kml file...
cd $kmlDir
mv $kmlDir/files/files.png .
sed "s/0.kml/files\/0.kml/" $kmlDir/files/files.kml | \
sed "s/1.kml/files\/1.kml/" | \
sed "s/2.kml/files\/2.kml/" | \
sed "s/3.kml/files\/3.kml/" > $kmlDir/$stem.kml

# to make a legal kmz: zip CONTENTS of directory, not the directory!!!
echo "zip CONTENTS of kml DIR into a kmz FILE"	>> $logFile
zip -r -q $kmzFilePath *
wait; wait; wait;
cd - >> $logFile 2>&1
date >> $logFile

# clean up now useless bunch of many, many, many, tiny kml files
#	this is surprisingly slow!
rm -rf $kmlDir $tmpDir	2>> $logFile
# possibly leave log for debug
rm -f $logFile
exit
