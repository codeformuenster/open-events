package MsScraperConfig;

use Config::IniFiles;
use XML::Feed;
#use HTML::Restrict;
use lib 'lib';
use Digest::MD5 qw(md5_hex);
use Digest::SHA qw(hmac_sha256_hex);

use strict;
use warnings;
use DBI;
use Log;
use MsEvent;
use HTML::TreeBuilder::XPath;
use JSON qw( decode_json );
use LWP::Simple;
use Try::Tiny;
use POSIX qw(strftime);

use constant {
	MONTHS3 => {
		Jan => '01',
		Feb => '02',
		Mrz => '03',
		Apr => '04',
		Mai => '05',
		Jun => '06',
		Jul => '07',
		Aug => '08',
		Sep => '09',
		Okt => '10',
		Nov => '11',
		Dez => '12'
	},
	MONTHS => {
		Januar => '01',
		Februar => '02',
		'März' => '03',
		April => '04',
		Mai => '05',
		Juni => '06',
		Juli => '07',
		August => '08',
		September => '09',
		Oktober => '10',
		November => '11',
		Dezember => '12'
	}

};

# global fb auth token
my $token ;

#
# feed transformation definitions
#
use constant {
	TRANSFORMATORS => {
		conny_kramer => sub {
			my $url = 'http://www.connykramer.ms';
			my $html= HTML::TreeBuilder::XPath->new_from_url( $url );

			my $events = [];
			my $nodes = $html->findnodes( '//div[@class="boxRight"]');
			for my $node ( @$nodes ) {
				my $event = {
					title => $node->findvalue('h2'),
					link => $url,
					description => $node->findvalue('div[@class="info"]' ),
					image => "",
					type => 'disco',
					source_url => $url
				};

				my $datetime = $node->findvalue('h1');
				if ( $datetime =~ /(\d\d?)\.(\d\d?)\.(\d{4})/ ) {
					$event->{datetime} = $3.'-'.sprintf('%02d',$2).'-'.sprintf('%02d',$1);
					$event->{md5} = md5_hex( "conny" . $event->{datetime} );
					if ($event->{description} =~ /(\d\d:\d\d)h/) {
						$event->{datetime} .= " " . $1.":00";
					}
				}
				push @$events, $event;
			}
			$html->delete;
			return $events;
		},

		# <div class="eintrag">
		# 	<div class="zeitraum">
		# 		24.10.2015 - 1.11.2015					</div>
		# 	<div class="beschreibung">
		# 		<!--
		# 		<div class="foto"> <!-- dieser Bereich kann über den Titel geschoben werden um Foto auf Höhe der Überschrift zu haben -->
		# 		<!--	<img src="css/images/grueffelo.jpg" />
		# 		</div>
		# 		-->
		# 		<div class="titel">
		# 			Herbstsend						</div>
		# 		<div class="untertitel">
		# 			M&uuml;nsters gr&ouml;&szlig;tes Volksfest						</div>
		# 		<div class="top-veranstaltung-kurztext">
		# 			Die gr&ouml;&szlig;te Kirmes des M&uuml;nsterlandes: Schaustellerbetriebe aus der gesamten Bundesrepublik pr&auml;sentieren Nostalgisches ebenso wie die neuesten Fahrgesch&auml;fte.															<a href="http://www.muenster.de/veranstaltungskalender/scripts/frontend/mm/top-veranstaltung.php?id=3168&amp;guestID=101" class="intern">Details</a>
		# 		</div>
		# </div>

		muenster => sub {
			my $url = 'http://www.muenster.de/stadt/tourismus/veranstaltungen.html';
			my $html= HTML::TreeBuilder::XPath->new_from_url( $url );
			my $events = [];
			my $nodes = $html->findnodes( '//div[@class="eintrag"]');
			for my $node ( @$nodes ) {
				my $title = $node->findvalue('div[@class="beschreibung"]/div[@class="titel"]');
				my $subt = $node->findvalue('div[@class="beschreibung"]/div[@class="untertitel"]');
				if ( $subt =~ /[a-z]/i ) {
					$title .= " - ". $subt;
				}
				my $desc = $node->findvalue('div[@class="beschreibung"]/div[@class="top-veranstaltung-kurztext"]');
				$desc =~ s/mehr\.\.\.//g;
				my $event = {
					parsedate => $node->findvalue('div[@class="zeitraum"]'),
					title => $title,
					link => $node->findvalue('div[@class="beschreibung"]/div[@class="top-veranstaltung-kurztext"]/a[@class="intern"]/@href'),
					description => $desc,
					image => $node->findvalue('div[@class="beschreibung"]/div[@class="foto"]/img/@src'),
					type => 'muenster',
					source_url => $url
				};
				push @$events, $event;
			}
			$html->delete;
			return $events;
		},


		gleis22 => sub {
			my $url = "http://www.gleis22.de/programmuebersicht.php";
			my $html= HTML::TreeBuilder::XPath->new_from_url( $url );

			my $events = [];
			my $nodes = $html->findnodes( '//td[@class="TEXTUebersicht" and @width="60"]/ancestor::tr[1]');
			for my $node ( @$nodes ) {
				my $description = $node->findvalue('td[@width="569"]');
				my $title = $description;
				my $titlehtml = $node->as_XML;
				my $type = 'disco';
				if ( $titlehtml =~ /textuebersichtband/ ) {
					log_debug("got titlehtml", $titlehtml );
					$title = "";
					my @matches = $titlehtml =~ /lass="textuebersichtband"[^>]*>(.+?)<br/g;
					$type = 'konzert';
					for my $match ( @matches ) {
						$match =~ s/<[^>]+?>/ /g;
						if ( $match ) {
							if ( $title ) { $title .= " und "; }
							else { $title = "Konzert: "; }
							$title .= $match;
						}
					}
				}
				my $date = $node->findvalue('td[@width="60"]');
				my $event = {
					parsedate => $date,
					title => $title,
					link => 'http://www.gleis22.de',
					description => $description,
					image => "",
					type => $type,
					md5 => $date.$title
				};
				if ( $title =~ /sentier/) {
					$event->{type} = 'konzert';
				};
				push @$events, $event;
			}
			$html->delete;
			return $events;
		},

		# <article class="module extended">
		# 	<footer class="metainfo" style="text-align:left; padding-left:10px;">
		# 		<div style="width:100%;"><div style="float:left;">Ausstellung</div><div style="text-align:right;font-weight:bold;">08. Okt. 2016 &ndash; 08. Jan. 2017</div></div>
		# 	</footer>
		# 	<div class="module-content">
		# 		<header>
		# 			<h2 style="margin-bottom:5px"><a class="int" href="/HausDerNiederlande/veranstaltungen/details.shtml?id=000177">Der goldene Käfig</a></h2>
		# 			<div class="subhead" style="margin-bottom:10px">Prächtiges Federvieh des flämischen Bilderbuchkünstlers Carll Cneut</div>
		# 		</header>
		#
		# 		<figure class="teaserfigure" style="margin-right:10px;margin-bottom:15px;">
		# 			<a title="Symbol Ausstellung" href="/HausDerNiederlande/veranstaltungen/details.shtml?id=000177">
		#
		# <img src="/HausDerNiederlande/files/layout/veranstaltungsicons/ausstellung180.png" width="180" height="180" class="lang" alt="Teaserbild">
		# <picture data-lazy="200" data-alt="Teaserbild" data-default-src="/HausDerNiederlande/files/layout/veranstaltungsicons/ausstellung360.png" class="kurz">
		# 	<source media="(min-width: 49.125em)" srcset="/HausDerNiederlande/files/layout/veranstaltungsicons/ausstellung180.png 1x, /HausDerNiederlande/files/layout/veranstaltungsicons/ausstellung349.png"/>
		# 	<source media="(min-width: 37.5em)" srcset="/HausDerNiederlande/files/layout/veranstaltungsicons/ausstellung180.png 1x, /HausDerNiederlande/files/layout/veranstaltungsicons/ausstellung356.png"/>
		# 	<source srcset="/HausDerNiederlande/files/layout/veranstaltungsicons/ausstellung360.png"/>
		# 	<img src="/HausDerNiederlande/files/layout/veranstaltungsicons/ausstellung360.png" width="360" height="180" alt="Teaser">
		# </picture>
		#
		# 			</a>
		#
		# <figcaption class="" style="max-width:750px">
		#
		# 		<address><a href="https://thenounproject.com/icon/68539/" target="_blank" style="color:#8c9598;">Luis Prado</a>/<a href="http://creativecommons.org/licenses/by/3.0/us/" target="_blank" style="color:#8c9598;">cc-by</a>/<acronym title="The Noun Project">TNP</acronym></a></address>
		#   </figcaption>
		#
		# 		</figure>
		# 		<div class="teaser" style="float:left;margin-top:-15px;">
		# 			<p>Der goldene Käfig, die Ausstellung zum gleichnamigen, für den Jugendliteraturpreis nominierten Bilderbuch, zeigt Originale des belgischen Illustrators Carll Cneut (*1969), der phantastische Welten zu dem dramatisch-poetischen Märchen der Italienerin Anna Castagnoli schuf. Die Legende von Macht und Obsession, von Veränderung und Geduld wurde von Cneut in intensiven Szenarien von unvergleichbarer Bildgewalt dargestellt. <a class="int" href="/HausDerNiederlande/veranstaltungen/details.shtml?id=000177">Zu den Details</a></p>
		# 		</div>
		# 	</div>
		# 	<div class="clearfix"></div>
		# </article>

		haus_der_nl => sub {
			my $url = 'http://www.uni-muenster.de/HausDerNiederlande/veranstaltungen/';
			my $events = [];
			my $content = get( $url );
			my @matches = $content =~ /(<p\s+lang="de-de".*?<\/p>)/imsg;
			for my $match ( @matches ) {
				if ( $match =~ /<strong>([^<]+)<\/strong>.*href="([^"]+)".*<strong>([^<]+)</ims ) {
					my $event = { title => $1 . " " . $3 };
					$event->{link} = $2;
					$event->{type} = 'kultur';
					if ( $match =~ /^<p[^>]+>\s*(\d\d?)\.(\d\d?)\.(\d{4})([^<]*)</ims ) {
						$event->{datetime} = $3.'-'.sprintf('%02d',$2).'-'.sprintf('%02d',$1);
						my $daterest = $4;
						log_debug("daterest", $daterest );
						if ( $daterest =~ /(\d\d)(\.\d\d)?\s*Uhr/ ) {
							$event->{datetime} .= ' '.$1.':'.($2||'00').':00';
						} elsif ( $daterest =~ /(\d\d?)\.(\d\d?)\.(\d{4})/) {
							$event->{enddate} = $3.'-'.sprintf('%02d',$2).'-'.sprintf('%02d',$1);
							log_debug("enddate", $event->{enddate} );
						} else {
							log_debug("hm, only date..?!");
						}
					}
					push @$events, $event;
				}
			}
			return $events;
		},

		# <div class="anreisser">
		# 	<h3>Mittwoch, 1. April 2015, 19 Uhr</h3>
		# 	<p>Malte Berndt, Dr. Ralf Springer (Münster)
		# 		<br/>
		# 	<a class="intern" target="_self"  href="villa-ten-hompel/veranstaltungen/2015-04-01-drehbuch-geschichte.html" >Drehbuch Geschichte</a>
		# 	<br/>
		# 	Heute vor 70 Jahren - Das Kriegsende in Westfalen
		# </p>
		# </div>
		villa_ten_hompel => sub {
			my $url = 'http://www.stadt-muenster.de/villa-ten-hompel/veranstaltungen.html';
			my $events = [];
			my $content = get( $url );
			my @matches = $content =~ /<div class="anreisser">(.*?)<\/div>/imsg;
			log_debug("villa ten hompel got matches: " , scalar @matches );
			for my $match ( @matches ) {
				if ( $match =~ /<h3>.*?([0-9.:])+\s*Uhr.*<\/h3>(.*?)<a[^>]+href="([^"]+)"[^>]+>(.*?)<\/a>(.*)$/ims ) {
					my $event = {
						link => 'http://www.stadt-muenster.de/' . $3,
						type => 'kultur',
						description => $4." - ".$5." - ".$2,
						title => $4,
						source_url => $url
					};
					my $uhrzeit = $1;
					$uhrzeit = "0". $uhrzeit if ( length( $uhrzeit ) == 1 );
					$uhrzeit .= ':00' if ( length( $uhrzeit ) == 2 );
					if ( $event->{link} =~ /(\d\d\d\d-\d\d-\d\d)/ ) {
						$event->{datetime} = $1.' '.$uhrzeit;
					}
					push @$events, $event;
				}
			}
			return $events;
		},

  # 		  <dt>
  #               <p class="datum">Freitag, 26.12.2014</p>
  #               <p class="uhrzeit">14:30 Uhr</p>
  #           </dt>

  #           <dd>
  #               <p class="titel"><a href="http://www.lwl.org/lwlkalender/VeranstaltungAction.do;jsessionid=2BCDA4513C29859617B46E5EA5742FF0?id=1032395"><span>Highlight-Tour</span></a></p>
  #               <p class="u-titel"><a href="http://www.lwl.org/lwlkalender/VeranstaltungAction.do;jsessionid=2BCDA4513C29859617B46E5EA5742FF0?id=1032395"><span>Besonderer Rundgang durch die Sammlung</span></a></p>

  #               <p class="ort">Münster</p>
  #               <p class="v-ort">Domplatz 10, 48143 Münster</p>
  #               <hr />
  #           </dd>
		lwl_museum => sub {
			my $url = 'http://www.lwl.org/LWL/Kultur/museumkunstkultur/programm/kalender/';
			my $events = [];
			my $content = get( $url );
			my @matches = $content =~ /(<dt>.*?<\/dd>)/imsg;
			for my $match ( @matches ) {
				my %details = $match =~ /<p\s+class="([^"]+)">(.*?)<\/p>/imsg;
				if ( scalar %details ) {
					my $event = {source_url => $url};
					for my $classname (keys %details ) {
						my $content = $details{$classname};
						$event->{parsedate} = $content if $classname eq "datum";
						$event->{parsetime} = $content if $classname eq "uhrzeit";
						if ( $classname =~ /titel$/ ) {
							$event->{title}.= ($event->{title} ? " - " : "" ) . $content;
							if ( $content =~ /href="([^"]+)"/i ) {
								my $link = $1;
								$link =~ s/;jsessionid=[^&?]+//;
								$event->{link} = $link;
							}
						}
					}
					$event->{type} = 'kultur';
					$event->{type} = lc($1) if ( $event->{title} =~ /(kind|jugend|familie)/i ) ;
					push @$events, $event;
				}
			}
			return $events;
		},

		#		 <div id="node-395" class="node node-event node-promoted node-teaser clearfix">
		#		   <h2><a href="/node/395">BarCraft</a></h2>
		#		   <div class="content">
		#		       <div class="field field-name-field-datum field-type-datetime field-label-hidden">
		#					div class="field-items">
		#						div class="field-item even">
		#							span class="date-display-single">Sonntag, 5. April 2015</span>
		#						/div>
		#					/div>
		#				/div>
		#				div class="field field-name-body field-type-text-with-summary field-label-hidden">
		#					div class="field-items">
		#						div class="field-item even">
		#							p><a class="colorbox colorbox-insert-image" title="" href="http://www.spec-ops.de/sites/default/files/styles/colorbox/public/bilder/event/11017166_747978845317980_1778961674907993302_n.png" rel="gallery-all">
		#									img class="image-insert" style="display: block; margin-left: auto; margin-right: auto;" title="" src="http://www.spec-ops.de/sites/default/files/styles/insert/public/bilder/event/11017166_747978845317980_1778961674907993302_n.png" alt="" />
		#								/a>
		#							/p>
		#						/div>
		#					/div>
		#				/div>
		#				div class="s-break-weiss s-break"></div>
		#		 		<div class="s-weiter">
		#					ul class="links inline"><li class="node-readmore first last"><a href="/node/395" rel="tag" title="BarCraft">Weiterlesen<span class="element-invisible"> über BarCraft</span></a></li>
		#		 			</ul>
		#				/div>
		#		   </div>
		#		 </div>
		spec_ops => sub {
			my $url = 'http://www.spec-ops.de/programm';
			my $html= HTML::TreeBuilder::XPath->new_from_url( $url );
			my $events = [];
			my $nodes = $html->findnodes( '//div[@class="node node-event node-promoted node-teaser clearfix"]');
			for my $node ( @$nodes ) {
				my $event = {
					title => $node->findvalue('h2/a'),
					link => 'http://www.spec-ops.de' . $node->findvalue('h2/a/@href'),
					description => $node->findvalue('div[@class="content"]/div[contains(@class,"field-type-text-with-summary")]' ),
					image => $node->findvalue('div[@class="content"]/div[contains(@class,"field-type-text-with-summary")]/div/div/p/a/img/@src' ),
					default_type => 'party',
					source_url => $url
				};
				my $datum = $node->findvalue('div[@class="content"]/div[@class="field field-name-field-datum field-type-datetime field-label-hidden"]/div/div/span');
				if ( $datum =~ /,\s*(\d\d?).\s*([a-zA-Z]+)\s+(\d{2,4})/ ) {
					$event->{datetime} = sprintf( '%04d-%02d-%02d', $3, +MONTHS->{$2} || $2, $1 );
					my $uhr = "";
					if ( $event->{description} =~ /(\d\d)([\.:]\d\d)?\s*Uhr/i ) {
						$uhr = $1.':'.(substr($2, 1)||'00').':00';
					}
					if ( (!$uhr) && ( $event->{description} =~ /ab\s*(\d\d)([\.:]\d\d)?/i ) ) {
						$uhr = $1.':'.(substr($2, 1)||'00').':00';
					}
					$event->{datetime}.= ' '.$uhr if $uhr;
				}
				push @$events, $event;
			}
			return $events;
		},



