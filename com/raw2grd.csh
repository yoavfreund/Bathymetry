#! /bin/csh

# Author:	JJ Becker
# Date:		2011 03 07
#
# Summary:	Create grd file to look at raw multibeam data.
#
# Inputs:	"Usage: $0 src name west east south north"
#
#	path to directory containing 1 or more ".raw" files from R/V Melville Simrad Multibeam sonar
#
#	stem of name of output files
#		e.g. raw
#
#	West, East, South, and North bounds of data to be plotted (signed decimal degrees)
#
# Outputs:
#	
#	"grd" file of bathymetry or sidescan
#
# Notes:
#
#	Probably works best on regions limited to 10 by 10 degrees, but you might get lucky.
#
# References:
#
#	Cribbed directly from
#
#	www.marine-geo.org/tools/search/data/field/Revelle/RR0901/docs/RR0901_report_multibeam.pdf
#
# 	read that link and the rest of this egregious hacking might make some sense. It's ugly...


#--->if "MAP_REGION" doesn't have any data; you'll get strange error messages.
#--->but: MB System is a memory hog, so a huge "MAP_REGION" (west, east, s, n), will "malloc off"
#
# Copies the src data to $TMP_DIR because mbsytem steps on it's source directory!


if ($#argv < 6 ) then
 echo " "
 echo "Usage: $0 src name west east south north [sidescan]"
 echo " "
 echo "Example: $0 . Nafanua -169.2 -168.9 -14.35 -14.05
 echo "Example: $0 ~/data test 	-90 -30 -60 -40"
 echo "Example: $0 ~/data/foo.all test	-90 -30 -60 -40"
 echo "Example: $0 ~/data sideScanTest	-90 -30 -60 -40 sidescan"
 echo
 echo "To get the min/max longitude, and latitude:'
 echo "  path to the raw file is just an example..."
 echo
 echo " mbinfo -G -F58 -I /Volumes/current-cruise-data-read-only/multibeam/rawdata/0679_20110306_194753_melville.all "
 echo 
 echo "		note: this will take a moment to run, and if you forget the -I, it will spin forever..."
 echo " "
 exit 1
endif 

# Set these editing and plottting options to your taste
#
# For starters, do not grid data when on station, ship must have min speed (km/h) to be in grid

set minSpeed = "2.0"


# gridding options
#
# -E is grid spacing, e.g. -E 0.25/0.25/degrees or -E 100meters
#
# median filtered -F2
# footprint size filtered/weighted -F5
#
# -M output grids with ping count and standard deviation of pings at each grid node

#set gridOption = "-C0 -f2 -E 0.004166666666667/0.004166666666667/degrees "
set gridOptions = "-C0 -f2 -E 25/25meters"


# obviously there are many other plotting, clipping, etc options to fiddle with below.
#
#
# ============ do not edit below, unless you really want to, and then its ok ===========

set SRC = $1
set NAME = $2
set MAP_REGION = "$3/$4/$5/$6"

set TMP_DIR = "."
set WORK_DIR = "$TMP_DIR/lamedata/"
set FILES_FILE = "$TMP_DIR/lamedataList"

if ($#argv < 7) then
 set GRID_TYPE = 2
else
 set GRID_TYPE = 4
 echo "creating SIDESCAN images"
endif


# FIXME: The next bit of vodoo coding is needed to keep GMT color map crap straight
#
#--->IF you get stange GMT color pallet errors try RGB
# ps2raster requires HSV, mbsystem seems to require rgb, usually....
#gmtset COLOR_MODEL = HSV
gmtset COLOR_MODEL = RGB


# cribbed directly from
#
#	www.marine-geo.org/tools/search/data/field/Revelle/RR0901/docs/RR0901_report_multibeam.pdf
#
# === mbsystem can NOT edit/process format 58 file, (".all" on Melville), convert to 59 format. ===
# === mbcopy can NOT accept -F-1 -I filelist options :-( ==========================================
#
# lot's of csh hackery to basically overcome lame mbsystem stuff and end up with a format 59 file...
# skip any proccessed file, taking only ".all"
# 1.	Data format conversion

if (! -e $SRC) then
 echo "$SRC does not exist" 
 exit 1
else 
 if (-f $SRC) then
  set SRC_DIR = "`dirname $SRC`"
  basename $SRC >! $FILES_FILE
 else 
  set SRC_DIR = "$SRC"
  ls $SRC | grep '.all$' >! $FILES_FILE
 endif
endif

rm -rf $WORK_DIR ; mkdir -p $WORK_DIR
cat $FILES_FILE | grep '.all$' | sed 's/.all$//' | \
	awk ' {print "mbcopy -I '$SRC_DIR/'"$0".all -O '$WORK_DIR/'"$0".mb59 -F58/59 -R'$MAP_REGION'"}' | \
		/bin/csh -xf


# 2.	Generation of filename list for batch processing

ls $WORK_DIR | grep '.mb59$' | awk ' {print "'$WORK_DIR'/"$0}' >! list0

mbdatalist -F-1 -I list0 -R$MAP_REGION >! list1


# 3.	Ancillary data

mbdatalist -F-1 -I list1 -R$MAP_REGION -N


# generate a script to make grid, run that script and make a grd

# mbm_grid -A$GRID_TYPE -F-1 -I list1 $gridOptions -N -R$MAP_REGION -S$minSpeed -O$NAME
mbm_grid -A$GRID_TYPE -F-1 -I list1 $gridOptions    -R$MAP_REGION -S$minSpeed -O$NAME

if ($GRID_TYPE == 4) then
 "./$NAME".kmz_mbmosaic.cmd
else
"./$NAME"_mbgrid.cmd
endif

# run script that plots grd

"./$NAME".grd.cmd


# === remove cruft 

# rm -f "./$NAME"_mbmosaic.cmd "./$NAME"_mbgrid.cmd ./$NAME.grd.cmd
rm -f ./$NAME.mb-1 list[0-1]
exit 0
