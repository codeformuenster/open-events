package MsEvent;
use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use Log;
use Time::ParseDate;
use POSIX qw(strftime);
use Data::Dumper;
use JSON qw( encode_json decode_json );

my $IMP_SOURCE = 0;
my $IMP_STATS = {};

sub init_import_stats {
	my $source_id = shift;
	die("init_import_stats: Need source id") unless $source_id;
	die("init_import_stats: Too many parameters") if shift;
	$IMP_SOURCE = $source_id;
	$IMP_STATS = {};
}

sub save_import_stats {
#
# 	my $dbh = shift;
 	my $errors = ($IMP_STATS->{total}||0) - ($IMP_STATS->{new}||0) - ($IMP_STATS->{updated}||0);
# 	my $sth = $dbh->prepare( '
# 		INSERT INTO event_import_stats( location_source_id, found_events, new_events, updated_events, error_events, error_message )
# 		values ( ?,?,?,?,?,? )'
# 	);
# 	$sth->execute( $IMP_SOURCE, $IMP_STATS->{total} ||0,$IMP_STATS->{new}||0, $IMP_STATS->{updated}||0,
# 		$errors, $IMP_STATS->{errors}  ? Dumper( $IMP_STATS->{errors}): undef  );
# 	$sth->finish();
#
# 	# delete future events that have changed / were cancelled
# 	$sth = $dbh->prepare( 'DELETE FROM event WHERE location_source_id = ? AND event_datetime > now() AND date(last_modified) <> date(now()) ');
# 	$sth->execute( $IMP_SOURCE );
# 	$sth->finish();
#
 	log_info( "<-------- import source ".$IMP_SOURCE." --------->");
 	log_info( "found events:", $IMP_STATS->{total} );
 	log_error("no events found! That's probably wrong!" ) unless ( $IMP_STATS->{total} );
 	log_info( "new:     ", $IMP_STATS->{new} );
 	log_info( "updated: ", $IMP_STATS->{updated} );
 	log_info( "errors:  ", $errors );
 }

