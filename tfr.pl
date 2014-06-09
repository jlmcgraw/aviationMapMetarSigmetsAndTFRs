#!/usr/bin/perl -w

#This program obtains a list of the current TFRs from the FAA website, downloads the .XML for each
#then converts to a .CSV with a geometry definition suitable for loading into QGIS etc and outputs to 
#stdout
#
#
#Some of the code is from Zubair Kahn's tfr.pl

use strict;
use warnings;
use autodie;

use LWP::Simple;
use XML::LibXML;
use HTML::LinkExtor;
use v5.10;

# my $filename = "./tfrXml/detail_0_8326.xml";
# my $parser   = XML::LibXML->new();

#my $xmldoc   = $parser->parse_file($filename);
my @linksXml;

#my $root     = $xmldoc->getDocumentElement;

#Callback routine for link extraction
sub linkCallback {
    my ( $tag, %links ) = @_;
    my $link = "@{[%links]}\n";
#./getDocumentElementsay $link;
    if ( $link and ( -1 != index( $link, "save_pages" ) ) ) {

        #replace html to xml to get XML links
        #eg http://tfr.faa.gov/save_pages/detail_4_9441.xml
        $link =~ s/\.html/.xml/g;
        $link =~ s/\.\.//g;
        #Example link to shape files
        #http://tfr.faa.gov/save_pages/4_9441.shp.zip
        #$link =~ s/\.html/.shp.zip/g;
        #$link =~ s/detail_//g;

        $link =~ s/href\s*//g;

        #put in an array
        push( @linksXml, $link );
    }
}

#Print the header for the .csv file
say
  "sequenceNumber;txtName;valDistVerLower;uomDistVerLower;valDistVerUpper;uomDistVerUpper;dateEffective;dateExpires;txtDescrUSNS;geometry";

# get TFR list
my $tfrList = get('http://tfr.faa.gov/tfr2/list.html') or die;

# extract links from it
my $tfrLinks = new HTML::LinkExtor( \&linkCallback, 'http://tfr.faa.gov/' );
$tfrLinks->parse($tfrList);

#throw away duplicate links
my %hash = map { $_ => 1 } @linksXml;
my @unique = keys %hash;

#The list of URLs
# print "@unique\n";

for my $url ( @{unique} ) {
# say $url;
    #If we can get XML data from this URL..
    if ( my $data_xml = get($url) ) {
        my $parser = XML::LibXML->new();
       # say $data_xml;
        #Then parse it
        #my $xmldoc = $parser->parse_string($data_xml);
        my $xmldoc = XML::LibXML->load_xml( string => ( \$data_xml ) );

        #Loop through each area definition in the TFR and pull out relevant data
        foreach my $tfr (
            $xmldoc->findnodes(
                '/XNOTAM-Update/Group/Add/Not/TfrNot/TFRAreaGroup')
          )
        {
            my ($sequenceNumber) =
              $tfr->findnodes('/XNOTAM-Update/Group/Add/Not/NotUid/noSeqNo')
              ->to_literal;
            my ($name) = $tfr->findnodes('./aseTFRArea/txtName')->to_literal;
            my ($valDistVerLower) =
              $tfr->findnodes('./aseTFRArea/valDistVerLower')->to_literal;
            my ($uomDistVerLower) =
              $tfr->findnodes('./aseTFRArea/uomDistVerLower')->to_literal;
            my ($valDistVerUpper) =
              $tfr->findnodes('./aseTFRArea/valDistVerUpper')->to_literal;
            my ($uomDistVerUpper) =
              $tfr->findnodes('./aseTFRArea/uomDistVerUpper')->to_literal;

            # my ($dateEffective) =
            # $tfr->findnodes('./aseTFRArea/ScheduleGroup/dateEffective')
            # ->to_literal;
            # my ($dateExpires) =
            # $tfr->findnodes('./aseTFRArea/ScheduleGroup/dateExpire')
            # ->to_literal;
            my ($dateEffective) =
              $tfr->findnodes('/XNOTAM-Update/Group/Add/Not/dateEffective')
              ->to_literal;
            my ($dateExpires) =
              $tfr->findnodes('/XNOTAM-Update/Group/Add/Not/dateExpire')
              ->to_literal;
            my ($txtDescrUSNS) =
              $tfr->findnodes('/XNOTAM-Update/Group/Add/Not/txtDescrUSNS')
              ->to_literal;

            #Sanitize the variables
            $txtDescrUSNS =~ s/;//g;

            #Enclose the text in quotes
            $txtDescrUSNS = "\"" . $txtDescrUSNS . "\"";

            my @polygon;

            #Pull out the polygon definition coordinates for each TFRAreaGroup
            foreach my $area ( $tfr->findnodes('./abdMergedArea/Avx') ) {
                my ($lat) = $area->findnodes('./geoLat')->to_literal;
                my ($lon) = $area->findnodes('./geoLong')->to_literal;

                #Convert to negative coordinate as necessary
                if ( $lat =~ m/S$/i ) {
                    $lat = "-" . $lat;
                }
                if ( $lon =~ m/W$/i ) {
                    $lon = "-" . $lon;
                }

                #Remove trailing letter
                $lat =~ s/\w$//g;
                $lon =~ s/\w$//g;

                #Save each point to our @polygon array
                push( @polygon, $lon . " " . $lat );

            }

            #Create a POLYGON WKT definition by joining together all of the points in the polygon array
            my $geometry;
            if (@polygon) {
              $geometry = "POLYGON ((" . join( ' , ', @polygon ) . "))";
            }
            else {$geometry = "POINT (0 0)";}

            say
              "$sequenceNumber;$name;$valDistVerLower;$uomDistVerLower;$valDistVerUpper;$uomDistVerUpper;$dateEffective;$dateExpires;$txtDescrUSNS;$geometry";

        }

    }
}
