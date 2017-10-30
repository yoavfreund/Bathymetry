#include <stdio.h>

// Read the angle and upper limit (both as decimal degrees) from cmd line.
//
// Caclulate desired range (i.e. 0-360, +/-180) as 
//
//			(upper-360) <= x <= upper
//
// write principle value of angle AS INTEGER to standard out.
//
// The integer requirement is a concession to csh and
// its inability to deal with float

#include <math.h>

main (argc, argv)
int argc;
char *argv[];

#define UPPER_LIMIT (+360.           )
#define LOWER_LIMIT (UPPER_LIMIT-180.)

{
	double x, upperLimit, lowerLimit;

	sscanf (*++argv, "%lf", &x);
	sscanf (*++argv, "%lf", & upperLimit);
	
	lowerLimit = upperLimit - 360.;

	while (x > upperLimit) x -= 360.;

	while (x < lowerLimit) x += 360.;

//	printf("%.10lf\n", x); 
	printf("%ld\n", lrint(x)); 
}
