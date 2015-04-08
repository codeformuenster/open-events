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
my $cfg = Config::IniFiles->new( -file => "../conf/app.ini" );



#
# commandline parameters 
#
my $parse_only = shift;
my $loglevel = shift || ( $parse_only ? 'debug' : "info" );
log_set_config( 'LEVEL_DEFAULT', $loglevel );
log_info( "parsing only ", $parse_only ) if $parse_only;



my $transformers = MsScraperConfig::TRANSFORMATORS;

my $locations_export = []; 
while ( my $row = $sth->fetchrow_hashref() ) {
	log_debug( $row->{parser} );
	if ( (!$parse_only ) || ( $parse_only && ( $row->{parser} eq $parse_only)  ) || ( $parse_only && ( $row->{source_id} eq $parse_only )  )  ) {
		log_info( "===========================>",$row->{parser},"terminseite location:", $row->{location_id}, "source:", $row->{source_id}, $row->{source_url});
		#parse_terminseite( $row );
	}
	for my $key ( qw( created_date last_modified active ) ) {
		delete $row->{$key};
	}
	push @$locations_export, $row;

}

my $json_export_file = 'data/locations.json';
open(my $fh, '>', $json_export_file ) or die "Could not write to file '$json_export_file' $!";
print $fh encode_json( $locations_export );
close $fh;


sub parse_terminseite {
	my $args = shift;
	my $url 		= $args->{source_url};
	my $source_id 	= $args->{source_id};
	my $location_id = $args->{location_id};
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
		my $res = MsEvent::save_event( $dbh, $location_id, $event );
	}

	MsEvent::save_import_stats( $dbh );

}





