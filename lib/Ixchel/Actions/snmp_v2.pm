package Ixchel::Actions::snmp_v2;

use 5.006;
use strict;
use warnings;
use File::Slurp;

=head1 NAME

Ixchel::Actions::snmp_v2 - Generates a config file SNMPD.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    my $filled_in=$ixchel->action(action=>'snmp_v2', opts=>{w=>1});

    print $filled_in;

=head1 DESCRIPTION

The template used is 'snmp_v2'.

The returned value is the filled in template..

=head1 FLAGS

=head2 -w

Write out the file instead of stdout.

=head2 -o <file>

File to write the out to if -w is specified.

Default :: /usr/local/etc/snmpd.conf

Linux Default :: /etc/snmp/snmpd.conf

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

	return $self;
} ## end sub new

sub action {
	my $self = $_[0];

	# set the default output for -o if not defined
	if ( !defined( $self->{opts}{o} ) ) {
		$self->{opts}{o} = $self->{config}{snmp}{config_file};
	}

	# set the default output for -o if not defined
	if ( !defined( $self->{opts}{w} ) ) {
		$self->{opts}{w} = 0;
	}

	my $filled_in;
	eval {
		$filled_in = $self->{ixchel}->action(
			action => 'template',
			vars   => {},
			opts   => {
				np => 1,
				t  => 'auto_cron',
			},
		);
	};
	if ($@) {
		die( 'Filling in the template failed... ' . $@ );
	}

	if ( $self->{opts}{w} ) {
		write_file( $self->{opts}{o}, $filled_in );
	} else {
		print $filled_in;
	}

	return $filled_in;
} ## end sub action

sub short {
	return 'Generates a config file SNMPD.';
}

sub opts_data {
	return '
w
o=s
';
}

1;
