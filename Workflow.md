OBJECTIVES
  The overall objective of this project is to create two global grids at 30 and 15 arcsecond resolution.  One arcsecond is 1/60 of a degree.  15 arcseconds is about 500 m spatial resolution at the equator.  The first grid is topography/bathymetry at 1 m vertical quantization.  The second grid is the source identification number (SID) that is used to determine which data product was used to create the bathymetry of that cell.  Here is the information from the netcdf headers:
  
topo30.grd: Title: topo30.grd
topo30.grd: Command: xyz2grd -V -Rg -I30c topo30 -Gtopo30.grd=ns -ZTLhw -F
topo30.grd: Remark: 
topo30.grd: Pixel node registration used [Geographic grid]
topo30.grd: Grid file format: ns = GMT netCDF format (16-bit integer), COARDS, CF-1.5
topo30.grd: x_min: 0 x_max: 360 x_inc: 0.00833333333333 name: longitude [degrees_east] n_columns: 43200
topo30.grd: y_min: -90 y_max: 90 y_inc: 0.00833333333333 name: latitude [degrees_north] n_rows: 21600
topo30.grd: z_min: -10921 z_max: 8685 name: z
topo30.grd: scale_factor: 1 add_offset: 0
topo30.grd: format: classic

topo30_sid.grd: Title: topo30_sid.grd
topo30_sid.grd: Command: xyz2grd -V -R00/360/-90/90 -I30c topo30_sid -Gtopo30_sid.grd -ZTLHw -F
topo30_sid.grd: Remark: 
topo30_sid.grd: Pixel node registration used [Cartesian grid]
topo30_sid.grd: Grid file format: nf = GMT netCDF format (32-bit float), COARDS, CF-1.5
topo30_sid.grd: x_min: 0 x_max: 360 x_inc: 0.00833333333333 name: x n_columns: 43200
topo30_sid.grd: y_min: -90 y_max: 90 y_inc: 0.00833333333333 name: y n_rows: 21600
topo30_sid.grd: z_min: 0 z_max: 65506 name: z
topo30_sid.grd: scale_factor: 1 add_offset: 0
topo30_sid.grd: format: classic

DATA

There are three types of data used for this analysis:  
1) Land areas have complete coverage from SRTM and a variety of other sources so no interpolation is needed.
2) Ocean areas and some large bodies of water have depth pre

WORKFLOW

1)  The workflow starts with a custom CM_EDITOR that runs on a mac.  ( I think you saw this one and it runs fine right now.)   This is for a human to screen the bad data.  This is where the machine learning should assist.

2) The we use Generic Mapping Tools GMT to do most of the work which is creating matching grids of depth and source ID. GMT is very powerful but has a steep learning curve.

3) Then we use the NASA StereoToolkit to convert geotiff maps to a piramid of KML for Google Earth.

5) Then the human editor uses Google Earth to isolate bad data and draw polygons.

6) There polygons are sent back to the data base to flag the outliers.

Go to 1 or 2) and do it again.

TODO:

