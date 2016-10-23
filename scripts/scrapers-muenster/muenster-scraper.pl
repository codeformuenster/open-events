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
my $token = "498459953cc4d3342d64724e93517019";



#
# read ini file and connect to mysql
#
my $cfg = Config::IniFiles->new( -file => "muenster.ini" );



#
# commandline parameters
#
my $parse_only = shift;
# my $loglevel = shift || ( $parse_only ? 'debug' : "info" );
#log_set_config( 'LEVEL_DEFAULT', $loglevel );
log_info( "parsing only ", $parse_only ) if $parse_only;



my $transformers = MsScraperConfig::TRANSFORMATORS;

print "[\n";
# parse events from each location page
foreach my $parser_name (keys %$transformers) {
  if ( (!$parse_only ) || ( $parse_only && ( $parser_name eq $parse_only)  )  ) {
    log_info( "===========================>",$parser_name );
    my $parser_code = $transformers->{$parser_name};
    parse_terminseite( $parser_name, $parser_code );
  }
}

# parse events from fb urls
my $fb_urls = [
 ['heile_welt', 'https://www.facebook.com/heile.welt.7/661314167323865'],
 ['655321_milchbar', 'https://www.facebook.com/pages/655321-milchbar/466498750114656'],
 ['boheme_boulette', 'https://www.facebook.com/111155778948430'],
 ['watusibar_ms', "https://www.facebook.com/watusibarms/131244416925066"],
 ['pension_schmidt', 'https://www.facebook.com/schmidt.pension/203257859770378'],
 ['cuba_nova', 'https://www.facebook.com/cubanova.de/172682859543687'],
 ['frauenstr_24', 'https://www.facebook.com/pages/Frauenstrasse-24/482134915163'],
 ['heaven_ms','https://www.facebook.com/heavenmuenster/121914222610'],
 ['der_stur',"https://www.facebook.com/derstur48/749352325078218"],
 ['schwarzes_schaf',"https://www.facebook.com/DasSchwarzesSchafMS/303333226364758"],
 ['fusion_ms', "https://www.facebook.com/fusionmuenster/117570597074"]
];
foreach my $fb_url (@$fb_urls) {
  my $parser_name = $fb_url->[0];
  if ( (!$parse_only ) || ( $parse_only && ( $parser_name eq $parse_only)  )  ) {
    log_info( "===========================>",$parser_name );
    my $parser_code = $transformers->{events};
    my $options = {'url'=> $fb_url->[1]};
    parse_terminseite( $parser_name, $parser_code, $cfg, $options );
  }
}



sub parse_terminseite {
  my $parser_name = shift;
  my $parser_code = shift;
  my $config = shift;
  my $options = shift;

  log_debug("start parser", $parser_name );
  MsEvent::init_import_stats( $parser_name );
  log_debug("mid parser", $parser_name );
  # execute the parser code
  my $events = &{$parser_code}($parser_name, $config, $options);
  log_debug("done parsing", $parser_name );

  # save the resulting events
  for my $event (@$events) {
    if (!$event->{source_url}) {
      die("Missing source_url");
    }
    $event->{location} = $parser_name if (!$event->{location});
    my $res = MsEvent::save_event( $event );
  }

  MsEvent::save_import_stats( );

}

print "\n]\n";
