CC = gcc
CFLAGS = -c -O2 -pedantic -fno-common -Wall -fPIC -fno-strict-aliasing $(INCDIR)

NETCDF = /sw/lib
NETCDF = /opt/local/lib
GMTLIB = /sw/lib
GMTLIB = /opt/local/lib/gmt4/lib
LIBDIR = -L$(GMTLIB) -L$(NETCDF)

INCDIR = -I. -I/sw/include/ -I/sw/bin/include/
INCDIR = -I. -I/opt/local/lib/gmt4/include/ -I/opt/local/include/

PROG = medianId
SRCS = medianId.c

OBJS = $(SRCS:.c=.o)

HDRS = block_subs.c block_subs.h

LIBS = -lgmt -lnetcdf -lm


all: $(PROG)

# This is a mess to do "right"
# because block_subs.c is in fact a .h

medianId: medianId.c block_subs.c block_subs.h
	$(CC) $(CFLAGS) medianId.c
	$(CC) -o $@ $(OBJS) $(LIBDIR) $(LIBS)

clean:
	-rm -f $(OBJS) tags core $(PROG)

install:
	mv $(PROG) ../../bin/$(PROG)
