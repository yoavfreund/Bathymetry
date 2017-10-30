#!/bin/csh

# need lots of sig figs to keep surface from moaning

gmtset D_FORMAT = %.16lg
gmtset VERBOSE = TRUE

if ($#argv != 3) then
    echo "usage: $0 MOA_public MOA_private oDir"
    echo "  example: $0 /geosat4/data/public /geosat4/data/private /geosat2/srtm15_data/huge"
    exit
endif

set MOA_public  = $1;   shift
set MOA_private = $1;   shift
set oDir        = $1;   shift

set cmDir =   $oDir/cmFiles
rm $cmDir/*.xyzi
/bin/mkdir -p $oDir $cmDir

# make it all from scratch, or at least from cm files...
# use unique extension xyzi to ease debug and partial runs
#
# use all processors. In this case, several jobs are very quick,
# just launch all 12 and let them thrash just a little bit...
#FIXME: MAYBE these can not be run in parallel; this makes this one step slow.
#FIXME: group these by eye to be jobs of roughly same size (i.e. fast and slow)
#
#FIXME: it would be more efficient to remove shoal pings in makeAgencyCm.csh
#FIXME: but do that as a separate step to make bad pings easier to find; maybe...
#
echo "-CREATE- .xyzi files from cm data"
csh makeAgencyCm.csh $MOA_public/AGSO       $cmDir/AGSO.xyzi      &
csh makeAgencyCm.csh $MOA_public/CCOM       $cmDir/CCOM.xyzi      &
csh makeAgencyCm.csh $MOA_public/GEOMAR     $cmDir/GEOMAR.xyzi    &
csh makeAgencyCm.csh $MOA_public/IBCAO      $cmDir/IBCAO.xyzi     &
csh makeAgencyCm.csh $MOA_public/JAMSTEC    $cmDir/JAMSTEC.xyzi   &
#csh makeAgencyCm.csh $MOA_public/NAVO       $cmDir/NAVO.xyzi      &
wait;
#csh makeAgencyCm.csh $MOA_public/NGA        $cmDir/NGA.xyzi       &
csh makeAgencyCm.csh $MOA_public/NGDC       $cmDir/NGDC.xyzi      &
csh makeAgencyCm.csh $MOA_public/NOAA       $cmDir/NOAA.xyzi      &
#csh makeAgencyCm.csh $MOA_public/NOAA_geodas  $cmDir/NOAA_geodas.xyzi &
csh makeAgencyCm.csh $MOA_public/SIO        $cmDir/SIO.xyzi       &
csh makeAgencyCm.csh $MOA_public/US_multi   $cmDir/US_multi.xyzi  &
wait;
csh makeAgencyCm.csh $MOA_public/lakes      $cmDir/lakes.xyzi     &
csh makeAgencyCm.csh $MOA_private/3DGBR     $cmDir/3DGBR.xyzi     &
csh makeAgencyCm.csh $MOA_private/GEBCO     $cmDir/GEBCO.xyzi     &
#csh makeAgencyCm.csh $MOA_private/IFREMER  $cmDir/IFREMER.xyzi   &
csh makeAgencyCm.csh $MOA_private/NGA       $cmDir/DNC.xyzi &
wait;

#FIXME: it would be more efficient to remove shoal pings in makeAgencyCm.csh
#FIXME: but do that as a separate step to make bad pings easier to find; maybe...
removeShoalPings.sh -1 $cmDir $oDir/huge.xyzi $oDir/huge.shoal.xyzi

# all done, double check the results

minmax $oDir/huge.xyzi $oDir/huge.shoal.xyzi

