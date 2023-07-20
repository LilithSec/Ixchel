package Ixchel::Actions::suricata_outputs;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use String::ShellQuote;

=head1 NAME

Ixchel::Actions::suricata_ouputs :: Generate a outputs include for suricata.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use Data::Dumper;

    my $results=$ixchel->action(action=>'suricata_outputs', opts=>{np=>1, w=>1, });

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
			my $vars = {
				enable_fastlog    => $self->{config}{suricata}{enable_fastlog},
				enable_syslog     => $self->{config}{suricata}{enable_syslog},
				filestore_enable  => $self->{config}{suricata}{filestore_enable},
				dhcp_in_alert_eve => $self->{config}{suricata}{dhcp_in_alert_eve},
				instance_part     => '-' . $instance,
			};

			foreach my $to_migrate (@vars_to_migrate) {
				if ( defined( $self->{config}{suricata}{instances}{$instance}{$to_migrate} ) ) {
					$vars->{$to_migrate} = $self->{config}{suricata}{instances}{$instance}{$to_migrate};
				}
			}

			my $filled_in;
			eval {
				$filled_in = $self->{ixchel}->action(
					action => 'template',
					vars   => $vars,
					opts   => {
						np => 1,
						t  => 'suricata_outputs',
					},
				);
				if ( $self->{opts}{w} ) {
					write_file( $config_base . '/outputs-' . $instance . '.yaml', $filled_in );
				}
			};
			if ($@) {
				$results->{status_text}
					= $results->{status_text}
					. '-----[ Errored: '
					. $instance
					. ' ]-------------------------------------' . "\n" . '# '
					. $@ . "\n";
				$self->{ixchel}{errors_count}++;
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
			die('-i may not be used in single instance mode');
		}

		my $vars = {
			enable_fastlog    => $self->{config}{suricata}{enable_fastlog},
			enable_syslog     => $self->{config}{suricata}{enable_syslog},
			filestore_enable  => $self->{config}{suricata}{filestore_enable},
			dhcp_in_alert_eve => $self->{config}{suricata}{dhcp_in_alert_eve},
			instance_part     => '',
		};

		my $filled_in;
		eval {
			$filled_in = $self->{ixchel}->action(
				action => 'template',
				vars   => $vars,
				opts   => {
					np => 1,
					t  => 'suricata_outputs',
				},
			);

			if ( $self->{opts}{w} ) {
				write_file( $config_base . '/outputs.yaml', $filled_in );
			}
		};
		if ($@) {
			$results->{status_text} = '# ' . $@ . "\n";
			$self->{ixchel}{errors_count}++;
		} else {
			$results->{status_text} = $filled_in;
		}
	} ## end else [ if ( $self->{config}{suricata}{multi_instance...})]

	if ( !$self->{opts}{np} ) {
		print $results->{status_text};
	}

	if ( !defined( $results->{errors}[0] ) ) {
		$results->{ok} = 1;
	}

	return $results;
} ## end sub action

sub help {
	return 'Generate a outputs include for suricata.

--np          Do not print the status of it.

-w            Write the generated services to service files.

-i <instance> A instance to operate on.

';
} ## end sub help

sub short {
	return 'Generate a outputs include for suricata.';
}

sub opts_data {
	return 'i=s
np
w
';
}

1;