/*--------------------------------------------------------------------
 *    $Id: blockmedian.c 9729 2012-03-21 23:19:37Z pwessel $
 *
 *	Copyright (c) 1991-2012 by P. Wessel and W. H. F. Smith
 *	See LICENSE.TXT file for copying and redistribution conditions.
 *
 *	This program is free software; you can redistribute it and/or modify
 *	it under the terms of the GNU General Public License as published by
 *	the Free Software Foundation; version 2 or any later version.
 *
 *	This program is distributed in the hope that it will be useful,
 *	but WITHOUT ANY WARRANTY; without even the implied warranty of
 *	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *	GNU General Public License for more details.
 *
 *	Contact info: gmt.soest.hawaii.edu
 *--------------------------------------------------------------------*/

/*
 blockmedian.c
 Takes lon, lat, data, [weight] on GMT_stdin or file and writes out one value
 per cell, where cellular region is bounded by West East South North and
 cell dimensions are delta_x, delta_y.  While the word median is used in most
 places, we actually compute a quantile [which by default is 50%, i.e., the median].
 
 Author: 	Walter H. F. Smith
 Date:	28 June, 1988
 Modified	26 April, 1991 for gmt v2.0 by whfs smith;
 added dynamic memory allocation.
 Modified:	3 Jan 1995 by PW for gmt 3.0
 Modified:	3 May 1998 by PW for gmt 3.1
 Modified:	29 Oct 1998 by WHFS to add -Q option
 Modified:	3.3.5: 10 Jul 2000 by PW to add -L
 Version:	3.4 01-MAR-2001 by PW, Use -F instead of -N, and add -C
 Version:	4 01-MAR-2003 by PW
 Version:	4.1: 14-SEP-2005 by PW, Added enhanced -I
 Version	4.1.2: 24-MAR-2006 by PW: No longer defines global variables. Use double to hold data.
 4-APR-2006 by PW: Added -E for L1 scale, low, and high value, and -T to set quantile
 Also implemented size_t counters to be 64-bit compatible.
 5-MAR-2008 by PW: Added -Eb to produce box-and-whisker output (all 5 quantiles)
 */

#define BLOCKMEDIAN

#include "gmt.h"
#include "block_subs.h"

