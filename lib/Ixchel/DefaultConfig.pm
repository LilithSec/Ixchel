package Ixchel::DefaultConfig;

use 5.006;
use strict;
use warnings;

=head1 NAME

Ixchel::DefaultConfig - The default config used for with Ixchel.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use Ixchel::DefaultConfig;
    use Data::Dumper;

    print Dumper( Ixchel::DefaultConfig->get );

=head1 Functions

=head2 get

Returns a hash reference of the default config.

=cut

sub get {
	my $config = {
		suricata => {
			multi_intance => 0,
			config_base   => '/etc/suricata/',
			instances     => '',
			enable        => 0,
		},
		suricata_extract => {
			enable      => 0,
			url         => '',
			slug        => '',
			apikey      => '',
			filestore   => '',
			ignore      => '',
			ignoreHosts => '',
			env_proxy   => 1,
			stats_file  => '/var/cache/suricata_extract_submit_stats.json',
			stats_dir   => '/var/cache/suricata_extract_submit_stats/',
			interval    => '*/2 * * * *',
		},
		sagan => {
			multi_intance => 0,
			config_base   => '/usr/local/etc/',
			instances     => '',
			enable        => 0,
		},
		meer => {
			multi_intance => 0,
			config_base   => '/usr/local/etc/meer/',
			instances     => '',
			enable        => 0,
		},
		mariadb => {
			enable => 0,
		},
		apache2 => {
			enable  => 0,
			version => '2.4',
		},
		apache2 => {
			enable => 0,
		},
		chronyd => {
			enable => 0,
		},
		zfs => {
			enable => 0,
		},
		squid => {
			enable => 0,
		},
		proxy => {
			ftp   => '',
			http  => '',
			https => '',
		},
		apt => {
			proxy_https => '',
			proxy_http  => '',
			proxy_ftp   => '',
		},
		pkgs => {
			install => {},
			cpanm   => {},
		},
		snmp => {
			community         => 'public',
			extend_env        => 'PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin LC_ALL=C',
			syslocation       => '',
			syscontact        => '',
			extend_base_dir   => '/usr/local/etc/snmp',
			extend_avail_dir  => '',
			listen_types      => ['array'],
			listen_array      => [ 'udp:161', 'tcp:161' ],
			listen_file       => '',
			listen_script     => '',
			v3_limited_enable => '0',
			v3_limited_name   => '',
			v3_limited_pass   => '',
			extends           => {
				smart => {
					enable                 => 0,
					cache                  => '/var/cache/smart',
					use_cache              => 0,
					nightly_test           => 1,
					nightly_test           => 'long',
					config                 => '/usr/local/etc/smart-extend.conf',
					additional_update_args => '',
				},
				systemd            => { enable => 0, cache => '/var/cache/systemd.extend', use_cache => 1 },
				mysql              => { enable => 0, host  => '127.0.0.1', port => '3306', ssl => 0, timeout => 0, },
				sneck              => { enable => 0, },
				suricata_extract   => { enable => 0, },
				suricata           => { enable => 0, args => '', },
				sagan              => { enable => 0, args => '', },
				hv_monitor         => { enable => 0, },
				fail2ban           => { enable => 0, },
				supvervisord       => { enable => 0, },
				linux_softnet_stat => { enable => 0, },
				opensearch         => { enable => 0, host     => '127.0.0.1', port => 9200 },
				osupdate           => { enable => 1, interval => '*/5 * * * * ', },
				privoxy            => { enable => 0, log      => '/var/log/privoxy/logfile' },
				chronyd            => { enable => 0, },
				zfs                => { enable => 0, },
				squid              => { enable => 0, },
				ifAlias            => { enable => 0, },
				ntp_client         => { enable => 0, },
			},
		},
	};

	if ( $^O eq 'linux' ) {
		$config->{snmp}{extend_base_dir} = '/etc/snmp/';
		$config->{snmp}{linux_softnet_stat}{enable} = 1;
	}

	return $config;
} ## end sub get

1;
