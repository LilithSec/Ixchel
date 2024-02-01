package Ixchel::Actions::suricata_include;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use YAML::XS qw(Dump);
use base 'Ixchel::Actions::base';

=head1 NAME

Ixchel::Actions::suricata_include - Generates the instance specific include for a suricata instance.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';

=head1 CLI SYNOPSIS

ixchel -a suricata_include [B<-i> <instance>] [B<-d> <base_dir>]

ixchel -a suricata_include [B<-w>] [B<--np>] [B<-i> <instance>] [B<-d> <base_dir>]

=head1 CODE SYNOPSIS

    use Data::Dumper;

    my $results=$ixchel->action(action=>'suricata_include', opts=>{np=>1, w=>1, });

    print Dumper($results);

=head1 DESCRIPTION

This generates a the general purpose include for Suricata.

The include is generated by first reading in the values under .suricata.config and
then if multiple instances are enabled, then .suricata.instances.$instance is merged
into it. Arrays are replaced with the new array while the rest are just merged using
L<Hash::Merge> using RIGHT_PRECEDENT with the right being
.suricata.instances.$instance .

If told to write it out, it will be written out to undef .suricata.config_base with  the name "include.yaml"
or "include-$instance.yaml" if multiple instances are in use.

=head1 FLAGS

=head2 -w

Write the generated services to service files.

=head2 -i instance

A instance to operate on.

=head2 -d <base_dir>

Use this as the base dir instead of .suricata.config_base from the config.

=head1 RESULT HASH REF

    .errors :: A array of errors encountered.
    .status_text :: A string description of what was done and teh results.
    .ok :: Set to zero if any of the above errored.

=cut

sub new_extra { }

sub action_extra {
	my $self = $_[0];

	my $config_base;
	if ( !defined( $self->{opts}{d} ) ) {
		$config_base = $self->{config}{suricata}{config_base};
	} else {
		if ( !-d $self->{opts}{d} ) {
			$self->status_add(
				status => '-d, "' . $self->{opts}{d} . '" is not a directory',
				error  => 1,
			);
			return undef;
		}
		$config_base = $self->{opts}{d};
	} ## end else [ if ( !defined( $self->{opts}{d} ) ) ]

	if ( $self->{config}{suricata}{multi_instance} ) {
		my @instances;

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
					$self->status_add(
						status => $instance . ' does not exist under .suricata.instances',
						error  => 1,
					);
					return undef;
				}

				my $config = $self->{config}{suricata}{instances}{$instance};

				my $merger = Hash::Merge->new('RIGHT_PRECEDENT');
				my %tmp_config      = %{$config};
				my %tmp_base_config = %{$base_config};
				my $merged          = $merger->merge( \%tmp_base_config, \%tmp_config );

				$filled_in = '%YAML 1.1' . "\n" . Dump($merged);

				if ( $self->{opts}{w} ) {
					write_file( $config_base . '/' . $instance . '-include.yaml', $filled_in );
				}
			};
			if ($@) {
				$self->status_add(
					status => '-----[ Errored: '
						. $instance
						. ' ]-------------------------------------' . "\n" . '# '
						. $@,
					error => 1,
				);
				$self->{ixchel}{errors_count}++;
			} else {
				$self->status_add( status => '-----[ '
						. $instance
						. ' ]-------------------------------------' . "\n"
						. $filled_in
						. "\n" );
			}
		} ## end foreach my $instance (@instances)
	} else {
		if ( defined( $self->{opts}{i} ) ) {
			$self->status_add( status => '-i may not be used in single instance mode, .suricata.multi_instance=0' );
		}

		my $filled_in;
		eval {
			my $config = $self->{config}{suricata}{config};
			$filled_in = '%YAML 1.1' . "\n" . Dump($config);

			if ( $self->{opts}{w} ) {
				write_file( $config_base . '/include.yaml', $filled_in );
			}
		};
		if ($@) {
			$self->status_add( status => '# ' . $@, error => 1, );
		} else {
			$self->status_add( status => $filled_in );
		}
	} ## end else [ if ( $self->{config}{suricata}{multi_instance...})]

	return undef;
} ## end sub action_extra

sub short {
	return 'Generates the instance specific include for a suricata instance.';
}

sub opts_data {
	return 'i=s
w
d=s
';
}

1;
