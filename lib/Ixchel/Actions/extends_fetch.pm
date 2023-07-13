package Ixchel::Actions::extends_fetch;

use 5.006;
use strict;
use warnings;
use LWP::Simple;
use File::Slurp;

=head1 NAME

Ixchel::Actions::extends_fetch :: Fetches relevant SNMP extends.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

Fetches the SNMP extends that are just a single file and makes them executable.

The output dir used is specified by .snmp.extend_base_dir in the config.

The following are used for setting the proxy.

    .proxy.ftp
    .proxy.http
    .proxy.https

=head1 Switches

None.

=cut

sub new {
	my ( $empty, %opts ) = @_;

	my $self = { config => undef, opts => {} };
	bless $self;

	if ( defined( $opts{config} ) ) {
		$self->{config} = \%{ $opts{config} };
	}

	if ( defined( $opts{opts} ) ) {
		$self->{opts} = \%{ $opts{opts} };
	}

	return $self;
} ## end sub new

sub action {
	my $self = $_[0];

	if ( !-f $self->{config}{snmp}{extend_base_dir} ) {
		mkdir( $self->{config}{snmp}{extend_base_dir} )
			|| die( $self->{config}{snmp}{extend_base_dir} . ' does not exist and could not be created... $@' );
	}

	my $statuses = {};

	my $general_map = {
		smart              => { fetch => 'smart-v1', },
		mysql              => { fetch => 'mysql', },
		fail2ban           => { fetch => 'fail2ban', },
		supervisord        => { fetch => 'supervisord.py', },
		linux_softnet_stat => { fetch => 'linux_softnet_stat', },
		opensearch         => { fetch => 'opensearch', },
		privoxy            => { fetch => 'privoxy', },
		chrony             => { fetch => 'chrony', },
		zfs                => { fetch => 'zfs', },
		ntp_client         => { fetch => 'ntp-client', },
		chronyd            => { fetch => 'chrony', },
	};
	my $snmp_base = 'https://raw.githubusercontent.com/librenms/librenms-agent/master/snmp/';

	my $other_map
		= { ifAlias => { fetch => 'https://raw.githubusercontent.com/librenms/librenms/master/scripts/ifAlias', }, };

	if ( defined( $self->{config}{proxy} ) ) {
		if ( defined( $self->{config}{proxy}{ftp} ) ) {
			$ENV{FTP_PROXY} = $self->{config}{proxy}{ftp};
		}
		if ( defined( $self->{config}{proxy}{http} ) ) {
			$ENV{HTTP_PROXY} = $self->{config}{proxy}{http};
		}
		if ( defined( $self->{config}{proxy}{https} ) ) {
			$ENV{HTTPS_PROXY} = $self->{config}{proxy}{https};
		}
	} ## end if ( defined( $self->{config}{proxy} ) )

	foreach my $extend ( keys( %{$general_map} ) ) {
		my $status = 0;
		if ( $self->{config}{snmp}{extends}{$extend}{enable} ) {
			print $extend. ' :: ';
			my $url     = $snmp_base . $general_map->{$extend}{fetch};
			my $content = get($url);
			if ( defined($content) ) {
				my $output = $self->{config}{snmp}{extend_base_dir} . '/' . $extend;
				eval { write_file( $output, $content ); };
				if ($@) {
					$status = 'Writing ' . $url . ' to ' . $output . ' failed... ' . $@;
					print $status;
				} else {
					print $url. ' -> ' . $output;
					system( 'chmod', '+x', $output );
				}
			} else {
				$status = 'Fetching ' . $url . ' failed';
				print $status;
			}
			print "\n";
		} ## end if ( $self->{config}{snmp}{extends}{$extend...})
		$statuses->{$extend} = $status;
	} ## end foreach my $extend ( keys( %{$general_map} ) )
	foreach my $extend ( keys( %{$other_map} ) ) {
		my $status = 0;
		if ( $self->{config}{snmp}{extends}{$extend}{enable} ) {
			print $extend. ' :: ';
			my $url     = $other_map->{$extend}{fetch};
			my $content = get($url);
			if ( defined($content) ) {
				my $output = $self->{config}{snmp}{extend_base_dir} . '/' . $extend;
				eval { write_file( $output, $content ); };
				if ($@) {
					$status = 'Writing ' . $url . ' to ' . $output . ' failed... ' . $@;
					print $status;
				} else {
					print $url. ' -> ' . $output;
					system( 'chmod', '+x', $output );
				}
			} else {
				$status = 'Fetching ' . $url . ' failed';
				print $status;
			}
			print "\n";
		} ## end if ( $self->{config}{snmp}{extends}{$extend...})
		$statuses->{$extend} = $status;
	} ## end foreach my $extend ( keys( %{$other_map} ) )

	return $statuses;
} ## end sub action

sub help {
	return 'Fetches the extends.

The output dir used is specified by .snmp.extend_base_dir in the config.

The following are used for setting the proxy.

    .proxy.ftp
    .proxy.http
    .proxy.https
';
}

sub short {
	return 'Prints data from the sys_info function.';
}

sub opts_data {
	return '';
}

1;
