package Ixchel::Actions::pkgs;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use Rex::Commands::Pkg;

=head1 NAME

Ixchel::Actions::pkgs - Handles making sure desired packages are installed as specified by the config.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';

=head1 SYNOPSIS

    use Data::Dumper;

    my $results=$ixchel->action(action=>'pkgs', opts=>{}'});

=head1 DESCRIPTION

The modules to be installed are determined by the config.

    - .pkgs.latest :: Packages to ensure that are installed and up to date, updating if needed.
       - Default :: []

    - .pkgs.present :: Packages to ensure that are installed, installing if not needed. Will not update
            the package if it is installed an update is available.
        - Default :: []

    - .pkgs.absent :: Packages to ensure that are not installed, uninstalling if present.
        - Default :: []

=head1 FLAGS

None.

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

	$self->{results} = {
		errors      => [],
		status_text => '',
		ok          => 0,
	};

	my $latest = '';
	my @latest_failed;
	my @latest_handled;
	my $present = '';
	my @present_failed;
	my @present_handled;
	my $absent = '';
	my @absent_failed;
	my @absent_handled;

	if ( ref( $self->{config}{pkgs}{latest} ) eq 'ARRAY' && defined( $self->{config}{pkgs}{latest}[0] ) ) {
		$latest = join( ', ', @{ $self->{config}{pkgs}{latest} } );
		$self->status_add( status => 'Starting Latest: ' . $latest );
		foreach my $pkg ( @{ $self->{config}{pkgs}{latest} } ) {
			$self->status_add( status => 'ensuring ' . $pkg . ' is latest..' );
			eval { pkg( $pkg, ensure => 'latest' ); };
			if ($@) {
				$self->status_add( status => $pkg . ' errored... ' . $@, error => 1 );
				push( @latest_failed, $pkg );
			} else {
				push( @latest_handled, $pkg );
			}
		} ## end foreach my $pkg ( @{ $self->{config}{pkgs}{latest...}})
	} ## end if ( ref( $self->{config}{pkgs}{latest} ) ...)

	if ( ref( $self->{config}{pkgs}{present} ) eq 'ARRAY' && defined( $self->{config}{pkgs}{present}[0] ) ) {
		$present = join( ', ', @{ $self->{config}{pkgs}{present} } );
		$self->status_add( status => 'Starting Present: ' . $present );
		foreach my $pkg ( @{ $self->{config}{pkgs}{present} } ) {
			$self->status_add( status => 'ensuring ' . $pkg . ' is present...' );
			eval { pkg( $pkg, ensure => 'present' ); };
			if ($@) {
				$self->status_add( status => $pkg . ' errored... ' . $@, error => 1 );
				push( @present_failed, $pkg );
			} else {
				push( @present_handled, $pkg );
			}
		} ## end foreach my $pkg ( @{ $self->{config}{pkgs}{present...}})
	} ## end if ( ref( $self->{config}{pkgs}{present} )...)

	if ( ref( $self->{config}{pkgs}{absent} ) eq 'ARRAY' && defined( $self->{config}{pkgs}{absent}[0] ) ) {
		$absent = join( ', ', @{ $self->{config}{pkgs}{absent} } );
		$self->status_add( status => 'Starting Absent: ' . $absent );
		foreach my $pkg ( @{ $self->{config}{pkgs}{absent} } ) {
			$self->status_add( status => 'ensuring ' . $pkg . ' is absent...' );
			eval { pkg( $pkg, ensure => 'absent' ); };
			if ($@) {
				$self->status_add( status => $pkg . ' errored... ' . $@, error => 1 );
				push( @absent_failed, $pkg );
			} else {
				push( @absent_handled, $pkg );
			}
		} ## end foreach my $pkg ( @{ $self->{config}{pkgs}{absent...}})
	} ## end if ( ref( $self->{config}{pkgs}{absent} ) ...)

	$self->status_add( status => 'Latest: ' . $latest );
	$self->status_add( status => 'Latest Handled: ' . join( ', ', @latest_handled ) );
	$self->status_add( status => 'Latest Failed: ' . join( ', ', @latest_failed ) );
	$self->status_add( status => 'Present: ' . join( ', ', @{ $self->{config}{pkgs}{present} } ) );
	$self->status_add( status => 'Present Handled: ' . $present );
	$self->status_add( status => 'Present Failed: ' . join( ', ', @present_failed ) );
	$self->status_add( status => 'Absent: ' . $absent );
	$self->status_add( status => 'Absent Handled: ' . join( ', ', @absent_handled ) );
	$self->status_add( status => 'Absent Failed: ' . join( ', ', @absent_failed ) );

	return $self->{results};
} ## end sub action

sub short {
	return 'Install packages specified by the config.';
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
		$opts{type} = 'pkgs';
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
