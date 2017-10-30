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

foreach file (`find $dir -name "*.cm"`)
	echo "`basename $0` processing $file"

	# quick, half hearted, test of input data
	awk '{ if (NF<8) {printf ("Error: '$file':line %g is broken\n",NR); print} }' < $file

	# make sure everything is +/- 180

	awk '{printf("%s,%s,%s,%s,%s,%s,%s,%s,'$file'\n", $1,$2,$3,$4,$5,$6,$7,$8)}' \
		< $file >> $ofile

end