# 	<div id="events">
#     <ul>
#     	        <li>
#         <div>
#         	<div class="container">
        #
#                 <div class="top">
#                 	<div class="row">
                    	#
#                         <div class="col-sm-5">
#                             <div class="image">
#                             	<div>
#                                 	<img src="http://www.jovel.de/media/jovel/images/0422.png" alt="" class="grey" /><img src="http://www.jovel.de/media/jovel/images/0422.png" alt="" />                               	</div>
#                             </div>
#                         </div>
                        #
#                         <div class="col-sm-7">
                        #
#                             <h2>Beer Pong  Meisterschaft + Semesterstartparty - F&Auml;LLT AUS</h2>
#                             <div class="info">
#                                 Mi, 22.04, 00:00 Uhr<br />
#                                 <span style="color:#009ee3">Music Hall</span>                            </div>
                            #
#                             <div class="text">
#                             	                                <p><strong>Die geplante Beer Pong Meisterschaft und Semesterstartparty f&auml;llt leider aus.</strong></p>
# <p><strong>Eine Verlegung auf einen sp&auml;teren Zeitpukt ist in Planung.</strong></p>
#                                 <div class="clearfix"></div>
                                #
#                                 <a class="btn btn-default" data-toggle="modal" data-target="#modal246462">Details</a>
#                             </div>
                        #
