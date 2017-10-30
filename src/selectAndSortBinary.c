#include <stdio.h>

// NOTE: assumes "bo3" output from a gmt function like grd2xyz foo.grd -bo3
//
// Read in 3 file paths, and WESN
// if xyz in first file is inside WESN provided write to second file, else third file
//
// used to break up "cm files" into tiles.

#define MAXLINESZ 1024

main (argc, argv)
int argc;
char *argv[];
{	
	if (argc-1 != 7) {
		printf("%s: got %d args, expected 7\n", *argv, argc-1);
		printf("	%s srcFileName insideFileName outsideFileName minX, maxX, minY, maxY\n", *argv);
		while (--argc) printf("%s ",*++argv);
		printf ("\n");
		return 1;
	}
	
	char srcFileName[MAXLINESZ], insideFileName[MAXLINESZ], outsideFileName[MAXLINESZ];
	double minX, maxX, minY, maxY;
	sscanf (*++argv, "%s", srcFileName);
	sscanf (*++argv, "%s", insideFileName);
	sscanf (*++argv, "%s", outsideFileName);
	sscanf (*++argv, "%lf", &minX);
	sscanf (*++argv, "%lf", &maxX);
	sscanf (*++argv, "%lf", &minY);
	sscanf (*++argv, "%lf", &maxY);
	
	FILE *insideFile, *outsideFile, *srcFile; 
	srcFile = fopen(srcFileName,"r"); 
 	insideFile = fopen(insideFileName,"wb"); 
 	outsideFile = fopen(outsideFileName,"wb"); 

	if (srcFile == NULL) {printf ("can't open %s in r mode\n", srcFileName); return 1; }
	if (insideFile == NULL) {printf ("can't open %s in wt mode\n",  insideFileName); return 1; }
	if (outsideFile == NULL) {printf ("can't open %s in wt mode\n", outsideFileName); return 1; }
	
	size_t cnt;
	double xyz[3];
	while (cnt = fread(xyz, sizeof(xyz), 1, srcFile)) {
//printf("%f %f %f\n", xyz[0], xyz[1], xyz[2]);
		if (xyz[0] > 180) xyz[0] -= 360;
		if (xyz[0] <-180) xyz[0] += 360;
		if (xyz[0] >= minX && xyz[0] <= maxX && xyz[1] >= minY && xyz[1] <= maxY) {
 			fwrite  (xyz, sizeof(xyz), 1, insideFile);
		} else {
 			fwrite  (xyz, sizeof(xyz), 1, outsideFile);
		}
	}
	
	fclose(srcFile); /*done!*/ 
	fclose(insideFile); /*done!*/ 
	fclose(outsideFile); /*done!*/ 
	return 0; 
}

