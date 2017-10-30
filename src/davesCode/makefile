CC=gcc
FC=gfortran

FFLAGS=-O -Bstatic 

PGMS = interp_ship_80 img2xyz_80 interp_ship img2xyt principleValue colorScale hoursMinSec

all		: $(PGMS) 
		mv $(PGMS) ../bin

clean		:
		rm -f diskio.o colorScale hoursMinSec principleValue \
			interp_ship   interp_ship_80 \
			interp_ship.o interp_ship_80.o \
			img2xyt   img2xyz_80 \
			img2xyt.o img2xyz_80.o 

img2xyz_80	: img2xyz_80.o diskio.o
		$(FC) $(FFLAGS) img2xyz_80.o diskio.o -o img2xyz_80

interp_ship_80	: interp_ship_80.o diskio.o
		$(FC) $(FFLAGS) interp_ship_80.o diskio.o -o interp_ship_80

img2xyt		: img2xyt.o diskio.o
		$(FC) $(FFLAGS) img2xyt.o diskio.o -o img2xyt

interp_ship	: interp_ship.o diskio.o
		$(FC) $(FFLAGS) interp_ship.o diskio.o -o interp_ship