#                         </div>
                    #
#                     </div>
#                 </div>
            #
#             </div>
#         </div>
#         </li>

		jovel => sub {

			my $urls = [
				["konzert/rockpop","http://www.jovel.de/veranstaltungen/konzerte"],
				['party',"http://www.jovel.de/veranstaltungen/parties"],
				["sonstiges","http://www.jovel.de/veranstaltungen/spezial"]
			];
			my $events = [];
			foreach my $row (@$urls) {
				my $type = $row->[0];
				my $url = $row->[1];
				my $html= HTML::TreeBuilder::XPath->new_from_url( $url );
				my $nodes = $html->findnodes('//div[@id="events"]/ul/li/div/div[@class="container"]' );
				log_debug("found nodes", scalar @$nodes );
				for my $node ( @$nodes ) {
					#log_debug("adding event", $node );
					my $event = {
						title => $node->findvalue('div/div/div[@class="col-sm-7"]/h2'),
						link => 'http://www.jovel.de/veranstaltungen/',
						description => $node->findvalue('div/div/div[@class="col-sm-7"]/div[@class="text"]'),
						type => $type
					};
					my $datum = $node->findvalue('div/div/div[@class="col-sm-7"]/div[@class="info"]');
					if ( $datum =~ /\w\w,\s*(\d\d?)\.(\d{1,2}),\s*(\d\d:\d\d)/i ) {
						$event->{parsedate} = $1.'.'.$2.'.';
						$event->{parsetime} = $3;
					}
					$event->{md5} = md5_hex($event->{parsedate} . $event->{parsetime});
					$event->{source_url} = $url;
					push @$events, $event;
				}
			}
			return $events;
		},

