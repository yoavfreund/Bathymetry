#!/bin/bash
set -u
echo "`date`: starting com/$0 $@ "
purge

if [ "$#" != "2" ] ; then
	echo "usage: `basename $0` srcDir dstDir"
	echo "  example: `basename $0` ../../../doNotBackup/srtm15 /tmp/kmz "
	exit
fi

srcDir="$1";	shift
dstDir="$1";	shift

workingDir="/tmp/"
mkdir -p $dstDir $workingDir

# convert file paths to absolute

srcDir="`cd $srcDir/; pwd`"
dstDir="`cd $dstDir/; pwd`"
mkdir -p $dstDir

fileCnt=`ls -1 $srcDir/*.grd 2> /dev/null | wc -l`
if [ $fileCnt == "0" ] ; then
	echo "ERROR `basename $0`: no grd files in $srcDir"
	exit
fi
echo "`basename $0`: processing $fileCnt files"

for item in $srcDir/*.grd
do
	echo "`basename $0` processing $item"
	#FIXME: put grd2kmz someplace that isn't stupid...
	/Users/jj/Desktop/SRTM15/com/grd2kmz.sh $item $dstDir &
	sleep 3
	((jobsRunning=`ps -C | grep grd2kmz | grep -v grep | wc -l`))
	# do NOT launch zillion jobs at once. They are light, but thrash file system
	# use about a third of possible threads, ad hoc but reasonable
	while [ $jobsRunning -ge `sysctl hw.activecpu | awk '{print $2 /3 }'` ]
	do
		echo "$jobsRunning grd2kmz jobs are running..."
		sleep 30
		((jobsRunning=`ps -C | grep grd2kmz | grep -v grep | wc -l`))
	done
done
wait; wait; wait;
echo "`date`: finished com/$0 $@ "
exit
