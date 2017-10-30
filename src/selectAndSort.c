#include <stdio.h>

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
	insideFile = fopen(insideFileName,"wt"); 
	outsideFile = fopen(outsideFileName,"wt"); 

	if (srcFile == NULL) {printf ("can't open %s in r mode\n", srcFileName); return 1; }
	if (insideFile == NULL) {printf ("can't open %s in wt mode\n",  insideFileName); return 1; }
	if (outsideFile == NULL) {printf ("can't open %s in wt mode\n", outsideFileName); return 1; }
	
	char tmp[MAXLINESZ], *cnt;
	while (cnt = fgets(tmp, MAXLINESZ, srcFile)) {
		double x, y, z;
		long sid;
		
		sscanf(tmp, "%lf %lf %lf %ld", &x, &y, &z, &sid);
		
		if (x > 180) x -= 360;
		if (x <-180) x += 360;
		if (x >= minX && x <= maxX && y >= minY && y <= maxY) {
			fprintf (insideFile, "%s", tmp);
		} else {
			fprintf (outsideFile, "%s", tmp);
		}
	}
	
	fclose(srcFile); /*done!*/ 
	fclose(insideFile); /*done!*/ 
	fclose(outsideFile); /*done!*/ 
	return 0; 
}

