// Input converted from decimal deg to dd:mm:ss.sss
// with the : in the string for GMT use.
// ascii floating point from stdin.
//
// FIXME: assumes the input is aready a PRINCIPLE VALUE i.e. +/-180

#include <stdio.h>
#include <math.h>

main (argc, argv)
int argc;
char *argv[];

{
	double x, mmss, ss;
	int dd, mm, signBit = 0;
	
	sscanf (*++argv, "%lf", &x);

	if (x<0.0) {
		signBit = 1;
		x = fabs(x);
	}
		
	dd = floor(x);

	mmss=3600*(x-dd);
	mm = floor(mmss/60);

	ss =(mmss-mm*60);

	printf("%c%02d:%02d:%06.3f\n",signBit?'-':' ',dd,mm,ss);
}
