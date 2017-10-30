#include <stdio.h>

// NOTE: this code assume xyzi input, similar functions expect xyz

// Read in 2 file paths, and WESN
// if xyzi in first file is inside WESN provided append to second file else do nothing
//
// used to break up "cm files" into tiles.

main (argc, argv)
int argc;
char *argv[];

{
	double x, y, z;
	long sid;
	double minX, maxX, minY, maxY;
	
#define LINESZ 1024

	char tileFileName[LINESZ], nextFileName[LINESZ], xyziFileName[LINESZ], tmp[LINESZ], *cnt;
	
	if (argc-1 != 6) {
		printf("%s: got %d args, expected 6\n", *argv, argc-1);
		while (--argc) printf("%s ",*++argv);
		printf ("\n");
		return 1;
	}
	
	sscanf (*++argv, "%s", xyziFileName);
	sscanf (*++argv, "%s", tileFileName);
	sscanf (*++argv, "%lf", &minX);
	sscanf (*++argv, "%lf", &maxX);
	sscanf (*++argv, "%lf", &minY);
	sscanf (*++argv, "%lf", &maxY);
		
	
	FILE *tileFile, *nextFile, *xyziFile; 
	xyziFile = fopen(xyziFileName,"r"); 
	tileFile = fopen(tileFileName,"at");
	if (!tileFile) tileFile = fopen(tileFileName,"wt");
	if (tileFile == NULL) {printf ("can't open %s in either at or wt mode\n", tileFileName); return 1; }
	if (xyziFile == NULL) {printf ("can't open %s in r mode\n", xyziFileName); return 1; }
	
	while (cnt = fgets(tmp,LINESZ,xyziFile)) {
		sscanf(tmp, "%lf %lf %lf %ld", &x, &y, &z, &sid);
		if (x > 180) x -= 360;
		if (x <-180) x += 360;
		if (x >= minX && x <= maxX && y >= minY && y <= maxY) { 
			fprintf (tileFile, "%s", tmp);
		}
	}
	
	fclose(xyziFile); /*done!*/ 
	fclose(tileFile); /*done!*/ 
	return 0; 
}

