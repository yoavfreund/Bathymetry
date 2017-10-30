1)  The workflow starts with a custom CM_EDITOR that runs on a mac.  ( I think you saw this one and it runs fine right now.)   This is for a human to screen the bad data.  This is where the machine learning should assist.

2) The we use Generic Mapping Tools GMT to do most of the work which is creating matching grids of depth and source ID. GMT is very powerful but has a steep learning curve.

3) Then we use the NASA StereoToolkit to convert geotiff maps to a piramid of KML for Google Earth.

5) Then the human editor uses Google Earth to isolate bad data and draw polygons.

6) There polygons are sent back to the data base to flag the outliers.

Go to 1 or 2) and do it again.

