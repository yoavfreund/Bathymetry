#! /bin/csh

# need lots of sig figs to keep surface from moaning

gmtset D_FORMAT = %.16lg
gmtset VERBOSE = TRUE

# cat -ALL- files in target dir into one huge file,
# keeping only lat, lon, depth and srcId

if ($#argv != 2) then
	echo "usage: `basename $0` dir outfile"
	echo "  example: `basename $0` cm huge.cm"
	exit
endif

set dir		= $1;   shift
set ofile	= $1;   shift
set opts	= "$*"

/bin/rm -rf $ofile
touch  $ofile

# get all the good data from all the good files in the dir

foreach file (`find $dir -name "*.cm" -maxdepth 1 `)
	echo "`basename $0` processing $file"

	# quick, half hearted, test of input data
	awk '{ if (NF<8) {printf ("Error: '$file':line %g is broken\n",NR); print} }' < $file

	# punt pings with flag = 9999
	# make sure everything is +/- 180
	# cat interesting parts of each file (xyzi) into huge one output file
	awk '{if ($6 != 9999) {tmp=$2;if(tmp>180)tmp=tmp-360;printf "%.7lf %s %s %05d\n",tmp,$3,$4,$7 } }' \
		< $file >> $ofile
end
