package Log;
use strict;
no warnings;
use Data::Dumper;
#use IO::Capture::Stdout;
use Time::HiRes;

require Exporter;
our @ISA = ("Exporter");
our @EXPORT = qw( log_info log_debug log_error log_set_config log_reset_timer log_get_timer get_script_time);

#
# Override these default settings by loading a config with log_set_config.
#

#
# define log levels. 
# Attention: These must be ordered: FIRST list the most specific package names (like Project::Service::ImageUpload). 
# Then the more general ones ( like Project::Service )
#
my %rules = ( 

	# specific log levels on package or method level
    'BadBuilder::Database::MySQL5'=>"debug",
	# logger defaults
	"LEVEL_DEFAULT" => $ENV{MOJO_LOG_LEVEL} || "debug",			# default log level
	"PACKAGE_CHARS" => 40				# string length for the package & method name in the log file ( 0 = no package name )

);



# 
# print a start message to the log with current date & time
#
my @start_time = Time::HiRes::gettimeofday();
my $prefix = ""; 
sub log_reset_timer {
	$prefix = shift || "";
	$rules{LEVEL_DEFAULT} = $ENV{MOJO_LOG_LEVEL} if $ENV{MOJO_LOG_LEVEL};
	$rules{LEVEL_DEFAULT} = 'debug' if $prefix;
	@start_time = Time::HiRes::gettimeofday();
}
print STDERR scalar(localtime). "\t\e[37;44m [ -------------------------- RESTART ------------------------- ] \e[00m\n";

#
# log_debug(..) 
#
# use this for very low level messages only 
# (like database queries, hash dumps, etc.)
# Stuff you need for debugging 
#
sub log_debug {
	_show( "\e[01;31mdebug", @_ ) unless _checkLogLevel( 1 ); 
}

#
# log_info(..)
#
# messages that provide useful information about the program flow
# even when you are not currently debugging that subroutine.
# e.g. "creating thumbnail file $FILENAME, crop: $Ax$B"
#
sub log_info {
	_show( "\e[01;33minfo", @_ ) unless _checkLogLevel( 2 ); 
}

#
# log_error(..)
# use for important messages and errors 
# that should definitively be logged
#
sub log_error {
	_show( "\e[00;31merror", @_ ) unless _checkLogLevel( 3 );
}


#
# check if the log level settings for the current package allow display of this message
#
sub _checkLogLevel {
	my $messagelevel = shift; 
	#
	my $method = (caller(2))[3]; 
	my $level = $rules{'LEVEL_DEFAULT'};
	foreach my $package ( keys %rules ) {
		if ( defined $method && $method =~ /^${package}/ ) {
			$level = $rules{$package};
			last; 
		}
	}
	my $numlevel = $level eq "info" ? 2 : ( $level eq "debug") ? 1 : 3; 
	return ( $messagelevel < $numlevel )
}


#
# print pretty colorized log message to STDOUT
#
sub _show {
	my ($severity, @args) = @_;
	my $method = "";
	my $chars = $rules{'PACKAGE_CHARS'};
	if ( $chars ) {
		$method = (caller(2))[3]; 
		if (defined $method) {
		    $method =~ s/::/:/g;
		    $method = sprintf( "% ".$chars."s", substr( $method, -$chars ) );
		} else {
		    $method = "";
		}
	}
	my $line = (caller(1))[2]; 
	my $string = _getString( @args );
	print STDERR $prefix . log_get_timer() . "\t$severity\t\e[00;34m$method($line)\t\e[00m". $string ."\n"; 
}

sub _getString {
	my $string = ""; 
	foreach my $x ( @_ ) {
		my $out = $x;
		if ( !defined $x ) {
			$out = "*undef*";
		} elsif( ! ref($x) ) {
			$string =~  s/\n//g; 			
		} elsif ( UNIVERSAL::isa($x,'HASH') ) {
		    my $tmp = "hash reference:  {\n" ;
		    for my $k ( sort keys %$x ) {
		    	$tmp.="\t $k => "._getString( $x->{$k} ).",\n";
		    }
		    $out = $tmp."}\n"; 
		} elsif(  UNIVERSAL::isa($x,'ARRAY') ) {
		    $out = "array reference: " . Dumper( $x );
		}
		elsif ( UNIVERSAL::isa($x,'SCALAR') || UNIVERSAL::isa($x,'REF') ) {
		    $out = "scalar ref: " . $$x;
		}
		elsif ( UNIVERSAL::isa($x,'CODE') ) {
		    $out = "code reference: " . var_eval( &$x ); 
		} 
		$string .= " " if $string; 
		$string .= $out; 
	}
	return $string; 
}

#
#  sadly this does not work, maybe because mojolicious already does something to STDOUT?
#
# otherwise we could do cool stuff like write 
# 	log_debug( sub {Dumper( $bla ) } )
# somewhere in the code, and Dumper gets executed only when logging is enabled. 
#
sub var_eval {
	# my $capture = IO::Capture::Stdout->new();
	# $capture->start();
	# eval shift; 
	# $capture->end();
	# my @lines = $capture->read();
	# return join('', @lines);
}


#
# get script run time
#
sub log_get_timer {
	return 
		substr( scalar(localtime), 11,8 )
		.substr( Time::HiRes::gettimeofday(),10); 
}

sub get_script_time {
	return substr( Time::HiRes::tv_interval( \@start_time ) ,0,7);
}


#
# use log_set_config to change log config at runtime
#
sub log_set_config {
	my $var = shift;
	my $val = shift;
	log_debug( "setting log config var $var to $val");
	$rules{$var} = $val; 
}



1;
