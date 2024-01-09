package Ixchel::Actions::sagan_conf_update;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use YAML::XS qw(Dump);

=head1 NAME

Ixchel::Actions::sagan_conf_update - Update the all Sagan confs.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';

=head1 SYNOPSIS

    use Data::Dumper;

    my $results=$ixchel->action(action=>'sagan_conf_update', opts=>{np=>1, w=>1, });

    print Dumper($results);

=head1 DESCRIPTION

This calls runs the following actions if
.sagan.merged_base_include is false.

    sagan_base
    sagan_include
    sagan_rules

This calls runs the following actions if
.sagan.merged_base_include is true.

    sagan_merged
    sagan_rules

=head1 FLAGS

=head2 --np

Do not print the status of it.

=head2 -w

Write the generated services to service files.

=head2 -i instance

A instance to operate on.

=head2 --no_base

Do not rebuild the base files.

Only relevant is the config item .sagan.merged_base_include
is false.

=head2 --no_include

Do not rebuild the include files.

Only relevant is the config item .sagan.merged_base_include
is false.

=head2 --no_merged

Do not rebuild the the merged base/include files.

Only relevant is the config item .sagan.merged_base_include
is true.

=head2 --no_rules

Do not rebuild the rules files.

=head1 RESULT HASH REF

    .errors :: A array of errors encountered.
    .status_text :: A string description of what was done and teh results.
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

	return $self;
} ## end sub new

sub action {
	my $self = $_[0];

	my $results = {
		errors      => [],
		status_text => '',
		ok          => 0,
	};

	my %opts = %{ $self->{opts} };
	$opts{np} = 1;

	if ( $self->{config}{sagan}{merged_base_include} ) {
		if ( !$self->{opts}{no_merged} ) {
			my $status   = '-----[ sagan_merged ]-------------------------------------' . "\n";
			my $returned = $self->{ixchel}->action( action => 'sagan_merged', opts => \%opts );
			if ( defined( $returned->{errors}[0] ) ) {
				$status = $status . join( "\n", @{ $returned->{errors} } ) . "\n";
			} else {
				$status = $status . "Completed with out errors.\n";
			}
			$results->{status_text} = $results->{status_text} . $status;
			push( @{ $results->{errors} }, @{ $returned->{errors} } );
		} ## end if ( !$self->{opts}{no_merged} )
	} else {
		if ( !$self->{opts}{no_base} ) {
			my $status   = '-----[ sagan_base ]-------------------------------------' . "\n";
			my $returned = $self->{ixchel}->action( action => 'sagan_base', opts => \%opts );
			if ( defined( $returned->{errors}[0] ) ) {
				$status = $status . join( "\n", @{ $returned->{errors} } ) . "\n";
			} else {
				$status = $status . "Completed with out errors.\n";
			}
			$results->{status_text} = $results->{status_text} . $status;
			push( @{ $results->{errors} }, @{ $returned->{errors} } );
		} ## end if ( !$self->{opts}{no_base} )

		if ( !$self->{opts}{no_include} ) {
			my $status   = '-----[ sagan_include ]-------------------------------------' . "\n";
			my $returned = $self->{ixchel}->action( action => 'sagan_include', opts => \%opts );
			if ( defined( $returned->{errors}[0] ) ) {
				$status = $status . join( "\n", @{ $returned->{errors} } ) . "\n";
			} else {
				$status = $status . "Completed with out errors.\n";
			}
			$results->{status_text} = $results->{status_text} . $status;
			push( @{ $results->{errors} }, @{ $returned->{errors} } );
		} ## end if ( !$self->{opts}{no_include} )
	} ## end else [ if ( $self->{config}{sagan}{merged_base_include...})]

	if ( !$self->{opts}{no_rules} ) {
		my $status   = '-----[ sagan_rules ]-------------------------------------' . "\n";
		my $returned = $self->{ixchel}->action( action => 'sagan_rules', opts => \%opts );
		if ( defined( $returned->{errors}[0] ) ) {
			$status = $status . join( "\n", @{ $returned->{errors} } ) . "\n";
		} else {
			$status = $status . "Completed with out errors.\n";
		}
		$results->{status_text} = $results->{status_text} . $status;
		push( @{ $results->{errors} }, @{ $returned->{errors} } );
	} ## end if ( !$self->{opts}{no_rules} )

	if ( !$self->{opts}{np} ) {
		print $results->{status_text};
	}

	if ( !defined( $results->{errors}[0] ) ) {
		$results->{ok} = 1;
	}

	return $results;
} ## end sub action

sub short {
	return 'Generates the instance specific include for a sagan instance.';
}

sub opts_data {
	return 'i=s
np
w
no_base
no_include
no_rules
no_merged
';
} ## end sub opts_data

1;