int main (int argc, char **argv)
{
	
	GMT_LONG	error = FALSE, nofile = TRUE, done = FALSE, first = TRUE, box_and_whisker = FALSE;
	
	FILE *fp = NULL;
	
	double	*in = NULL, out[7+1], wesn[4], quantile[3] = {0.25, 0.5, 0.75}, extra[3], weight, *z_tmp = NULL;
	
	GMT_LONG	i, ix, iy, fno, n_files = 0, n_args, n_req, w_col;
	GMT_LONG	n_expected_fields, n_fields, n_out, n_quantiles = 1, go_quickly = 0;
	/* Default value for go_quickly = 0 for backward compatibility with GMT 3.0  */
	
	GMT_LONG	nz, n_read, n_cells_filled, n_lost, index;
	GMT_LONG	first_in_cell, first_in_new_cell;
	GMT_LONG	n_alloc = 0, nz_alloc = 0, n_pitched;
	
	char	modifier, buffer[BUFSIZ], format[BUFSIZ];
	
	struct GRD_HEADER h;
	
	struct BLK_DATA *data = NULL;
	struct BLOCKMEDIAN_CTRL *Ctrl = NULL;
	
	void median_output (struct GRD_HEADER *h, GMT_LONG first_in_cell, GMT_LONG first_in_new_cell, double weight_sum, double *out,
						double *extra, GMT_LONG go_quickly, double *quantile, GMT_LONG n_quantiles, struct BLK_DATA *data);
	
	argc = (int)GMT_begin (argc, argv);
	
	Ctrl = (struct BLOCKMEDIAN_CTRL *) New_blockmedian_Ctrl ();	/* Allocate and initialize a new control structure */
	
	GMT_grd_init (&h, argc, argv, FALSE);
	
	for (i = 1; i < argc; i++) {
		if (argv[i][0] == '-') {
			switch (argv[i][1]) {
					
					/* Common parameters */
					
				case 'H':
				case 'R':
				case 'V':
				case ':':
				case 'b':
				case 'f':
				case '\0':
					error += GMT_parse_common_options (argv[i], &h.x_min, &h.x_max, &h.y_min, &h.y_max);
					break;
					
					/* Supplemental parameters */
					
				case 'C':
					Ctrl->C.active = TRUE;
					break;
				case 'E':
					Ctrl->E.active = TRUE;				/* Extended report with standard deviation, min, and max in cols 4-6 */
					if (argv[i][2] == 'b') Ctrl->E.mode = 1;	/* Extended report with min, 25%, 75% and max in cols 4-7 */
					break;
				case 'I':
					Ctrl->I.active = TRUE;
					if (GMT_getinc (&argv[i][2], &Ctrl->I.xinc, &Ctrl->I.yinc)) {
						GMT_inc_syntax ('I', 1);
						error = TRUE;
					}
					break;
				case 'L':	/* Obsolete, but backward compatibility prevails [use -f instead] */
					GMT_io.in_col_type[GMT_X] = GMT_io.out_col_type[GMT_X] = GMT_IS_LON;
					GMT_io.in_col_type[GMT_Y] = GMT_io.out_col_type[GMT_Y] = GMT_IS_LAT;
					fprintf (stderr, "%s: Option -L is obsolete (but is processed correctly).  Please use -f instead\n", GMT_program);
					break;
				case 'N':	/* Backward compatible with 3.3.6 */
				case 'F':
					Ctrl->F.active = TRUE;
					break;
				case 'Q':
					Ctrl->Q.active = TRUE;		/* Get median z and (x,y) of that point */
					break;
				case 'T':
					Ctrl->T.active = TRUE;		/* Extended report with standard deviation, min, and max in cols 4-6 */
					Ctrl->T.quantile = atof (&argv[i][2]);
					break;
				case 'W':
					Ctrl->W.active = TRUE;
					if ( (modifier = argv[i][2]) == 'i' || modifier == 'I')
						Ctrl->W.weighted[GMT_IN] = TRUE;
					else if (modifier == 'O' || modifier == 'o')
						Ctrl->W.weighted[GMT_OUT] = TRUE;
					else
						Ctrl->W.weighted[GMT_IN] = Ctrl->W.weighted[GMT_OUT] = TRUE;
					break;
					
				default:
					error = TRUE;
					GMT_default_error (argv[i][1]);
					break;
			}
		}
		else
			n_files++;
	}
	
	if (argc == 1 || GMT_give_synopsis_and_exit) {
		fprintf (stderr, "medianId %s - Block averaging by L1 norm\n\n", GMT_VERSION);
		fprintf (stderr, "usage: medianId [infile(s)] %s %s\n", GMT_I_OPT, GMT_Rgeo_OPT);
		fprintf (stderr, "\t[-C] [-E] [-F] [%s] [-Q] [-T<q>] [-V] [-W[i][o] ] [%s] [%s]\n", GMT_H_OPT, GMT_t_OPT, GMT_b_OPT);
		fprintf (stderr, "\t[%s]\n\n", GMT_f_OPT);
		
		if (GMT_give_synopsis_and_exit) exit (EXIT_FAILURE);
		
		GMT_inc_syntax ('I', 0);
		GMT_explain_option ('R');
		fprintf (stderr, "\n\tOPTIONS:\n");
		fprintf (stderr, "\t-C Output center of block as location [Default is (median x, median y), but see -Q].\n");
		fprintf (stderr, "\t-E Extend output with L1 scale (s), low (l), and high (h) value per block, i.e.,\n");
		fprintf (stderr, "\t   output (x,y,z,s,l,h[,w]) [Default outputs (x,y,z[,w]); see -W regarding w.\n");
		fprintf (stderr, "\t   Use -Eb for box-and-whisker output (x,y,z,l,25%%q,75%%q,h[,w])\n");
		fprintf (stderr, "\t-F Offsets registration so block edges are on gridlines (pixel reg.) [Default: grid reg.].\n");
		GMT_explain_option ('H');
		fprintf (stderr, "\t-Q Quicker; get median z and x,y at that z [Default gets median x, median y, median z].\n");
		fprintf (stderr, "\t-T Set quantile (0 < q < 1) to report [Default is 0.5 which is the median of z].\n");
		GMT_explain_option ('V');
		fprintf (stderr, "\t-W sets Weight options.\n");
		fprintf (stderr, "\t   -Wi reads Weighted Input (4 cols: x,y,z,w) but skips w on output.\n");
		fprintf (stderr, "\t   -Wo reads unWeighted Input (3 cols: x,y,z) but weight sum on output.\n");
		fprintf (stderr, "\t   -W with no modifier has both weighted Input and Output; Default is no weights used.\n");
		GMT_explain_option (':');
		GMT_explain_option ('i');
		GMT_explain_option ('n');
		fprintf (stderr, "\t   Default is 3+1 columns (or 4+1 if -W is set).\n");
		GMT_explain_option ('o');
		GMT_explain_option ('n');
		GMT_explain_option ('f');
		GMT_explain_option ('.');
		exit (EXIT_FAILURE);
	}
	
	GMT_check_lattice (&Ctrl->I.xinc, &Ctrl->I.yinc, &Ctrl->F.active, &Ctrl->I.active);
	
	if (Ctrl->C.active && go_quickly == 1) {
		fprintf (stderr, "%s: GMT WARNING: -C overrides -Q\n", GMT_program);
		go_quickly = 0;
	}
	
	if (!project_info.region_supplied) {
		fprintf (stderr, "%s: GMT SYNTAX ERROR: Must specify -R option\n", GMT_program);
		error++;
	}
	if (Ctrl->T.quantile <= 0.0 || Ctrl->T.quantile >= 1.0) {
		fprintf (stderr, "%s: GMT SYNTAX ERROR: 0 < q < 1 for quantile in -T [0.5]\n", GMT_program);
		error++;
	}
	if (Ctrl->I.xinc <= 0.0 || Ctrl->I.yinc <= 0.0) {
		fprintf (stderr, "%s: GMT SYNTAX ERROR -I option.  Must specify positive increment(s)\n", GMT_program);
		error = TRUE;
	}
	if (GMT_io.binary[GMT_IN] && GMT_io.io_header[GMT_IN]) {
		fprintf (stderr, "%s: GMT SYNTAX ERROR.  Binary input data cannot have header -H\n", GMT_program);
		error++;
	}
	n_req = (Ctrl->W.weighted[GMT_IN]) ? 4+1 : 3+1;
	if (GMT_io.binary[GMT_IN] && GMT_io.ncol[GMT_IN] == 0) GMT_io.ncol[GMT_IN] = n_req;
	if (GMT_io.binary[GMT_IN] && n_req > GMT_io.ncol[GMT_IN]) {
		fprintf (stderr, "%s: GMT SYNTAX ERROR.  binary input data must have at least %ld columns\n", GMT_program, n_req);
		error++;
	}
	
	if (error) exit (EXIT_FAILURE);
	
	if (GMT_io.binary[GMT_IN] && gmtdefs.verbose) {
		char *type[2] = {"double", "single"};
		fprintf (stderr, "%s: Expects %ld-column %s-precision binary data\n", GMT_program, GMT_io.ncol[GMT_IN], type[GMT_io.single_precision[GMT_IN]]);
	}
	
#ifdef SET_IO_MODE
	GMT_setmode (GMT_OUT);
#endif
	
	h.x_inc = Ctrl->I.xinc;
	h.y_inc = Ctrl->I.yinc;
	h.node_offset = (int)Ctrl->F.active;
	GMT_RI_prepare (&h);	/* Ensure -R -I consistency and set nx, ny */
	
	go_quickly = (Ctrl->Q.active) ? 1 : 0;	
	if (Ctrl->C.active) go_quickly = 2;	/* Flag used in output calculation */
	if (Ctrl->E.active && Ctrl->E.mode == 1) {
		n_quantiles = 3;
		box_and_whisker = TRUE;
	}
	else
		quantile[0] = Ctrl->T.quantile;
	
	h.xy_off = 0.5 * h.node_offset;		/* Use to calculate mean location of block */
	
	if (gmtdefs.verbose) {
		sprintf (format, "%%s: W: %s E: %s S: %s N: %s nx: %%ld ny: %%ld\n", gmtdefs.d_format, gmtdefs.d_format, gmtdefs.d_format, gmtdefs.d_format);
		fprintf (stderr, format, GMT_program, h.x_min, h.x_max, h.y_min, h.y_max, h.nx, h.ny);
	}
	
	n_read = n_pitched = 0;
	
	GMT_set_xy_domain (wesn, &h);	/* May include some padding if gridline-registered */
	
	/* Read the input data  */
	
	n_expected_fields = (GMT_io.binary[GMT_IN]) ? GMT_io.ncol[GMT_IN] : 3+1 + Ctrl->W.weighted[GMT_IN];
	
	if (n_files > 0)
		nofile = FALSE;
	else
		n_files = 1;
	n_args = (argc > 1) ? argc : 2;
	
	for (fno = 1; !done && fno < n_args; fno++) {	/* Loop over input files, if any */
		if (!nofile && argv[fno][0] == '-') continue;
		
		if (nofile) {	/* Just read standard input */
			fp = GMT_stdin;
			done = TRUE;
#ifdef SET_IO_MODE
			GMT_setmode (GMT_IN);
#endif
		}
		else if ((fp = GMT_fopen (argv[fno], GMT_io.r_mode)) == NULL) {
			fprintf (stderr, "%s: Cannot open file %s\n", GMT_program, argv[fno]);
			continue;
		}
		
		if (!nofile && gmtdefs.verbose) fprintf (stderr, "%s: Working on file %s\n", GMT_program, argv[fno]);
		
		if (GMT_io.io_header[GMT_IN]) {
			for (i = 0; i < GMT_io.n_header_recs; i++) {
				GMT_fgets (buffer, BUFSIZ, fp);
				GMT_chop (buffer);
				if (first && GMT_io.io_header[GMT_OUT]) {
					(Ctrl->W.weighted[GMT_OUT] && !(Ctrl->W.weighted[GMT_IN])) ? sprintf (format, "%s weights\n", buffer) : sprintf (format, "%s\n", buffer);
					GMT_fputs(format, GMT_stdout);
				}
			}
			first = FALSE;
		}
		
		while ((n_fields = GMT_input (fp, &n_expected_fields, &in)) >= 0 && !(GMT_io.status & GMT_IO_EOF)) {	/* Not yet EOF */
			
			n_read++;
			
			if (GMT_io.status & GMT_IO_MISMATCH) {
				fprintf (stderr, "%s: Mismatch between actual (%ld) and expected (%ld) fields near line %ld (skipped)\n", GMT_program, n_fields,  n_expected_fields, n_read);
				continue;
			}
			
			if (GMT_is_dnan (in[GMT_Z])) continue;	/* Skip when z = NaN */
			
			if (GMT_y_is_outside (in[GMT_Y],  wesn[2], wesn[3])) continue;	/* Outside y-range */
			if (GMT_x_is_outside (&in[GMT_X], wesn[0], wesn[1])) continue;	/* Outside x-range */
			
			ix = GMT_x_to_i (in[GMT_X], h.x_min, h.x_inc, h.xy_off, h.nx);
			if ( ix < 0 || ix >= h.nx ) continue;
			iy = GMT_y_to_j (in[GMT_Y], h.y_min, h.y_inc, h.xy_off, h.ny);
			if ( iy < 0 || iy >= h.ny ) continue;

			index = GMT_IJ (iy, ix, h.nx);		/* 64-bit safe 1-D index */
			
			if (n_pitched == n_alloc) n_alloc = GMT_alloc_memory ((void **)&data, n_pitched, n_alloc, sizeof (struct BLK_DATA), GMT_program);
			data[n_pitched].i = index;
			data[n_pitched].a[BLK_W] = ((Ctrl->W.weighted[GMT_IN]) ? in[3+1] : 1.0);
			if (!Ctrl->C.active) {
				data[n_pitched].a[BLK_X] = in[GMT_X];
				data[n_pitched].a[BLK_Y] = in[GMT_Y];
			}
			data[n_pitched].a[BLK_Z] = in[GMT_Z];
			data[n_pitched].sid      = (unsigned short)in[3];
			
			n_pitched++;
		}
		if (fp != GMT_stdin) GMT_fclose(fp);
		
	}
	if (n_pitched < n_alloc) n_alloc = GMT_alloc_memory ((void **)&data, 0, n_pitched, sizeof (struct BLK_DATA), GMT_program);
	
	if (n_read == 0) {	/* Blank/empty input files */
		if (gmtdefs.verbose) fprintf (stderr, "%s: No data records found; no output produced\n", GMT_program);
		exit (EXIT_SUCCESS);
	}
	if (n_pitched == 0) {	/* No points inside region */
		if (gmtdefs.verbose) fprintf (stderr, "%s: No data points found inside the region; no output produced\n", GMT_program);
		exit (EXIT_SUCCESS);
	}
	n_lost = n_read - (GMT_LONG)n_pitched;
	if (gmtdefs.verbose) fprintf(stderr,"%s: N read: %ld N used: %ld N outside_area: %ld\n", GMT_program, n_read, (GMT_LONG)n_pitched, n_lost);
	
	/* Ready to go. */
	
	n_out = (Ctrl->W.weighted[GMT_OUT]) ? 4+1 : 3+1;
	if (Ctrl->E.active) n_out += 3 + (int)box_and_whisker;	/* So, 3, 6, or 7, plus 1 extra if -W */
	w_col = n_out - 1;	/* Weights always reported in last output column */
	
	/* Sort on index and Z value */
	
	qsort((void *)data, (size_t)n_pitched, sizeof (struct BLK_DATA), BLK_compare_index_z);
	
	/* Find n_in_cell and write appropriate output  */
	
	first_in_cell = n_cells_filled = nz = 0;
	while (first_in_cell < n_pitched) {
		weight = data[first_in_cell].a[BLK_W];
		if (Ctrl->E.active) {
			if (nz == nz_alloc) nz_alloc = GMT_alloc_memory ((void **)&z_tmp, nz, nz_alloc, sizeof (double), GMT_program);
			z_tmp[0] = data[first_in_cell].a[BLK_Z];
			nz = 1;
		}
		first_in_new_cell = first_in_cell + 1;
		while ( (first_in_new_cell < n_pitched) && (data[first_in_new_cell].i == data[first_in_cell].i) ) {
			weight += data[first_in_new_cell].a[BLK_W];
			if (Ctrl->E.active) {	/* Must get a temporary copy of the sorted z array */
				if (nz == nz_alloc) nz_alloc = GMT_alloc_memory ((void **)&z_tmp, nz, nz_alloc, sizeof (double), GMT_program);
				z_tmp[nz++] = data[first_in_new_cell].a[BLK_Z];
			}
			first_in_new_cell++;
		}
		
		/* Now we have weight sum [and copy of z in case of -E]; now calculate the quantile(s): */

		/* IMPORTANT NOTE!!!
		 median_output will (possibly) sort data by x, and y, so you can NOT assume data is still sorted 
		 */		
		median_output (&h, first_in_cell, first_in_new_cell, weight, out, extra, go_quickly, quantile, n_quantiles, data);
		
		if (box_and_whisker) {	/* Need 7 items: x, y, median, min, 25%, 75%, max [,weight] */
			out[3+1] = z_tmp[0];	/* 0% quantile (min value) */
			out[4+1] = extra[0];	/* 25% quantile */
			out[5+1] = extra[2];	/* 75% quantile */
			out[6+1] = z_tmp[nz-1];	/* 100% quantile (max value) */
		}
		else if (Ctrl->E.active) {	/* Need 6 items: x, y, median, MAD, min, max [,weight] */
			out[4+1] = z_tmp[0];	/* Low value */
			out[5+1] = z_tmp[nz-1];	/* High value */
			/* Turn z_tmp into absolute deviations from the median (out[GMT_Z]) */
			if (nz > 1) {
				for (index = 0; index < nz; index++) z_tmp[index] = fabs (z_tmp[index] - out[GMT_Z]);
				qsort ((void *)z_tmp, (size_t)nz, sizeof (double), GMT_comp_double_asc);
				out[3+1] = (nz%2) ? z_tmp[nz/2] : 0.5 * (z_tmp[(nz-1)/2] + z_tmp[nz/2]);
				out[3+1] *= 1.4826;	/* This will be L1 MAD-based scale */
			}
			else
				out[3+1] = GMT_d_NaN;
		}
		if (Ctrl->W.weighted[GMT_OUT]) out[w_col+1] = weight;
		
		GMT_output (GMT_stdout, n_out, out);
		
		n_cells_filled++;
		first_in_cell = first_in_new_cell;
	}
	
	if (gmtdefs.verbose) fprintf(stderr,"%s: N_cells_filled: %ld\n", GMT_program, n_cells_filled);
	
	GMT_free ((void *)data);
	GMT_free ((void *)z_tmp);
	
	Free_blockmedian_Ctrl (Ctrl);	/* Deallocate control structure */
	
	GMT_end (argc, argv);
	
	exit (EXIT_SUCCESS);
}

