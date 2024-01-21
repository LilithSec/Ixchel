package Ixchel::Actions::base;

use 5.006;
use strict;
use warnings;

=head1 NAME

Ixchel::Actions::base - Base module for actions.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    my $results=$ixchel->action(action=>'perl_module_via_pkg', opts=>{module=>'Monitoring::Sneck'});

=head2 DESCRIPTION

=head1 RESULT HASH REF

    .errors :: A array of errors encountered.
    .status_text :: A string description of what was done and the results.
    .ok :: Set to zero if any of the above errored.

=cut

sub new {
	my ( $empty, %opts ) = @_;

	my $self = {
		config   => {},
		vars     => {},
		arggv    => [],
		opts     => {},
		no_print => 0,
	};
	bless $self;

	$self->{type} = ref($self);
	$self->{type} =~ s/^Ixchel\:\:Actions\:\://;

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

	$self->new_extra;

	$self->{results} = {
		errors      => [],
		status_text => '',
		ok          => 0,
	};

	return $self;
} ## end sub new

=head2 status_add

Adds a item to $self->{results}{status_text}.

The following are required.

    - status :: Status to add.
        Default :: undef

The following are optional.

    - error :: A Perl boolean for if it is a error or not. If true
            it will be pushed to the array $self->{results}{errors}.
        Default :: undef

    - type :: What to display the current type as in the status line.
        Default :: $action

=cut

sub status_add {
	my ( $self, %opts ) = @_;

	if ( !defined( $opts{status} ) ) {
		return;
	}

	if ( !defined( $opts{error} ) ) {
		$opts{error} = 0;
	}

	if ( !defined( $opts{type} ) ) {
		$opts{type} = $self->{type};
	}

	my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime(time);
	my $timestamp = sprintf( "%04d-%02d-%02dT%02d:%02d:%02d", $year + 1900, $mon + 1, $mday, $hour, $min, $sec );

	my $status = '[' . $timestamp . '] [' . $opts{type} . ', ' . $opts{error} . '] ' . $opts{status};

	if (!$self->{no_print}) {
		print $status. "\n";
	}

	$self->{results}{status_text} = $self->{results}{status_text} . $status;

	if ( $opts{error} ) {
		push( @{ $self->{results}{errors} }, $opts{status} );
	}
} ## end sub status_add

1;
