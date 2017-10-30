#!/bin/bash -x

gmtset D_FORMAT = %.16lg

# Dave Sandwell "image of predicted bathymetry"
# 	http://topex.ucsd.edu/marine_topo/
img='../../img/topo.img'

# land DEMs we use from SRTM, ASTER, and GLAS
volume="/palsar"

asterDEM="$volume/DEM/ASTER/World"
cgiarDEM="$volume/DEM/CGIAR/"
glasDEM="$volume/DEM/GLAS/"

# location of IBCAO arctic grid
ibcaoDEM="$volume/DEM/IBCAO/"
ibcaoStem="$ibcaoDEM/IBCAO_V3"
ibcaoGrd="$ibcaoStem.grd"
arcticGrd="$ibcaoStem".grd
arcticXyz="$ibcaoStem".xyz

# location of edited CM files; aka the sonar pings
MOA_public=/geosat4/data/public
MOA_private=/geosat4/data/private

# Blend southern edge of IBCAO grid with predicted...
arcticSid=00099
minArctic=69
maxPred=70

# surface parameters use for bathymetry, including IBCAO processing
tension=-T0.55
#convergence=-C0.5	# meters
convergence=-C1.0	# meters
search=-S300m		# arc minutes
relaxFactor=-Z1.4
# FIXME: if surface goes max iterations, then inaccurate grid, but no limit could spin.
#maxItertion=-N123456
#maxItertion=-N100
maxItertion=-N200
surfaceOpts="$tension $relaxFactor $convergence $maxItertion $search"