# <div id="post-3185" class="hentry vevent type-tribe_events post-3185 tribe-clearfix tribe-events-category-session tribe-events-venue-183 tribe-events-organizer-182 hentry vevent type-tribe_events tribe-clearfix ">
# <!-- Event Image -->
# <div class="tribe-events-event-image"><a href="http://www.hotjazzclub.de/veranstaltung/monday-night-session-mit-snakatak-6/" title="Monday Night Session mit Snakatak">
# 	<img src="http://www.hotjazzclub.de/wp-content/uploads/2015/01/facebook_event_825985697459821-150x100.jpg" title="Monday Night Session mit Snakatak" />
# </a></div>
# <div class="tribe-events-date-listview">
# <div class="date-day">Montag</div>
# <div class="date-date">23.</div>
# <div class="date-month">Feb</div>
# </div>
# <div class="tribe-events-list-event-description tribe-events-content description entry-summary">
# <!-- Event Title -->
# <div class="my-tribe-events-title"><h2 class="tribe-events-list-event-title summary">
# 	<a class="url" href="http://www.hotjazzclub.de/veranstaltung/monday-night-session-mit-snakatak-6/" title="Monday Night Session mit Snakatak" rel="bookmark">
# 		Monday Night Session mit Snakatak	</a></h2>
# </div>
# <div class="my-tribe-events-stilrichtung"><h2>Jazz, Rock &amp; Fusion</h2></div>
# <div class="my-tribe-events-meta">
# 	<span class="my-tribe-events-preisinfos">Eintritt frei!</span>
# 	<a class='fb-share' href='https://facebook.com/events/825985697459821' target='_BLANK'></a></div>
#
# </div><!-- .tribe-events-list-event-description -->		</div><!-- .hentry .vevent -->


		hotjazzclub  => sub {
			my $url = 'http://www.hotjazzclub.de/programm/';
			my $html= HTML::TreeBuilder::XPath->new_from_url( $url );
			log_debug("tree built for url", $url );
			my $events = [];
			my $nodes = $html->findnodes( '//div[contains(@class,"type-tribe_events")]');
			log_debug("found nodes", scalar @$nodes );
			for my $node ( @$nodes ) {
				my $descnodes = $node->findnodes('div[contains(@class,"tribe-events-list-event-description")]' );
				my $descnode = $descnodes->[0];
				my $title = $descnode->findvalue('div[@class="my-tribe-events-title"]/h2/a');
				my $type = 'konzert';
				if ( $title =~ /theater/i ) {
					$type = "theater";
				} elsif ( $title =~ /club|party/i ) {
					$type = "party";
				}
				my $event = {
					title => $title,
					link => $descnode->findvalue('div[@class="my-tribe-events-title"]/h2/a/@href'),
					description => $descnode->findvalue('div[@class="my-tribe-events-stilrichtung"]' )."\n".
									$descnode->findvalue('div[@class="my-tribe-events-meta"]/span[@class="my-tribe-events-preisinfos"]'),
					image => $node->findvalue('div[@class="tribe-events-event-image"]/a/img/@src'),
					type => $type,
					tags => $descnode->findvalue('div[@class="my-tribe-events-stilrichtung"]' ),
					source_url => $url
				};
				my $dateday = $node->findvalue('div[@class="tribe-events-date-listview"]/div[@class="date-date"]');
				my $datem_text = $node->findvalue('div[@class="tribe-events-date-listview"]/div[@class="date-month"]');
				my $datemonth = +MONTHS3->{$datem_text};
				$event->{parsedate} = $dateday.$datemonth.'.';
				log_debug("month", $datem_text, $datemonth, $event->{parsedate} );
				log_debug("event", $event );
				push @$events, $event;
			}
			$html->delete;
			return $events;
		},

		# facebook events parsing
		events => sub {
			my $name = shift;
			my $cfg = shift;
			my $options = shift;
			my $url = $options->{url};

			my $fbId = $cfg->val( 'fb', 'id' );
			my $fbSc = $cfg->val( 'fb', 'sc' );
			if (! ( $fbId && $fbSc ) ) {
				log_error("Facebook id and secret not found. Did you fill out your app.ini file? Skipping location.");
				return [];
			}

			# get auth token
			unless ( $token ) {

				#
				# check if there is a user auth token file on disk
				#
				my $filename = 'fb-token.txt';
				open(my $fh, '<:encoding(UTF-8)', $filename);
				my $epoch_timestamp = $fh ? (stat($fh))[9] : "";
				#my $timestamp       = localtime($epoch_timestamp);
				my $now = time;
				log_debug("timestamps", $epoch_timestamp, $now );
				if ( $fh && ( $epoch_timestamp > $now-60*60 ) ) {
					log_info("using FB USER auth token from file", $filename );
					while (my $row = <$fh>) {
					  chomp $row;
					  $token.= $row if $row =~ /\w/;
					}
					close $fh;
					$token = "access_token=".$token;
				} else {

					$token = get( 'https://graph.facebook.com/oauth/access_token?client_id='.$fbId.'&client_secret='.$fbSc.'&grant_type=client_credentials' );
					log_info("using FB APP auth token", $token);
					unless( $token =~ /access_token=(.+)/ ) {
						log_error("DID NOT GET FB ACCESS TOKEN, DUDE!!");
					}
				}
			} else {
				log_info("Did not get facebook access token. Did you fill out your app.ini file correctly? Skipping location.");
			}
			my $fb_url = '';
			if ($url =~ m#^https://www.facebook.com/([^/]+)/?$#i ) {
				$fb_url =  'https://graph.facebook.com/'.$1.'/events';
			}
			if ($url =~ m#^https://www.facebook.com/pages/[^/]+/(.+)$#i ) {
				$fb_url =  'https://graph.facebook.com/'.$1.'/events';
			}
			elsif ($url =~ m#^https://www.facebook.com/[^/]+/([^/]+)$#i ) {
				$fb_url =  'https://graph.facebook.com/'.$1.'/events/created';
			} else {
				log_error("ERROR. Bad facebook url?", $url );
			}
			my $events = [];
			if ( $fb_url ) {
				$token =~ /access_token=(.+)$/;
				my $access_token = $1;
				my $appsecret_proof= hmac_sha256_hex( $access_token, $fbSc);

				$fb_url .= '?'.$token; # .'&appsecret_proof='.$appsecret_proof;
				$fb_url .= '&since='.time;
				log_debug("fetching", $fb_url );
				my $content = get( $fb_url );
				log_debug("content", $content);
				my $json;
				try {
					$json = decode_json( $content );
				} catch {
					log_error($_);
				};

			#	log_debug("we got", $json);

            	if ( $json && $json->{data} ) {
					for my $data ( @{$json->{data}} ) {
						my $event = {
							type => 'party',
							parsedate => $data->{start_time},
							title => $data->{name},
							link => 'https://www.facebook.com/events/'.$data->{id}.'/'
						};
						push @$events, $event;
					}
				}
			}
			return $events;

		},


		# google calendar events parsing for kotenkram.de
		gcal => sub {
			my $url = 't2rek1hujonc0g724bbm24gibo%40group.calendar.google.com';
			my $parser_name = shift;
			my $cfg = shift;
			my $source_url = "http://www.kotenkram.de";
			die("NO Google Calendar Email!") unless $url;
			if (!$cfg) {
				log_error('Google credentials config not found.');
				return [];
			}

			my $token = $cfg->val( 'gcal', 'token' );
			my $date = strftime("%Y-%m-%d" , localtime(time-24*60*60) );
			my $time = $date.'T10%3A57%3A00-08%3A00';
			my $enddate = strftime("%Y-%m-%d" , localtime(time + 24*60*60 * 60) ).'T10%3A57%3A00-08%3A00';
			$url =~ s/@/%40/;
			my $gurl = "https://www.googleapis.com/calendar/v3/calendars/$url/events?singleEvents=true&orderBy=startTime&timeMin=$time&timeMax=$enddate&key=$token";

			my $events = [];
			log_debug("fetching", $gurl );
			my $content = get( $gurl );
			log_debug("content", $content);
			my $json;
			try {
				$json = decode_json( $content );
			} catch {
				log_error($_);
			};

			log_debug("we got", $json);
			if ( $json && $json->{items} ) {
				for my $item ( @{$json->{items}} ) {
					my $start = substr( $item->{start}->{dateTime}, 0, 19 );
					$start =~ s/T/ /;
					my $end = substr( $item->{end}->{dateTime}, 0, 19 );
					$end =~ s/T/ /;
					my $event = {
						title => $item->{summary},
						description => $item->{description},
						link => $source_url,
						datetime => $start,
						enddate => $end,
						md5 => md5_hex( $item->{id} ),
						tags=> "Eltern, Kinder, Flohmärkte, Tagesmütter",
						type=> "kinderflohmarkt",
						source_url=> $source_url
					};
					push @$events, $event;
				}
			}

			return $events;
		}

	}
};


return 1;
