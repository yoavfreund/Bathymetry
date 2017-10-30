#!/bin/sh

# parse the name of the CGIAR file and return the SRTM equivalent name

if [ "$#" != "1" ]; then
	echo "usage: sourceFilePath  "
	echo "  example: $0 /Volumes/srtm15/DEM/CGIAR/srtm_69_01.grd "
	exit
fi

src=$1;		shift

#find the west coordinate by looking at the grdinfo for the tile

west=`grdinfo $src 2>/dev/null | grep "\<x_min:.*x\>" | awk '{print substr($0, index($0, "x_min:")+7, index($0, "x_max:")-(index($0, "x_min:")+8))}'`
#echo "$west"

if [ "$west" -lt 0 ]; then
	west2=`echo $west | awk '{print substr($0, 2)}'`
	#echo ${#north2}
	if [ ${#west2} == 2 ]; then
		west2="0"$west2
	elif [ ${#west2} == 1 ]; then
		west2="00"$west2
	fi
	west="w"$west2
else
	if [ ${#west} == 2 ]; then
		west="0"$west
	elif [ ${#west} == 1 ]; then
		west="00"$west
	fi
	west="e"$west
fi
#echo "$west"


#similarly find the north coordinate

north=`grdinfo $src 2>/dev/null | grep "\<y_max:.*y\>" | awk '{print substr($0, index($0, "y_max:")+7, index($0, "y_inc:")-(index($0, "y_max:")+8))}'`
#echo "$north"
if [ "$north" -lt 0 ]; then
	north2=`echo $north | awk '{print substr($0, 2)}'`
	#echo ${#north2}
	if [ ${#north2} == 1 ]; then
		north2="0"$north2
	fi
	north="s"$north2
else
	#echo ${#north}
	if [ ${#north} == 1 ]; then
		north="0"$north
	fi
	north="n"$north
fi

#use the west and north coordinates to rename the file to make it easier to find when we need it

echo "$src $west$north"
