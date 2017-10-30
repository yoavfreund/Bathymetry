
First let's compare what we want to do to what blockmedian currently does; i.e. echo all 4 fields in the input records…


[405] % ./medianId -Q ./test.xyzi -I30c -Rg-170/-160/60/65 -F -V -fg

-165.6585842	64.4452593	-31.5	45


Note that blockmedian agrees, 

[404] % blockmedian -Q ./test.xyzi -I30c -Rg-170/-160/60/65 -F -V -fg

-165.6585842	64.4452593	-31.5

but blockmedian truncates input line after the z data, (SID) which is the only reason we need medianId. Other parts of GMT -do- echo the unused parts of input line, which is all that really needed to be done…


===========

To roll up to a newer version of GMT (say 5), I'd do the following…



First do a diff the 3 source files in the gmt.4.5.8 with version of GMT you want to port to (say 5.0), which hopefully will only find cosmetic or simple changes. If there are major changes you'll have to learn how blockmedian.c used to work, and how it works now. That could be a big job, but keep in mind we only whacked a few index variables, so don't panic yet. Most likely, even if the GMT source changed a lot, the changes you need to make are still obvious...

Second diff the source files in this directory against 4.5.8. Those changes do show an obvious pattern, (e.g. +1), that will inform your next steps.

Third, if the changes to GMT don't conflict with medianId changes made in 4.5.8, you're lucky!!! The general procedure will be to copy this directory and then replace stuff in the copy with new version of GMT blockmedian. Using the diffs from the 4.5.8 version as a guide, you whack your copy… 

	make a copy of this directory

	-IN THE NEW DIRECORY- 
	replace the GMT 4.5.8 sub directory with version you're porting to 
		in other words: 
			replace 3 source files in gmt.4.5.8 with new GMT source.

	-IN THE NEW DIRECORY-
	replace medianId.c with new version of blockmedian.c you're porting,

	Do lots and lots of these in OLD directory to understand what the changes are...

		sdiff -l -W medianId.c gmt.4.5.8/blockmedian.c

			You'll need to have your brain turned on, but a pattern
			might jump out at you (+1).


	-IN THE NEW DIRECORY-
	Do the same sort of thing, comparing you hacks to mine…

	-IN THE NEW DIRECTORY-
	Hack medianId.c. It needs (generally) the same changes that the 4.5.8 version got. 
		This will require a little thought, but not a lot, if you don't let 
			too many GMT releasees go by without doing the maintenance you're 
				hating right now (hint)…

	debug with ./testMedianId

