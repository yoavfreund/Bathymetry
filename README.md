# Bathymetry

This repository holds the software for the batheymetry data editing software used by [David Sandwell](http://topex.ucsd.edu/sandwell/)
and his students, working in collaboration with [Yoav Freund](https://cseweb.ucsd.edu/~yfreund/) and his students.

## Organization of the software

The raw data is in `.cm` files. There is a master index file called `sid_filelist.txt`

### Initial filtering software

This software is called CM_EDIT. It takes as input a file corresponding to a single cruise. Display the data visually using apple xcode and lets the user flag (9999) the noisy measurements.

### Assemble the information from a geographic area.

The information from the edited raw data is windowed and then used to create a full image using interpolation. This is performed by the following software:

`maketile` script runs the following steps.
1. GMT/block-median: remove outliers using a median filter.
2. GMT/grd_track: removes a model depth from the data (computes residual)
3. GMT/surface: Interpolation of the residual generates a grid of image. (`netcdf` files)
4. GMT/grdmath: Add the residual grid back the current map.
5. GMT/landmask: creates a grid of land masks. (is it land or ocean).
6. GMT/grdmath: Combines topography and bathymetry based on the land mask.
7. GMT/create the map: produce the geotiff.

### Stereo toolkit from NASA
Takes as input the geotiff and produces a pyrmidal representation that can be used in google maps (`kml` files)

## Human correction
A human goes through the google map and marks polygons at the places that are judged incorrect.

Software that takes the polygons and marks (9999) those locations in the measurements (`cm` files)

### Machine Learning Software.

## Organization of the repository.

## databse
organization
| col      |        type   |   XX    |
| organization_id | int | PRIMARY KEY |
| name | varchar(255) |    |
| access_method | varchar(255) |    |
    
| First Header  | Second Header |
| ------------- | ------------- |
| Content Cell  | Content Cell  |
| Content Cell  | Content Cell  |
