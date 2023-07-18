package Ixchel::Actions::suricata_include;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use YAML qw(Dump);

=head1 NAME

Ixchel::Actions::suricata_include :: Generates the instance specific include for a suricata instance.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use Data::Dumper;

    my $results=$ixchel->action(action=>'suricata_include', opts=>{np=>1, w=>1, });

    print Dumper($results);

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

	my $config_base = $self->{config}{suricata}{config_base};

	if ( $self->{config}{suricata}{multi_instance} ) {
		my @instances;

		my @vars_to_migrate = ( 'enable_fastlog', 'enable_syslog', 'filestore_enable', 'dhcp_in_alert_eve' );

		if ( defined( $self->{opts}{i} ) ) {
			@instances = ( $self->{opts}{i} );
		} else {
			@instances = keys( %{ $self->{config}{suricata}{instances} } );
		}
		foreach my $instance (@instances) {
			my $filled_in;
			eval {
				my $base_config = $self->{config}{suricata}{config};

				if ( !defined( $self->{config}{suricata}{instances}{$instance} ) ) {
					die( $instance . ' does not exist under .suricata.instances' );
				}

				my $config = $self->{config}{suricata}{instances}{$instance};

				my $merger = Hash::Merge->new('RIGHT_PRECEDENT');
				# make sure arrays from the actual config replace any arrays in the defaultconfig
				$merger->add_behavior_spec(
					{
						'SCALAR' => {
							'SCALAR' => sub { $_[1] },
							'ARRAY'  => sub { [ $_[0], @{ $_[1] } ] },
							'HASH'   => sub { $_[1] },
						},
						'ARRAY' => {
							'SCALAR' => sub { $_[1] },
							'ARRAY'  => sub { [ @{ $_[1] } ] },
							'HASH'   => sub { $_[1] },
						},
						'HASH' => {
							'SCALAR' => sub { $_[1] },
							'ARRAY'  => sub { [ values %{ $_[0] }, @{ $_[1] } ] },
							'HASH'   => sub { Hash::Merge::_merge_hashes( $_[0], $_[1] ) },
						},
					},
					'Ixchel',
										   );
				my %tmp_config=%{ $config };
				my %tmp_base_config=%{ $base_config };
				my $merged = $merger->merge( \%tmp_base_config, \%tmp_config );

				$filled_in = '%YAML 1.1'."\n".Dump($merged);

				if ( $self->{opts}{w} ) {
					write_file( $config_base . '/include-' . $instance . '.yaml', $filled_in );
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
			die('-i may not be used in single instance mode, .suricata.multi_intance=1, ,');
		}

		my $filled_in;
		eval {
			my $config = $self->{config}{suricata}{config};
			$filled_in = '%YAML 1.1'."\n".Dump($config);

			if ( $self->{opts}{w} ) {
				write_file( $config_base . '/include.yaml', $filled_in );
			}
		};
		if ($@) {
			$results->{status_text} = '# ' . $@;
		} else {
			$results->{status_text} = $filled_in;
		}
	} ## end else [ if ( $self->{config}{suricata}{multi_intance...})]

	if ( !$self->{opts}{np} ) {
		print $results->{status_text};
	}

	if (!defined($results->{errors}[0])) {
		$results->{ok}=1;
	}

	return $results;
} ## end sub action

sub help {
	return 'Generates the instance specific include for a suricata instance.

--np          Do not print the status of it.

-w            Write the generated includes out.

-i <instance> A instance to operate on.

';
} ## end sub help

sub short {
	return 'Generates the instance specific include for a suricata instance.';
}

sub opts_data {
	return 'i=s
np
w
';
}

1;