sub save_event {
	my $event 		= shift;
	$IMP_STATS->{total} ++;

	$event->{description} = cleanup( $event->{description}) if ( $event->{description} );
	$event->{title} = cleanup( $event->{title}) if ( $event->{title} );

	if ( !$event->{md5} ) {
		$event->{md5} = md5_hex( $event->{link} );
	}

	if ( !$event->{title} ) {
		return event_error( -5,"EVENT TITLE IS MISSING", $event );
	}
	if ( !$event->{datetime} ) {
		if ($event->{parsedate} ) {
			my @dates = ();
			my ($sec,$min,$hour,$day,$month,$yr19,@rest) = localtime(time);
			my $current_year = $yr19 +1900;
			while ( $event->{parsedate} =~ /(\d\d?)\.(\d\d?)\.(\d{4})?/g ) {
				my $checkday 	= $1;
				my $checkmonth 	= $2;
				my $checkyear 	= $3;
				if ( !$checkyear ) {
					$checkyear = $current_year;
					if ( $checkmonth < $month  ) {
						$checkyear ++;
					}
				}
				my $date = ( $checkyear ).'-'.sprintf('%02d',$checkmonth ).'-'.sprintf('%02d',$checkday );
				push @dates, $date;
			}
			$event->{datetime} = $dates[0];
			$event->{enddate} = $dates[1] if ( scalar @dates == 2);

			# still got no date? then try to parse with parsedate()
			unless ( $event->{datetime} ) {
				my $seconds_since_jan1_1970 = parsedate($event->{parsedate} );
				$event->{datetime} = strftime("%Y-%m-%d %H:%M:%S" , localtime( $seconds_since_jan1_1970 ) );
			}
		}
		if ( $event->{parsetime} ) {
			my $ptime = $event->{parsetime};
			if ($ptime =~ /([012]?\d)[.:](\d\d)/ ) {
				$event->{datetime} .= ' ' . sprintf( '%02d', $1 ) . ':' . $2 ;
			} elsif ( $ptime =~ /([012]?\d)\s*Uhr/ ) {
				$event->{datetime} .= ' ' . sprintf( '%02d', $1 ) . ':00' ;
			}
		}


		if ( !$event->{datetime} ) {
			return event_error( -4, "EVENT datetime IS MISSING", $event );
		}
		if ( $event->{datetime} !~ /^\d{4}-\d{2}-\d\d(\s\d\d:\d\d)?/ ) {
			return event_error( -3,"WRONG DATE FORMAT ON 'datetime'", $event );
		}

	}
	if ( !$event->{type} ) {
		$event->{type} = 'theater' if ($event->{title} =~ /theater/i );
		$event->{type} = 'konzert' if ( (!$event->{type}) && ($event->{title} =~ /konzert/i ) );
		$event->{type} = 'disco' if ( (!$event->{type}) && ($event->{title} =~ /disco/i ) );
		$event->{type} = 'party' if ( (!$event->{type}) && ($event->{title} =~ /party/i ) );
		$event->{type} = $event->{default_type} unless $event->{type};
		return event_error( -2, "EVENT TYPE IS MISSING", $event ) unless ( $event->{type} );
	}
	if ( !( $event->{link} || $event->{description} ) ) {
		return event_error( -1,"EVENT NEEDS LINK OR DESCRIPTION", $event );
	}

	my $result = 1;
#	my $sth = $dbh->prepare( 'SELECT event_id FROM event WHERE event_md5 = ?' );
#	$sth->execute( $event->{md5} );
#	my $row = $sth->fetchrow_hashref();
#	$result = 2 if( $row->{event_id});
	my $itype = ($result == 2) ? "updated" : "new";
	$IMP_STATS->{$itype} ++;

	log_debug( "==> event", $event->{type}, "|", $event->{datetime}, "-", $event->{enddate}, "|", $event->{title} );
#	$sth = $dbh->prepare( 'INSERT INTO event( location_id, location_source_id, event_title, event_datetime, event_enddate, event_md5, event_link, event_description, event_image, event_type )
#		values( ?,?,?, ?, ?,?, ?,?,?, ? )
#		on duplicate key update 	event_title = values( event_title), event_link = values( event_link),  event_enddate = values( event_enddate ),
#									event_datetime = values( event_datetime),event_description = values( event_description),
#									location_source_id = values( location_source_id ), last_modified = now()
#
#	' );
#	$sth->execute( $location_id, $IMP_SOURCE, $event->{title},$event->{datetime}, $event->{enddate}, $event->{md5}, $event->{link}, $event->{description}, $event->{image}, $event->{type} );



	# my $event_schema_org = {
	# 	"\@context" => "http://schema.org",
	# 	"\@type" => "Event",
	# 	"name" => $event->{title},
	# 	"description" => $event->{description},
	# 	"location" => {
	# 		"\@type" => "Place",
	# 		"address" => {
	# 			"\@type" => "PostalAddress",
	# 			"streetAddress" => $event->{location}->{streetAddress},
	# 			"addressLocality" => $event->{location}->{addressLocality},
	# 			"postalCode" => $event->{location}->{postalCode}
	# 		},
	# 		"geo" => {
	# 			"\@type" => "GeoCoordinates",
	# 			"latitude" => $event->{location}->{latitude},
	# 			"longitude" => $event->{location}->{longitude}
	# 		}
	# 	},
	# 	"startDate" => $event->{datetime},
	# 	"url" => $event->{link},

		# "x_image" => $event->{image},
		# "x_type" => $event->{type},
		# "x_location" => $event->{location},

		# "geo_point2" => ($event->{location}->{longitude}, $event->{location}->{latitude}),
		# "geo_point3" => $event->{location}->{longitude}+", "+$event->{location}->{latitude}
		# "geo_point2" => [$event->{location}->{longitude}, $event->{location}->{latitude}]
	# };

	# if ( defined $event->{location}->{latitude} ) {
	# 	$event_schema_org->{geo_point3} => {
	# 		"lat" => $event->{location}->{latitude},
	# 		"lon" => $event->{location}->{longitude}
	# 	}
	# };

	my $json = encode_json( $event );
	print STDOUT $json . ",\n";

	return $result;
}

sub event_error {
	my $err = shift;
	my $message = shift;
	my $event = shift;
	log_error( $message, $event );
	$IMP_STATS->{errors}->{$message}++;
	return $err;
}


sub cleanup {
	my $content = shift;
	$content =~  s|<br[^>]*>|§~~§|g;
	$content =~  s|\n|§~~§|g;
	if ( $content ) {
		$content =~  s|<.+?>| |g;
		$content =~  s/\s+/ /;
		$content =~  s/^\s+//;
		$content =~  s/\s+$//;
	}
	$content =~  s|https?://[^\s"']+| |gi;

	$content =~  s|(?:§~~§\s*)+|\n|g;

	return $content;
}


1;
