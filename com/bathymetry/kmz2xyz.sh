#! /bin/bash

# Almost same as kml2gmt except it takes either kml or kmz
#
# Throws away the stderr which makes it easier to pipe xy output around,
# but might be a bug in itself let alone harder to debug callers...
#
# Accepts all the kml2gmt args,
#	but file name must be first arg




if [ "$#" -lt "1" ] ; then
	echo "usage: `basename $0` kmz "
	echo "  example: `basename $0` foo.kmz"
	exit
fi

file=$1;			shift;

if [[ $file == *.kmz ]]
then tar --to-stdout -xf $file | kml2gmt $@ 2>&1 | tail -n+5
else kml2gmt $file $@ | tail -n+5
fi
