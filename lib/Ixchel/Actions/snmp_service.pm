package Ixchel::Actions::snmp_service;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use Rex::Commands::Gather;
use Rex::Commands::Service;

# prevents Rex from printing out rex is exiting after the script ends
$::QUIET = 2;

=head1 NAME

Ixchel::Actions::snmp_service - Manage the snmpd service.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 CLI SYNOPSIS

ixchel -a snmp_service --enable [B<--start>|B<--stop>|B<--restart>|B<--stopstart>]

ixchel -a snmp_service --disable [B<--start>|B<--stop>|B<--restart>|B<--stopstart>]

ixchel -a snmp_service --start

ixchel -a snmp_service --stop

ixchel -a snmp_service --restart

ixchel -a snmp_service --stopstart

=head1 CODE SYNOPSIS

    use Data::Dumper;

    my $results=$ixchel->action(action=>'snmp_enable', opts=>{enable=>1,start=>1});

=head1 FLAGS

=head2 --enable

Enable the service.

My not be combined with --disable.

=head2 --disable

Disable the service.

My not be combined with --enable.

=head2 --start

Start the service.

May not be combined with.

    --start
    --stop
    --restart
    --stopstart

=head2 --stop

Stop the service.

May not be combined with.

    --start
    --stop
    --restart
    --stopstart

=head2 --restart

Restart the service.

May not be combined with.

    --start
    --stop
    --restart
    --stopstart

=head2 --stopstart

Stop and then restart the service.

May not be combined with.

    --start
    --stop
    --restart
    --stopstart

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

	$self->status_add( status => 'Enabling snmpd' );

	# make sure we don't have extra start/stop stuff specified
	my $extra_opts=0;
	my @various_opts=('restart', 'start', 'stop', 'stopstart');
	foreach my $item (@various_opts) {
		if (defined($self->{opts}{$item})) {
			$extra_opts++;
		}
	}
	if ($extra_opts > 1) {
		my $extra_opts_string='--'.join(', --',@various_opts);
		$self->status_add( error => 1, status => $extra_opts_string.' can not be combined' );
		return;
	}

	# make sure --enable and --disable are not both specified
	if ( $self->{opts}{enable} && $self->{opts}{disable} ) {
		$self->status_add( error => 1, status => '--disable and --enable may not be specified at the same time' );
		return;
	}

	# enable/disable it
	if ( $self->{opts}{enable} ) {
		eval { service 'snmpd', ensure => 'started'; };
		if ($@) {
			$self->status_add( error => 1, status => 'Errored enabling snmpd... ' . $@ );
		}
	} elsif ( $self->{opts}{disable} ) {
		eval { service 'snmpd', ensure => 'stopped'; };
		if ($@) {
			$self->status_add( error => 1, status => 'Errored disabling snmpd... ' . $@ );
		}
	}

	# start/stop it etc
	if ( $self->{opts}{restart} ) {
		eval { service 'snmpd' => 'restart'; };
		if ($@) {
			$self->status_add( error => 1, status => 'Errored restarting snmpd... ' . $@ );
		}
	} elsif ( $self->{opts}{start} ) {
		eval { service 'snmpd' => 'start'; };
		if ($@) {
			$self->status_add( error => 1, status => 'Errored starting snmpd... ' . $@ );
		}
	} elsif ( $self->{opts}{stop} ) {
		eval { service 'snmpd' => 'stop'; };
		if ($@) {
			$self->status_add( error => 1, status => 'Errored stopping snmpd... ' . $@ );
		}
	} elsif ( $self->{opts}{stopstart} ) {
		eval {
			service 'snmpd' => 'stop';
			service 'snmpd' => 'start';
		};
		if ($@) {
			$self->status_add( error => 1, status => 'Errored stopping and then starting snmpd... ' . $@ );
		}
	}

	if ( !defined( $self->{results}{errors}[0] ) ) {
		$self->{results}{ok} = 1;
	} else {
		$self->{results}{ok} = 0;
	}

	return $self->{results};
} ## end sub action

sub short {
	return 'Manage the snmpd service.';
}

sub opts_data {
	return '
enable
disable
start
stop
restart
stopstart
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
		$opts{type} = 'snmp_service';
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
