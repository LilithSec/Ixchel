package Ixchel::Actions::snmp_extends;

use 5.006;
use strict;
use warnings;
use File::Slurp;

=head1 NAME

Ixchel::Actions::snmp_extends :: List or install/update SNMP extends

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use Data::Dumper;

    my $results=$ixchel->action(action=>'', opts=>{u=>1});

=head1 FLAGS

=head2 -l

List the extends enabled.

=head2 -u

Update or install extends.

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
		ok          => 1,
	};

	return $self;
} ## end sub new

sub action {
	my $self = $_[0];

	if ( !$self->{opts}{l} && !$self->{opts}{u} ) {
		$self->status_add( error => 1, status => 'Neither -l or -u specified' );
		return $self->{results};
	} elsif ( $self->{opts}{l} && $self->{opts}{u} ) {
		$self->status_add( error => 1, status => 'Both -l and -u specified' );
		return $self->{results};
	}

	if ( $self->{opts}{l} ) {
		my @extends = keys( %{ $self->{config}{snmp}{extends} } );
		my @enabled;
		my @disabled;
		foreach my $item (@extends) {
			if ( $self->{config}{snmp}{extends}{$item}{enable} ) {
				push( @enabled, $item );
			} else {
				push( @disabled, $item );
			}
		}
		$self->status_add(status=>'Currently Enabled: '.join(',', @enabled));
		$self->status_add(status=>'Currently Disabled: '.join(',', @disabled));
	} ## end if ( $self->{opts}{u} )

	if ( $self->{opts}{u} ) {
		my @extends = keys( %{ $self->{config}{snmp}{extends} } );
		my @disabled;
		my @errored;
		my @installed;
		push(@extends, 'distro');
		foreach my $item (@extends) {
			if ( $self->{config}{snmp}{extends}{$item}{enable} ) {
				my $results;
				my $error = 0;
				$self->status_add(status=>'Calling xeno for librenms/extends/' . $item);
				eval {
					$results
						= $self->{ixchel}->action( action => 'xeno', opts => { r => 'librenms/extends/' . $item } );
				};
				if ( $@ || !defined($results) || defined( $results->{errors}[0] ) ) {
					$error = 1;
					use Data::Dumper; print Dumper($results);
					$self->status_add(
									  np     => 1,
									  error  => $error,
									  status => 'Errored installing/updating librenms/extends/'
									  . $item
									  );
					push( @errored, $item );
				}else {
					push( @installed, $item );
				}
			}else {
				push( @disabled, $item );
			} ## end if ( $self->{config}{snmp}{extends}{$item}...)
		} ## end foreach my $item (@extends)
		$self->status_add(status=>'Currently Disabled: '.join(',', @disabled));
		$self->status_add(status=>'Installed/Updated: '.join(',', @installed));
		$self->status_add(status=>'Errored: '.join(',', @errored));
	} ## end if ( $self->{opts}{u} )

} ## end sub action

sub short {
	return 'List or install/update SNMP extends';
}

sub opts_data {
	return '
l
u
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

	if ( $opts{error} ) {
		$self->{results}{ok} = 0;
	}

	if ( !defined( $opts{type} ) ) {
		$opts{type} = 'snmp_extends';
	}

	my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime(time);
	my $timestamp = sprintf( "%04d-%02d-%02dT%02d:%02d:%02d", $year + 1900, $mon + 1, $mday, $hour, $min, $sec );

	my $status = '[' . $timestamp . '] [' . $opts{type} . ', ' . $opts{error} . '] ' . $opts{status};

	if ( !$opts{no_print} ) {
		print $status. "\n";
	}

	$self->{results}{status_text} = $self->{results}{status_text} . $status;

	if ( $opts{error} ) {
		push( @{ $self->{results}{errors} }, $opts{status} );
	}
} ## end sub status_add

1;
