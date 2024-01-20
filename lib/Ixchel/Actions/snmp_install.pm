package Ixchel::Actions::snmp_install;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use Rex::Commands::Gather;
use Rex::Commands::Pkg;

# prevents Rex from printing out rex is exiting after the script ends
$::QUIET = 2;

=head1 NAME

Ixchel::Actions::snmp_install - Installs snmpd and snmp utils.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use Data::Dumper;

    my $results=$ixchel->action(action=>'snmp_install', opts=>{});

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

	$self->status_add( status => 'Installing snmp utils and snmpd' );

	my @depends = ();

	if ( is_freebsd || is_netbsd || is_freebsd ) {
		$self->status_add( status => 'OS Family FreeBSD, NetBSD, or OpenBSD detectected' );
		push( @depends, 'net-snmp' );
	} elsif (is_debian) {
		$self->status_add( status => 'OS Family Debian detectected' );
		push( @depends, 'snmp', 'snmpd' );
	} elsif ( is_redhat || is_arch || is_suse || is_alt || is_mageia ) {
		$self->status_add( status => 'OS Family Redhat, Arch, Suse, Alt, or Mageia detectected' );
		push( @depends, 'net-snmp' );
	}

	$self->status_add( status => 'Packages: ' . join( ', ' . @depends ) );

	my @failed;
	my @installed;

	foreach my $pkg (@depends) {
		eval { pkg( $pkg, ensure => 'present' ); };
		if ($@) {
			$self->status_add( status => 'Installing ' . $pkg . ' failed... ' . $@, error => 1 );
			push( @failed, $pkg );
		} else {
			$self->status_add( status => 'Installed ' . $pkg );
			push( @installed, $pkg );
		}
	} ## end foreach my $pkg (@depends)

	$self->status_add( status => 'Failed: ' . join( ', ', @failed ), error => 1 );
	$self->status_add( status => 'Installed: ' . join( ', ', @installed ) );

	if ( !defined( $self->{results}{errors}[0] ) ) {
		$self->{results}{ok} = 1;
	} else {
		$self->{results}{ok} = 0;
	}

	return $self->{results};
} ## end sub action

sub short {
	return 'Installs snmpd and snmp utils.';
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
		$opts{type} = 'snmp_install';
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
