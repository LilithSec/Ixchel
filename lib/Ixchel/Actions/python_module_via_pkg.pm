package Ixchel::Actions::python_module_via_pkg;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use Ixchel::functions::python_module_via_pkg;

=head1 NAME

Ixchel::Actions::python_module_via_pkg - Install cpanm via packages.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';

=head1 CLI SYNOPSIS

ixchel -a python_module_via_pkg B<--module> <module>

=head1 CODE SYNOPSIS

    use Data::Dumper;

    my $results=$ixchel->action(action=>'python_module_via_pkg', opts=>{module=>'Dumper'});

=head1 FLAGS

=head2 --module <module>

The module to install.

This is required.

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

	if ( !defined( $self->{opts}{module} ) ) {
		die('--module is undef');
	}

	$self->status_add( status => 'Installing python3 module via packges' );

	my $status;
	eval { $status=python_module_via_pkg( module => $self->{opts}{module}, no_print=>1 ); };
	if ($@) {
		$self->{results}{status_text}=$self->{results}{status_text}.$@;
		$self->status_add(
			status => 'Failed to install ' . $self->{opts}{module} . ' via packages',
			error  => 1
		);
	} else {
		$self->{results}{status_text}=$self->{results}{status_text}.$status;
		$self->status_add( status => $self->{opts}{module} . ' installed' );
	}

	return $self->{results};
} ## end sub action

sub short {
	return 'Install a Python module via packages';
}

sub opts_data {
	return '
module=s
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
		$opts{type} = 'python_module_via_pkg';
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
