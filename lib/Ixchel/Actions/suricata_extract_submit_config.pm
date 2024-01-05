package Ixchel::Actions::suricata_extract_submit_config;

use 5.006;
use strict;
use warnings;
use File::Slurp;

=head1 NAME

Ixchel::Actions::suricata_extract_submit_config :: Generates the config file for suricata_extract_submit.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    my $filled_in=$ixchel->action(action=>'suricata_extract_submit_config', opts=>{w=>1});

    print $filled_in;

=head1 DESCRIPTION

The template used is 'suricata_extract_submit'.

The returned value is the filed in template.

=head1 FLAGS

=head2 -w

Write out the file instead of stdout.

=head2 -o <file>

File to write the out to if -w is specified.

Default :: /usr/local/etc/suricata_extract_submit.ini

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
		$self->{opts}{o} = '/usr/local/etc/suricata_extract_submit.ini';
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
				t  => 'suricata_extract_submit',
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
	return 'Generates the config file for suricata_extract_submit.';
}

sub opts_data {
	return '
w
o=s
';
}

1;