void median_output (struct GRD_HEADER *h, GMT_LONG first_in_cell, GMT_LONG first_in_new_cell, double weight_sum, double *out,
					double *extra, GMT_LONG go_quickly, double *quantile, GMT_LONG n_quantiles, struct BLK_DATA *data)
{
	double	weight_half, weight_count;
	GMT_LONG index, n_in_cell, index1;
	GMT_LONG k, k_for_xy;
	
	/* Remember: Data are already sorted on z for each cell */
	
	/* Step 1: Find the n_quantiles requested (typically only one unless -Eb was used) */
	
	n_in_cell = first_in_new_cell - first_in_cell;
	index = first_in_cell;
	weight_count = data[first_in_cell].a[BLK_W];
	k_for_xy = (n_quantiles == 3) ? 1 : 0;	/* If -Eb is set get get median location, else same as for z (unless -Q) */
	for (k = 0; k < n_quantiles; k++) {
		
		weight_half  = quantile[k] * weight_sum;	/* Normally, quantile will be 0.5 (i.e., median), hence the name of the variable */
		
		/* Determine the point where we hit the desired quantile */
		
		while (weight_count < weight_half) weight_count += data[++index].a[BLK_W];	/* Wind up until weight_count hits the mark */
		
		if ( weight_count == weight_half ) {
			index1 = index + 1;
			extra[k] = 0.5 * (data[index].a[BLK_Z] + data[index1].a[BLK_Z]);
			if (k == k_for_xy && go_quickly == 1) {	/* Only get x,y at the z-quantile if requested [-Q] */
				out[GMT_X] = 0.5 * (data[index].a[BLK_X] + data[index1].a[BLK_X]);
				out[GMT_Y] = 0.5 * (data[index].a[BLK_Y] + data[index1].a[BLK_Y]);
				out[3] = (double)data[index1].sid;
			}
		}
		else {
			extra[k] = data[index].a[BLK_Z];
			if (k == k_for_xy && go_quickly == 1) {	/* Only get x,y at the z-quantile if requested [-Q] */
				out[GMT_X] = data[index].a[BLK_X];
				out[GMT_Y] = data[index].a[BLK_Y];
				out[3] = (double)data[index].sid;
			}
		}
	}
	out[GMT_Z] = extra[k_for_xy];	/* The desired quantile is passed via z */
	out[3] = (double)data[index].sid;
	
	if (go_quickly == 1) return;	/* Already have everything requested so we return */
	
	if (go_quickly == 2) {	/* Return center of block instead of computing a representative location */
		GMT_LONG i, j;
		j = data[index].i / ((GMT_LONG)h->nx);
		i = data[index].i % ((GMT_LONG)h->nx);
		out[GMT_X] = GMT_i_to_x (i, h->x_min, h->x_max, h->x_inc, h->xy_off, h->nx);
		out[GMT_Y] = GMT_j_to_y (j, h->y_min, h->y_max, h->y_inc, h->xy_off, h->ny);
		return;
	}
	
	/* We get here when we need separate quantile calculations for both x and y locations */
	
	weight_half = quantile[k_for_xy] * weight_sum;	/* We want the same quantile for locations as was used for z */
	
	if (n_in_cell > 2) qsort((void *)&data[first_in_cell], (size_t)n_in_cell, sizeof (struct BLK_DATA), BLK_compare_x);
	index = first_in_cell;
	weight_count = data[first_in_cell].a[BLK_W];
	while (weight_count < weight_half) weight_count += data[++index].a[BLK_W];
	out[GMT_X] = ( weight_count == weight_half ) ?  0.5 * (data[index].a[BLK_X] + data[index + 1].a[BLK_X]) : data[index].a[BLK_X];
	
	if (n_in_cell > 2) qsort((void *)&data[first_in_cell], (size_t)n_in_cell, sizeof (struct BLK_DATA), BLK_compare_y);
	index = first_in_cell;
	weight_count = data[first_in_cell].a[BLK_W];
	while (weight_count < weight_half) weight_count += data[++index].a[BLK_W];
	out[GMT_Y] = ( weight_count == weight_half ) ? 0.5 * (data[index].a[BLK_Y] + data[index + 1].a[BLK_Y]) : data[index].a[BLK_Y];
}

