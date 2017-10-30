#include <stdio.h>

// Read in 2 file paths
//
// used to convert invproj ascii XYZ files into binary.

#define MAXLINESZ 1024

main (argc, argv)
int argc;
char *argv[];
{	
	if (argc-1 != 2) {
		printf("%s: got %d args, expected 2\n", *argv, argc-1);
		printf("	%s srcFileName dstFileName\n", *argv);
		while (--argc) printf("%s ",*++argv);
		printf ("\n");
		return 1;
	}
	
	char srcFileName[MAXLINESZ], dstFileName[MAXLINESZ];
	sscanf (*++argv, "%s", srcFileName);
	sscanf (*++argv, "%s", dstFileName);
	
	FILE *dstFile, *srcFile; 
	srcFile = fopen(srcFileName,"r"); 
 	dstFile = fopen(dstFileName,"wb"); 

	if (srcFile == NULL) {printf ("can't open %s in r mode\n",  srcFileName); return 1; }
	if (dstFile == NULL) {printf ("can't open %s in wt mode\n", dstFileName); return 1; }
	
	double xyz[3];
	char tmp[MAXLINESZ], *cnt;
	while (cnt = fgets(tmp, MAXLINESZ, srcFile)) {
		double xyz[3];

		sscanf(tmp, "%lf %lf %lf", &xyz[0], &xyz[1], &xyz[2]);
//printf("%f %f %f\n", xyz[0], xyz[1], xyz[2]);
		fwrite  (xyz, sizeof(xyz), 1, dstFile);
	}
	
	fclose(srcFile); /*done!*/ 
	fclose(dstFile); /*done!*/ 
	return 0; 
}