I don't debug without a debugger, so there is an xCode project ("medanId_xcode") that has a single file (main.c). Replace main.c with your new medianId.c and run the xCode debugger. You'll probably have a few issues with xCode version-itis, but it USUALLY propagates easy, sometimes automatically. The tricky bit is finding the handful of places in the "project inspector" that set up gcc include and lib paths. Apple loves to change those :-(

To learn how to use the xcode debugger, google up "xcode command line debug" or something about using xcode to develop a command line utility (tool). I like xCode's GUI debugger, but you can also use gdb…



-jj


These are the changes from GMT 4.5.8. Yours will be different, but should be pretty similar…

======= Changes to block_subs.c in GMT 4.5.8 =======

	-none-




======= Changes to block_subs.h in GMT 4.5.8 =======

Just one, add "sid" to struct

[382] % diff -w block_subs.h gmt.4.5.8/
91d90
< 	double sid;    /* source ID */
[383] % 



======= Changes to blockmedian.c in GMT 4.5.8 =======

Mostly add "+1" when referring to fields, 

(also whack a few of the printfs…)


[382] % diff -w medianId.c gmt.4.5.8/blockmedian.c
55c55
< 	double	*in = NULL, out[7+1], wesn[4], quantile[3] = {0.25, 0.5, 0.75}, extra[3], weight, *z_tmp = NULL;
---
> 	double	*in = NULL, out[7], wesn[4], quantile[3] = {0.25, 0.5, 0.75}, extra[3], weight, *z_tmp = NULL;
150,151c150,151
< 		fprintf (stderr, "medianId %s - Block averaging by L1 norm\n\n", GMT_VERSION);
< 		fprintf (stderr, "usage: medianId [infile(s)] %s %s\n", GMT_I_OPT, GMT_Rgeo_OPT);
---
> 		fprintf (stderr, "blockmedian %s - Block averaging by L1 norm\n\n", GMT_VERSION);
> 		fprintf (stderr, "usage: blockmedian [infile(s)] %s %s\n", GMT_I_OPT, GMT_Rgeo_OPT);
176c176
< 		fprintf (stderr, "\t   Default is 3+1 columns (or 4+1 if -W is set).\n");
---
> 		fprintf (stderr, "\t   Default is 3 columns (or 4 if -W is set).\n");
207c207
< 	n_req = (Ctrl->W.weighted[GMT_IN]) ? 4+1 : 3+1;
---
> 	n_req = (Ctrl->W.weighted[GMT_IN]) ? 4 : 3;
252c252
< 	n_expected_fields = (GMT_io.binary[GMT_IN]) ? GMT_io.ncol[GMT_IN] : 3+1 + Ctrl->W.weighted[GMT_IN];
---
> 	n_expected_fields = (GMT_io.binary[GMT_IN]) ? GMT_io.ncol[GMT_IN] : 3 + Ctrl->W.weighted[GMT_IN];
312c312
< 			data[n_pitched].a[BLK_W] = ((Ctrl->W.weighted[GMT_IN]) ? in[3+1] : 1.0);
---
> 			data[n_pitched].a[BLK_W] = ((Ctrl->W.weighted[GMT_IN]) ? in[3] : 1.0);
318d317
< 			data[n_pitched].sid      = (unsigned short)in[3];
328c327
< 		if (gmtdefs.verbose) fprintf (stderr, "%s: No data records found; no output produced\n", GMT_program);
---
> 		if (gmtdefs.verbose) fprintf (stderr, "%s: No data records found; no output produced", GMT_program);
332c331
< 		if (gmtdefs.verbose) fprintf (stderr, "%s: No data points found inside the region; no output produced\n", GMT_program);
---
> 		if (gmtdefs.verbose) fprintf (stderr, "%s: No data points found inside the region; no output produced", GMT_program);
340c339
< 	n_out = (Ctrl->W.weighted[GMT_OUT]) ? 4+1 : 3+1;
---
> 	n_out = (Ctrl->W.weighted[GMT_OUT]) ? 4 : 3;
370,372d368
< 		/* IMPORTANT NOTE!!!
< 		 median_output will (possibly) sort data by x, and y, so you can NOT assume data is still sorted 
< 		 */		
376,379c372,375
< 			out[3+1] = z_tmp[0];	/* 0% quantile (min value) */
< 			out[4+1] = extra[0];	/* 25% quantile */
< 			out[5+1] = extra[2];	/* 75% quantile */
< 			out[6+1] = z_tmp[nz-1];	/* 100% quantile (max value) */
---
> 			out[3] = z_tmp[0];	/* 0% quantile (min value) */
> 			out[4] = extra[0];	/* 25% quantile */
> 			out[5] = extra[2];	/* 75% quantile */
> 			out[6] = z_tmp[nz-1];	/* 100% quantile (max value) */
382,383c378,379
< 			out[4+1] = z_tmp[0];	/* Low value */
< 			out[5+1] = z_tmp[nz-1];	/* High value */
---
> 			out[4] = z_tmp[0];	/* Low value */
> 			out[5] = z_tmp[nz-1];	/* High value */
388,389c384,385
< 				out[3+1] = (nz%2) ? z_tmp[nz/2] : 0.5 * (z_tmp[(nz-1)/2] + z_tmp[nz/2]);
< 				out[3+1] *= 1.4826;	/* This will be L1 MAD-based scale */
---
> 				out[3] = (nz%2) ? z_tmp[nz/2] : 0.5 * (z_tmp[(nz-1)/2] + z_tmp[nz/2]);
> 				out[3] *= 1.4826;	/* This will be L1 MAD-based scale */
392c388
< 				out[3+1] = GMT_d_NaN;
---
> 				out[3] = GMT_d_NaN;
394c390
< 		if (Ctrl->W.weighted[GMT_OUT]) out[w_col+1] = weight;
---
> 		if (Ctrl->W.weighted[GMT_OUT]) out[w_col] = weight;
414,415c410,411
< void median_output (struct GRD_HEADER *h, GMT_LONG first_in_cell, GMT_LONG first_in_new_cell, double weight_sum, double *out,
< 					double *extra, GMT_LONG go_quickly, double *quantile, GMT_LONG n_quantiles, struct BLK_DATA *data)
---
> void median_output (struct GRD_HEADER *h, GMT_LONG first_in_cell, GMT_LONG first_in_new_cell, double weight_sum, double *out, double *extra, 
> 	GMT_LONG go_quickly, double *quantile, GMT_LONG n_quantiles, struct BLK_DATA *data)
443d438
< 				out[3] = (double)data[index1].sid;
451d445
< 				out[3] = (double)data[index].sid;
456d449
< 	out[3] = (double)data[index].sid;
[383] % 
