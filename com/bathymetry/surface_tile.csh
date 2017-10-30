#! /bin/csh
#
# routine to take the giant surface run for SRTM15 and break it up into 6 tiles
# according to longitude.  This reduces the memory requirement but also allows
# an anisotropy factor at higher latitudes
#
gmtset D_FORMAT = %.16lg
gmtset VERBOSE = TRUE
#
#  here are the two surface to replace
#  surface $pred.median.xyz -V -fg -R$land.grd -bi3 $surfaceOpts -G$pred.unmasked.grd
#  surface $ping.xyd.landZeros.median -bi3 -V -fg -R$land.grd $surfaceOpts -G$ping.xyd.grd
#
if ($#argv < 3) then
	echo " "
	echo "  example: `basename $0` pred.median.xyz surfaceOpts pred.unmasked.grd"
	echo " "
	exit
endif

set bxyz	= $1;   shift
set out		= $1;   shift
set opts	= "$*"

#/bin/rm -rf *out.grd
#
set B1 = -180./180./58./90.;
set B2 = -180./180./28./62.;
set B3 = -180./180./-2./32.;
set B4 = -180./180./-32./02.;
set B5 = -180./180./-62./-28.;
set B6 = -180./180./-90./-58.;
#
set C1 = -180./180./60./90.;
set C2 = -180./180./30./60.;
set C3 = -180./180./00./30.;
set C4 = -180./180./-30./00.;
set C5 = -180./180./-60./-30.;
set C6 = -180./180./-90./-60.;
#
# make the blend file
#
echo B1.grd -R$C1 1 > blend.txt
echo B2.grd -R$C2 1 >> blend.txt
echo B3.grd -R$C3 1 >> blend.txt
echo B4.grd -R$C4 1 >> blend.txt
echo B5.grd -R$C5 1 >> blend.txt
echo B6.grd -R$C6 1 >> blend.txt
#
#  do all the subgrids
#
# 1
#
echo $bxyz -V -fg -bid -I15c -A0.5 -R$B1 $opts -GB1$out
blockmedian $bxyz -I15c -bid -bod -R$B1 -V > B1.xyz
surface B1.xyz -V -fg -bid -I15c -A.50 -Ll-800 -Lu800 -R$B1 $opts -GB1.grd
#
# 2
#
echo $bxyz -V -fg -bid -I15c -A.707 -R$B2 $opts -GB2$out
blockmedian $bxyz -I15c -bid -bod -R$B2 -V > B2.xyz
surface B2.xyz -V -fg -bid -I15c -A.707 -Ll-800 -Lu800 -R$B2 $opts -GB2.grd
#
# 3
#
echo $bxyz -V -fg -bid -I15c -A.966 -R$B3 $opts -GB3.grd
blockmedian $bxyz -I15c -bid -bod -R$B3 -V > B3.xyz
surface B3.xyz -V -fg -bid -I15c -A.966 -Ll-800 -Lu800 -R$B3 $opts -GB3.grd
#
# 4
#
echo $bxyz -V -fg -bid -I15c -A.966 -R$B4 $opts -GB4.grd
blockmedian $bxyz -I15c -bid -bod -R$B4 -V > B4.xyz
surface B4.xyz -V -fg -bid -I15c -A.966 -Ll-800 -Lu800 -R$B4 $opts -GB4.grd
#
# 5
#
echo $bxyz -V -fg -bid -I15c -A.707 -R$B5 $opts -GB5.grd
blockmedian $bxyz -I15c -bid -bod -R$B5 -V > B5.xyz
surface B5.xyz -V -fg -bid -I15c -A.707 -Ll-800 -Lu800 -R$B5 $opts -GB5.grd
#
# 6
#
echo $bxyz -V -fg -bid -I15c -A.50 -R$B6 $opts -GB6.grd
blockmedian $bxyz -I15c -bid -bod -R$B6 -V > B6.xyz
surface B6.xyz -V -fg -bid -I15c -A.50 -Ll-800 -Lu800 -R$B6 $opts -GB6.grd
#
#  now blend all the files together
#
grdblend blend.txt -G$out -R-180/180/-90/90 -fg -I15c -V
#
#   now clean up the mess
#
#rm *.xyz
#rm B*.grd
#rm blend.txt
