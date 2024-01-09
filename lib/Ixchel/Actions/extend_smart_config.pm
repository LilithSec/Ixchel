package Ixchel::Actions::extend_smart_config;

use 5.006;
use strict;
use warnings;
use File::Slurp;

=head1 NAME

Ixchel::Actions::extend_smart_config - Generates the config for the SMART SNMP extend.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    my $filled_in=$ixchel->action(action=>'extends_smart_config', opts=>{w=>1});

    print $filled_in;

=head1 DESCRIPTION

This invokes the extend with -g to generate a base config.

The returned value is the filed in template.

If snmp.extends.smart.additional_update_args is defined and
not blank, these tacked on to the command.

=head1 FLAGS

=head2 -w

Write out the file instead of stdout.

=head2 -o <file>

File to write the out to if -w is specified.

Default :: /usr/local/etc/smart-extend.conf

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
		$self->{opts}{o} = '/usr/local/etc/smart-extend.conf';
	}

	# set the default output for -o if not defined
	if ( !defined( $self->{opts}{w} ) ) {
		$self->{opts}{w} = 0;
	}

	my $command=$self->{config}{snmp}{extend_base_dir}.'/smart -g';
	if ($self->{config}{snmp}{extends}{smart}{additional_update_args}) {
		$command=$command.' '.$self->{config}{snmp}{extends}{smart}{additional_update_args};
	}
	my $filled_in=`$command 2>&1`;

	if ( $self->{opts}{w} ) {
		write_file( $self->{opts}{o}, $filled_in );
	} else {
		print $filled_in;
	}

	return $filled_in;
} ## end sub action

sub short {
	return 'Generates the config for the SMART SNMP extend.';
}

sub opts_data {
	return '
w
o=s
';
}

1;
