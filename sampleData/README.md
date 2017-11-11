# Features
        names = ['long','lat','depth','sigma_h','sigma_d','source_id','pred_depth','dens20', 'dens60','gravity','age','rate','sed thick', 'roughness']

That is the feature names array in the python script that I'm running.

---
## This section described the columns in sample.cm in the respective order.
## long

Pretty much as the name suggests, it is the longitude of the data collected.

## lat

Latitude of where the data was collected.

## depth

This is the measured depth.

## sigma_h

Like in statistics, this sigma stands for the horizontal standard deviation.

## sigma_d

A placeholder, feature. We use this column to store the bad data flag.

## source_id

This is the assigned id for the ship's cruise, this will probably make a good key for the sql db..

## pred_depth

This is the predicted depth using an algorithm.

---
## Everything below is added by data extracted from a grd file.
## dens20/dens60

## gravity

## age

This is the age of the seafloor.

## rate

## sed thickness

This is the floor's sediment thickness

## roughness

This is a measure of how rough the seafloor is.
