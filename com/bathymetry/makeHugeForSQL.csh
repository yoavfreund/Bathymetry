#!/bin/csh

# need lots of sig figs to keep surface from moaning

gmtset D_FORMAT = %.16lg
gmtset VERBOSE = TRUE

if ($#argv != 7) then
    echo "usage: $0 MOA_public MOA_private arcticGrid minArctic maxPred arcticSid oDir"
    echo "  example: $0 /Volumes/srtm15/multibeam/data/public /Volumes/srtm15/multibeam/data/private /Volumes/srtm15/SRTM15/arctic/IBCAO_V3_500m_RR_geo_trimmed.grd 79 80 00099 /Volumes/srtm15/doNotBackup/srtm15_plus"
    exit
endif

set MOA_public  = $1;   shift
set MOA_private = $1;   shift
set arcticGrd   = $1;   shift
set minArctic   = $1;   shift
set maxPred     = $1;   shift
set arcticSid   = $1;   shift
set oDir        = $1;   shift

set cmDir =   $oDir/cmFiles
/bin/mkdir -p $oDir $cmDir

# make it all from scratch, or at least from cm files...
# use unique extension csv to ease debug and partial runs
#
# use all processors. In this case, several jobs are very quick,
# just launch all 12 and let them thrash just a little bit...
#FIXME: MAYBE these can not be run in parallel; this makes this one step slow.
#FIXME: group these by eye to be jobs of roughly same size (i.e. fast and slow)
#
#FIXME: it would be more efficient to remove shoal pings in makeAgencyCSV.csh
#FIXME: but do that as a separate step to make bad pings easier to find; maybe...
#
echo "-CREATE- .csv files from cm data"
csh makeAgencyCSV.csh $MOA_public/lakes      $cmDir/lakes.csv     &
csh makeAgencyCSV.csh $MOA_private/3DGBR     $cmDir/3DGBR.csv     &
csh makeAgencyCSV.csh $MOA_public/CCOM       $cmDir/CCOM.csv      &
csh makeAgencyCSV.csh $MOA_public/NAVO       $cmDir/NAVO.csv      &
csh makeAgencyCSV.csh $MOA_public/NOAA       $cmDir/NOAA.csv      &
wait
csh makeAgencyCSV.csh $MOA_private/GEBCO     $cmDir/GEBCO.csv     &
csh makeAgencyCSV.csh $MOA_public/JAMSTEC    $cmDir/JAMSTEC.csv   &
csh makeAgencyCSV.csh $MOA_public/SIO        $cmDir/SIO.csv       &
csh makeAgencyCSV.csh $MOA_public/SIO_multi  $cmDir/SIO_multi.csv &
csh makeAgencyCSV.csh $MOA_public/US_multi   $cmDir/US_multi.csv  &
wait
#FIXME: Use IBCAO grid rather than their pings
# makeAgencyCSV.csh $MOA_public/IBCAO    $cmDir/IBCAO.csv     &
#FIXME: IFREMER, NGA private, and GEODAS data is suspect
# csh makeAgencyCSV.csh $MOA_private/IFREMER $cmDir/IFREMER.csv   &
# csh makeAgencyCSV.csh $MOA_public/NGA      $cmDir/NGA.csv       &
# csh makeAgencyCSV.csh $MOA_public/NOAA_geodas  $cmDir/NOAA_geodas.csv &
# wait


# FIRST Special Case
#
# Do want DNC data or not?
#FIXME: need some smart way to select DNC or not...
if (6 == 6) then

    set dnc = $cmDir/DNC_prop
    csh makeAgencyCSV.csh $MOA_private/NGA $dnc.tmp

    # use data from DNC, but set the sid = 0?
    if (6 == 9) then
        echo "Using DNC data, but zeroing DNC sid..."
        cat $dnc.tmp | awk '{ print $1, $2, $3, 00000 }' >! $dnc.csv
        /bin/rm -rf $dnc.tmp
    else
        echo "Using DNC data and keeping DNC sid..."
        mv $dnc.tmp $dnc.csv
    endif

else
    echo "-NOT- using DNC data"
endif

cat $cmDir/*.csv > $oDir/huge.csv

exit


#FIXME: it would be more efficient to remove shoal pings in makeAgencyCSV.csh
#FIXME: but do that as a separate step to make bad pings easier to find; maybe...
removeShoalPings.sh -10 $cmDir $oDir/huge.xyzi $oDir/huge.shoal.xyzi

# all done, double check the results

minmax $oDir/huge.xyzi $oDir/huge.shoal.xyzi
