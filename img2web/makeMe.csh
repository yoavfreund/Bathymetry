gfortran -O -Bstatic img2web.f -c -o img2web.o 
gfortran -O -Bstatic diskio.c  -c -o diskio.o
gfortran diskio.o img2web.o -o img2web -lgfortran
