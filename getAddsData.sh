#!/bin/bash
set -eu                # Always put this in Bourne shell scripts
IFS="`printf '\n\t'`"  # Always put this in Bourne shell scripts

## Clean out old data
# rm ./aircraftreports.cache.csv.gz
# rm ./airsigmets.cache.xml.gz
# rm ./metars.cache.csv.gz
# rm ./tafs.cache.csv.gz

# rm ./aircraftreports.cache.csv
# rm ./airsigmets.cache.csv
# rm ./metars.cache.csv
# rm ./tafs.cache.csv
# rm ./mergedTfrs.csv

#Experimental server
# wget -N http://weather.aero/dataserver_current/cache/aircraftreports.cache.csv.gz
##Use the XML for AIR/SIGMETS because CSV has polygon data errors
## wget -N http://weather.aero/dataserver_current/cache/airsigmets.cache.csv.gz
# wget -N http://weather.aero/dataserver_current/cache/airsigmets.cache.xml.gz
# wget -N http://weather.aero/dataserver_current/cache/metars.cache.csv.gz
# wget -N http://weather.aero/dataserver_current/cache/tafs.cache.csv.gz

#Stable server
wget -N http://aviationweather.gov/adds/dataserver_current/current/aircraftreports.cache.csv.gz
#Use the XML for AIR/SIGMETS because currently the CSV has polygon data errors
#wget -N http://aviationweather.gov/adds/dataserver_current/current/airsigmets.cache.csv.gz
wget -N http://aviationweather.gov/adds/dataserver_current/current/airsigmets.cache.xml.gz
wget -N http://aviationweather.gov/adds/dataserver_current/current/metars.cache.csv.gz
wget -N http://aviationweather.gov/adds/dataserver_current/current/tafs.cache.csv.gz

#Unzip ADDS data
gunzip -f *.gz

#Process the airmets/sigmets file to produce polygons
#perl airsig.pl > airsigmets.cache.csv
perl airmetSigmet.pl > airsigmets.cache.csv

#Download TFRs from FAA and produce a .csv with geometry to stdout
perl tfr.pl > mergedTfrs.csv