#ifdef USEOLDSTUFF
void median_output (struct GRD_HEADER *h, GMT_LONG first_in_cell, GMT_LONG first_in_new_cell, double weight_sum, double *xx, double *yy, double *zz, GMT_LONG go_quickly, double quantile, struct BLK_DATA *data)
{
	double	weight_half, weight_count;
	GMT_LONG index, n_in_cell, index1;
	
	weight_half  = quantile * weight_sum;	/* Normally, quantile will be 0.5 hence the name of the variable */
	n_in_cell = first_in_new_cell - first_in_cell;
	
	/* Data are already sorted on z  */
	
	/* Determine the point where we hit the desired quantile */
	
	index = first_in_cell;
	weight_count = data[first_in_cell].a[BLK_W];
	while (weight_count < weight_half) {
		index++;
		weight_count += data[index].a[BLK_W];
	}
	if ( weight_count == weight_half ) {
		index1 = index + 1;
		*xx = 0.5 * (data[index].a[BLK_X] + data[index1].a[BLK_X]);
		*yy = 0.5 * (data[index].a[BLK_Y] + data[index1].a[BLK_Y]);
		*zz = 0.5 * (data[index].a[BLK_Z] + data[index1].a[BLK_Z]);
	}
	else {
		*xx = data[index].a[BLK_X];
		*yy = data[index].a[BLK_Y];
		*zz = data[index].a[BLK_Z];
	}
	
	/* Now get median x and median y if quick x and quick y not wanted:  */
	
	if (go_quickly == 1) return;
	
	if (go_quickly == 2) {	/* Get center of block */
		GMT_LONG i, j;
		j = data[index].i / ((GMT_LONG)h->nx);
		i = data[index].i % ((GMT_LONG)h->nx);
		*xx = GMT_i_to_x (i, h->x_min, h->x_max, h->x_inc, h->xy_off, h->nx);
		*yy = GMT_j_to_y (j, h->y_min, h->y_max, h->y_inc, h->xy_off, h->ny);
		return;
	}
	
	/* We get here when we need median x,y locations */
	
	weight_half = 0.5 * weight_sum;	/* We want the median location */
	if (n_in_cell > 2) qsort((void *)&data[first_in_cell], (size_t)n_in_cell, sizeof (struct BLK_DATA), BLK_compare_x);
	index = first_in_cell;
	weight_count = data[first_in_cell].a[BLK_W];
	while (weight_count < weight_half) {
		index++;
		weight_count += data[index].a[BLK_W];
	}
	if ( weight_count == weight_half )
		*xx = 0.5 * (data[index].a[BLK_X] + data[index + 1].a[BLK_X]);
	else
		*xx = data[index].a[BLK_X];
	
	if (n_in_cell > 2) qsort((void *)&data[first_in_cell], (size_t)n_in_cell, sizeof (struct BLK_DATA), BLK_compare_y);
	index = first_in_cell;
	weight_count = data[first_in_cell].a[BLK_W];
	while (weight_count < weight_half) {
		index++;
		weight_count += data[index].a[BLK_W];
	}
	if ( weight_count == weight_half )
		*yy = 0.5 * (data[index].a[BLK_Y] + data[index + 1].a[BLK_Y]);
	else
		*yy = data[index].a[BLK_Y];
}
#endif
#include "block_subs.c"
