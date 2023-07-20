package Ixchel::Actions::sagan_rules;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use YAML::XS   qw(Dump);
use List::Util qw(uniq);

=head1 NAME

Ixchel::Actions::sagan_rules :: Generate the rules include for Sagan.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use Data::Dumper;

    my $results=$ixchel->action(action=>'sagan_rules', opts=>{np=>1, w=>1, });

    print Dumper($results);

Generates the rules include for sagan using the array .sagan.rules and
if .sagan.instances_rules.$instance exists, that will be merged into it.

The resulting array is deduplicated using uniq.

Any item that does not match /\// has '$RULE_PATH/' prepended to it.

=head1 FLAGS

=head2 --np

Do not print the status of it.

=head2 -w

Write the generated services to service files.

=head2 -i instance

A instance to operate on.

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

	my $config_base = $self->{config}{sagan}{config_base};

	if ( $self->{config}{sagan}{multi_instance} ) {
		my @instances;

		if ( defined( $self->{opts}{i} ) ) {
			@instances = ( $self->{opts}{i} );
		} else {
			@instances = keys( %{ $self->{config}{sagan}{instances} } );
		}
		foreach my $instance (@instances) {
			my $filled_in;
			eval {
				my @rules = @{ $self->{config}{sagan}{rules} };
				if ( defined( $self->{config}{sagan}{instances_rules}{$instance} ) ) {
					push( @rules, @{ $self->{config}{sagan}{instances_rules}{$instance} } );
				}
				@rules = uniq( sort(@rules) );

				my $int = 0;
				while ( defined( $rules[$int] ) ) {
					if ( $rules[$int] !~ /\// ) {
						$rules[$int] = '$RULE_PATH/' . $rules[$int];
					}
					$int++;
				}

				$filled_in = '%YAML 1.1' . "\n" . Dump( { 'rules-files' => \@rules } );

				if ( $self->{opts}{w} ) {
					write_file( $config_base . '/sagan-rules-' . $instance . '.yaml', $filled_in );
				}
			};
			if ($@) {
				$results->{status_text}
					= $results->{status_text}
					. '-----[ Errored: '
					. $instance
					. ' ]-------------------------------------' . "\n" . '# '
					. $@ . "\n";
			} else {
				$results->{status_text}
					= $results->{status_text}
					. '-----[ '
					. $instance
					. ' ]-------------------------------------' . "\n"
					. $filled_in . "\n";
			}

		} ## end foreach my $instance (@instances)
	} else {
		if ( defined( $self->{opts}{i} ) ) {
			die('-i may not be used in single instance mode, .sagan.multi_intance=1, ,');
		}

		my $filled_in;
		eval {
			my @rules = @{ $self->{config}{sagan}{rules} };
			@rules = uniq( sort(@rules) );

			my $int = 0;
			while ( defined( $rules[$int] ) ) {
				if ( $rules[$int] !~ /\// ) {
					$rules[$int] = '$RULE_PATH/' . $rules[$int];
				}
				$int++;
			}

			$filled_in = '%YAML 1.1' . "\n" . Dump( { 'rules-files' => \@rules } );

			if ( $self->{opts}{w} ) {
				write_file( $config_base . '/sagan-rules.yaml', $filled_in );
			}
		};
		if ($@) {
			$results->{status_text} = '# ' . $@;
		} else {
			$results->{status_text} = $filled_in;
		}
	} ## end else [ if ( $self->{config}{sagan}{multi_instance...})]

	if ( !$self->{opts}{np} ) {
		print $results->{status_text};
	}

	if ( !defined( $results->{errors}[0] ) ) {
		$results->{ok} = 1;
	}

	return $results;
} ## end sub action

sub help {
	return 'Generate the rules include for Sagan.

--np          Do not print the status of it.

-w            Write the generated includes out.

-i <instance> A instance to operate on.

';
} ## end sub help

sub short {
	return 'Generate the rules include for Sagan.';
}

sub opts_data {
	return 'i=s
np
w
';
}

1;
