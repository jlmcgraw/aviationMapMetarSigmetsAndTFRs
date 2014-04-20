#!/usr/bin/perl

#This program takes the .XML of the list of the current *METs from the FAA website,
#then converts to a .CSV with a geometry definition suitable for loading into QGIS etc and outputs to stdout

use strict;
use warnings;
use autodie;

use XML::LibXML;

use v5.10;

#input data file
my $data_xml = './airsigmets.cache.xml';

#Print the header for the .csv file
say
'rawText;validTimeFrom;validTimeTo;geometry;altitudeMinFtMsl;altitudeMaxFtMsl;hazardType;hazardSeverity;airsigmetType';

my $parser = XML::LibXML->new();

#Then parse it
my $xmldoc = XML::LibXML->load_xml( location => ($data_xml) );

#Loop through each area definition in the *MET and pull out relevant data
foreach my $airsigmet ( $xmldoc->findnodes('/response/data/AIRSIGMET') ) {

    my ( $hazard, $hazardType, $hazardSeverity );

    #This is a list
    ($hazard) = $airsigmet->findnodes('./hazard');

    if ($hazard) {
        $hazardType     = $hazard->getAttribute('type');
        $hazardSeverity = $hazard->getAttribute('severity');
    }

    next if ( $hazardType eq "CONVECTIVE" && $hazardSeverity eq "NONE" );

    my $rawText       = $airsigmet->findnodes('./raw_text')->to_literal;
    my $validTimeFrom = $airsigmet->findnodes('./valid_time_from')->to_literal;
    my $validTimeTo   = $airsigmet->findnodes('./valid_time_to')->to_literal;

    my ( $altitude, $altitudeMinFtMsl, $altitudeMaxFtMsl );

    #This is a list
    ($altitude) = $airsigmet->findnodes('./altitude');

    if ($altitude) {
        $altitudeMinFtMsl = $altitude->getAttribute('min_ft_msl');
        $altitudeMaxFtMsl = $altitude->getAttribute('max_ft_msl');
    }

    my $airsigmetType = $airsigmet->findnodes('./airsigmet_type')->to_literal;

    #Sanitize the variables
    $rawText =~ s/;//g;

    #Enclose the text in quotes
    $rawText = "\"" . $rawText . "\"";

    my @polygon;

    #Pull out the polygon definition coordinates for each *MET polygon
    foreach my $area ( $airsigmet->findnodes('./area/point') ) {
        my $lat = $area->findnodes('./latitude')->to_literal;
        my $lon = $area->findnodes('./longitude')->to_literal;

        #Save each point to our @polygon array
        push( @polygon, $lon . " " . $lat );

    }

#Create a POLYGON WKT definition by joining together all of the points in the polygon array
    my $geometry = "POLYGON ((" . join( ' , ', @polygon ) . "))";

    {
        #Disable these warnings for this block
        no warnings 'uninitialized';
        say
"$rawText;$validTimeFrom;$validTimeTo;$geometry;$altitudeMinFtMsl;$altitudeMaxFtMsl;$hazardType;$hazardSeverity;$airsigmetType";
    }
}
