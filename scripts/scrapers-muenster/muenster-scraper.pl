#!/usr/bin/perl

use Config::IniFiles;
use XML::Feed;
#use HTML::Restrict;
use lib 'lib';

use strict;
use warnings;
use Log;
use MsEvent;
use MsScraperConfig;
use JSON qw( encode_json decode_json );
use Try::Tiny;

# global fb auth token
my $token ;



#
# read ini file and connect to mysql
#
my $cfg = Config::IniFiles->new( -file => "muenster.ini" );



#
# commandline parameters
#
my $parse_only = shift;
my $loglevel = shift || ( $parse_only ? 'debug' : "info" );
log_set_config( 'LEVEL_DEFAULT', $loglevel );
log_info( "parsing only ", $parse_only ) if $parse_only;



my $transformers = MsScraperConfig::TRANSFORMATORS;






# read locations definition file
my $locations_file = 'locations.json';
open(my $fh, '<', $locations_file) or die "Could not open file '$locations_file' $!";
my $jsonfile = "";
while (my $row = <$fh>) {
  $jsonfile.=$row;
}
my $locations = decode_json( $jsonfile );


# parse events from each location page
for my $row ( @$locations) {
	log_debug( "parsing", $row );
	if ( (!$parse_only ) || ( $parse_only && ( $row->{parser} eq $parse_only)  ) || ( $parse_only && ( $row->{source_id} eq $parse_only )  )  ) {
		log_info( "===========================>",$row->{parser},"terminseite location:", $row->{location_id}, "source:", $row->{source_id}, $row->{source_url});
		parse_terminseite( $row );
	}
}
close $fh;


sub parse_terminseite {
	my $args = shift;
	my $url 		= $args->{source_url};
	my $source_id 	= $args->{source_id};
	my $location_id = $args->{location_id};
  my $location = $args;

	unless ($url) {
		log_error( "NO URL") ;
		return ;
	};
	unless ( $transformers->{$args->{parser} } ) {
		log_error("MISSING PARSER FOR ", $args->{parser} );
		return;
	}

	#
	# parse all the urls
	#
	log_debug("parsing url", $url );
	MsEvent::init_import_stats( $source_id );
	my $events = &{ $transformers->{$args->{parser} } }( $url, $cfg, $args );
	my $results = { };
	for my $event (@$events) {
		$event->{default_type} = $args->{default_event_type} if ($args->{default_event_type} && !$event->{type} );
		$event->{location_id} = $location_id;
		$event->{location} = $location;

		my $res = MsEvent::save_event( $event );
	}

	MsEvent::save_import_stats( );

}
