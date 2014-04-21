#!/bin/bash
set -eu                # Always put this in Bourne shell scripts
IFS="`printf '\n\t'`"  # Always put this in Bourne shell scripts

#update the data
./getAddsData.sh

#Move it to where the map expects to find it
mv ./aircraftreports.cache.csv ../aviationMap/weather/
mv ./airsigmets.cache.csv ../aviationMap/weather/
mv ./metars.cache.csv ../aviationMap/weather/
mv ./tafs.cache.csv ../aviationMap/weather/
mv ./mergedTfrs.csv ../aviationMap/tfr/

