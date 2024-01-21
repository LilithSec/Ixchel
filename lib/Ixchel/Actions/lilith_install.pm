package Ixchel::Actions::lilith_install;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use Ixchel::functions::perl_module_via_pkg;

=head1 NAME

Ixchel::Actions::lilith_install - Installs Lilith using packages as much as possible.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 CLI SYNOPSIS

ixchel -a lilith_install

=head1 CODE SYNOPSIS

    use Data::Dumper;

    my $results=$ixchel->action(action=>'lilith_install', opts=>{});

=head1 RESULT HASH REF

    .errors :: A array of errors encountered.
    .status_text :: A string description of what was done and the results.
    .ok :: Set to zero if any of the above errored.

=cut

sub new {
	my ( $empty, %opts ) = @_;

	my $self = {
		config => {},
		vars   => {},
		arggv  => [],
		opts   => {},
	};
	bless $self;

	if ( defined( $opts{config} ) ) {
		$self->{config} = $opts{config};
	}

	if ( defined( $opts{t} ) ) {
		$self->{t} = $opts{t};
	} else {
		die('$opts{t} is undef');
	}

	if ( defined( $opts{share_dir} ) ) {
		$self->{share_dir} = $opts{share_dir};
	}

	if ( defined( $opts{opts} ) ) {
		$self->{opts} = \%{ $opts{opts} };
	}

	if ( defined( $opts{argv} ) ) {
		$self->{argv} = $opts{argv};
	}

	if ( defined( $opts{vars} ) ) {
		$self->{vars} = $opts{vars};
	}

	if ( defined( $opts{ixchel} ) ) {
		$self->{ixchel} = $opts{ixchel};
	}

	$self->{results} = {
		errors      => [],
		status_text => '',
		ok          => 0,
	};

	return $self;
} ## end sub new

sub action {
	my $self = $_[0];

	$self->status_add( status => 'Installing Lilith depends via packages' );

	my @depends = (
		'TOML',                   'DBI',             'JSON',         'File::ReadBackwards',
		'Digest::SHA',            'POE',             'File::Slurp',  'MIME::Base64',
		'Gzip::Faster',           'DBD::Pg',         'Data::Dumper', 'Text::ANSITable',
		'Net::Server::Daemonize', 'Sys::Syslog',     'YAML::PP',     'File::Slurp',
		'TOML',                   'Term::ANSIColor', 'MIME::Base64', 'Time::Piece::Guess'
	);

	$self->status_add( status => 'Perl Depends: ' . join( ', ', @depends ) );

	my @installed;
	my @failed;

	foreach my $depend (@depends) {
		my $status;
		$self->status_add( status => 'Trying to install ' . $depend . ' as a package...' );
		eval { $status = perl_module_via_pkg( module => $depend ); };
		if ($@) {
			push( @failed, $depend );
			$self->status_add( status => $depend . ' could not be installed as a package' );
		} else {
			push( @installed, $depend );
			$self->status_add( status => $depend . ' could not be installed as a package' );
		}
	} ## end foreach my $depend (@depends)

	system( 'cpanm', 'Lilith' );
	if ( $? != 0 ) {
		$self->status_add( status => 'Failed to install Lilith via cpanm', error => 1 );
	} else {
		$self->status_add( status => 'Lilith installed' );
	}

	$self->status_add( status => 'Installed via Packages: ' . join( ', ', @installed ) );
	$self->status_add( status => 'Needed via cpanm: ' . join( ', ', @failed ) );

	if ( !defined( $self->{results}{errors}[0] ) ) {
		$self->{results}{ok} = 1;
	} else {
		$self->{results}{ok} = 0;
	}

	return $self->{results};
} ## end sub action

sub short {
	return 'Installs Lilith using packages as much as possible.';
}

sub opts_data {
	return '
';
}

sub status_add {
	my ( $self, %opts ) = @_;

	if ( !defined( $opts{status} ) ) {
		return;
	}

	if ( !defined( $opts{error} ) ) {
		$opts{error} = 0;
	}

	if ( !defined( $opts{type} ) ) {
		$opts{type} = 'lilith_install';
	}

	my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime(time);
	my $timestamp = sprintf( "%04d-%02d-%02dT%02d:%02d:%02d", $year + 1900, $mon + 1, $mday, $hour, $min, $sec );

	my $status = '[' . $timestamp . '] [' . $opts{type} . ', ' . $opts{error} . '] ' . $opts{status};

	print $status. "\n";

	$self->{results}{status_text} = $self->{results}{status_text} . $status;

	if ( $opts{error} ) {
		push( @{ $self->{results}{errors} }, $opts{status} );
	}
} ## end sub status_add

1;
