package Ixchel::Actions::dump_config;

use 5.006;
use strict;
use warnings;
use Ixchel::functions::sys_info;
use TOML qw(to_toml);
use JSON qw(to_json);
use YAML qw(Dump);
use Data::Dumper;

=head1 NAME

Ixchel::Actions::sys_info :: Prints out the config.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

Prints out the config.

=head1 Switches

=head2 -o <format>

Format to print it in.

Available: json, yaml, toml

Default: toml

=cut

sub new {
	my ( $empty, %opts ) = @_;



	if (!defined($opts{config})) {
		die('$opts{config} is undef');
	}

	my $self = { config => $opts{config}, opts => {} };
	bless $self;

	if ( defined( $opts{opts} ) ) {
		$self->{opts} = \%{ $opts{opts} };
	}

	return $self;
} ## end sub new

sub action {
	my $self = $_[0];

	if ( !defined( $self->{opts}->{o} ) ) {
		$self->{opts}->{o} = 'toml';
	}

	if (   $self->{opts}->{o} eq 'toml'
		&& $self->{opts}->{o} eq 'json'
		&& $self->{opts}->{o} eq 'dumper'
		&& $self->{opts}->{o} eq 'yaml' )
	{
		die( '-o is set to "' . $self->{opts}->{o} . '" which is not a understood setting' );
	}

	my $string;
	if ( $self->{opts}->{o} eq 'toml' ) {
		$string = to_toml( $self->{config}) . "\n";
		print $string;
	} elsif ( $self->{opts}->{o} eq 'json' ) {
		my $json = JSON->new;
		$json->canonical(1);
		$json->pretty(1);
		$string = $json->encode($self->{config});
		print $string;
	} elsif ( $self->{opts}->{o} eq 'yaml' ) {
		$string = Dump($self->{config});
		print $string;
	}

	return $string;
} ## end sub action

sub help {
	return 'Prints data from the sys_info function.

-o <format>     Format to print it in.
                Available: json, yaml, toml
                Default: toml
';
}

sub short {
	return 'Dumps the config to to JSON, YAML, or TOML(default)';
}

sub opts_data {
	return 'o=s';
}

1;
