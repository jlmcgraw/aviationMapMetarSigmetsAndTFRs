#!/bin/bash
set -eu                # Always put this in Bourne shell scripts
IFS="`printf '\n\t'`"  # Always put this in Bourne shell scripts

#update the data
./getAddsData.sh

#Move it to where the map expects to find it
mv ./aircraftreports.cache.csv ../aviationMap/data/weather/
mv ./airsigmets.cache.csv ../aviationMap/data/weather/
mv ./metars.cache.csv ../aviationMap/data/weather/
mv ./tafs.cache.csv ../aviationMap/data/weather/
mv ./mergedTfrs.csv ../aviationMap/data/tfr/

#Clear out old data
rm airsigmets.cache.xml