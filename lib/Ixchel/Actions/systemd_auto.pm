package Ixchel::Actions::systemd_auto;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use String::ShellQuote;

=head1 NAME

Ixchel::Actions::systemd_auto :: Generate systemd service files using the systemd_service template.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';

=head1 SYNOPSIS

    use Data::Dumper;

    my $results=$ixchel->action(action=>'systemd_auto', opts=>{np=>1, w=>1, reload=>1, enable=>1, start=>1, });

    print Dumper($results);

=head1 DESCRIPTION

The template used is systemd_service.

The generated services will be named ixchelAuto-$service.

Should be noted that the this can return what the generated templates will contain via checking the
output on non-systemd systems attempting to use -w or the like outside of systemd systems will result
in it failing. Printing the results on other systems is meant primarily for testing/debugging purposes.

=head1 FLAGS

=head2 --np

Do not print the status of it.

=head2 -w

Write the generated services to service files.

=head2 -s <service>

A auto service to operate on.

=head2 --reload

Run systemctl daemon-reload.

=head2 --enable

Enable the generated services.

=head2 --start

Start the generated services.

=head2 --restart

Restart the generated services.

=head1 RESULT HASH REF

    .errors :: A array of errors encountered.
    .status_text :: A string description of what was done and teh results.
    .is_systemd :: Set to 1 if the system in question is systemd.
    .started :: Set to 0 if starting anything failed.
    .restarted :: Set to 0 if restarting anything failed.
    .enabled :: Set to 0 if enabling anything failed.
    .reloaded :: Set to 0 if reloading systemd failed.
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
		is_systemd  => 0,
		written     => 1,
		started     => 1,
		restarted   => 1,
		enabled     => 1,
		reloaded    => 1,
		ok          => 0,
	};

	# not dying here is intentional for testing purposes
	if ( $^O eq 'linux' && ( -f '/usr/bin/systemctl' || -f '/bin/systemctl' ) ) {
		$results->{is_systemd} = 1;
	}

	my @units;

	# if we have a single service specified via -s, use that
	# otherwise act upon them all
	my @services;
	if ( defined( $self->{opts}{s} ) ) {
		if ( !defined( $self->{config}{systemd}{auto}{ $self->{opts}{s} } ) ) {
			die( '"' . $self->{opts}{s} . '" does not exist as a defined systemd auto service' );
		}
		@services = ( $self->{opts}{s} );
	} else {
		@services = keys( %{ $self->{config}{systemd}{auto} } );
	}

	# if we don't have any services, nothing we can do
	if ( !defined( $services[0] ) ) {
		die('There are no configured auto services under .systemd.auto');
	}

	# attempt to configure the various services
	foreach my $service (@services) {
		my $service_vars = $self->{config}{systemd}{auto}{$service};

		my $unit = 'ixchelAuto-' . $service . '.service';

		if ( !defined( $service_vars->{description} ) ) {
			$service_vars->{description} = 'Ixchel autogenerated service ' . $service;
		}

		my $filled_in;
		eval {
			$filled_in = $self->{ixchel}->action(
				action => 'template',
				vars   => $service_vars,
				opts   => {
					np => 1,
					t  => 'systemd_service',
				},
			);

			if ( $self->{opts}{w} ) {
				write_file( '/lib/systemd/system/' . $unit, $filled_in );
			}
		};
		if ($@) {
			$results->{written} = 0;
			my $error = $@;
			push( @{ $results->{errors} }, $error );
			if ( !defined($filled_in) ) {
				$filled_in = '';
			}
			$results->{status_text}
				= $results->{status_text}
				. '-----[ ERROR '
				. $unit
				. ' ]-------------------------------------' . "\n" . '# '
				. $error
				. $filled_in . "\n";
			$self->{ixchel}{errors_count}++;
		} else {
			push( @units, $unit );
			$results->{status_text}
				= $results->{status_text}
				. '-----[ '
				. $unit
				. ' ]-------------------------------------' . "\n"
				. $filled_in . "\n";
		}
	} ## end foreach my $service (@services)

	# if asked to reload systemd, attempt to do so
	if ( $self->{opts}{reload} ) {
		my $output = `systemctl daemon-reload 2>&1`;
		if ( !defined($output) ) {
			$output = '';
		}
		if ( $? != 0 ) {
			$results->{reloaded} = 0;
			$results->{status_text}
				= $results->{status_text}
				. '-----[ Reload Error ]-------------------------------------' . "\n"
				. "# systemctl daemon-reload 2>&1 exited non zero...\n"
				. $output . "\n";
			$self->{ixchel}{errors_count}++;
		} else {
			$results->{status_text}
				= $results->{status_text}
				. '-----[ Reload ]-------------------------------------' . "\n"
				. "# systemctl daemon-reload 2>&1 exit zero...\n"
				. $output . "\n";
		}
	} ## end if ( $self->{opts}{reload} )

	# if asked to enable the services, attempt to do so
	if ( $self->{opts}{enable} ) {
		foreach my $unit (@units) {
			my $escaped_unit = shell_quote($unit);
			my $command      = 'systemctl enable ' . $escaped_unit . ' 2>&1';
			my $output       = `$command`;
			if ( !defined($output) ) {
				$output = '';
			}
			if ( $? != 0 ) {
				$results->{enabled} = 0;
				$results->{status_text}
					= $results->{status_text}
					. '-----[ Enable '
					. $unit
					. ' Error ]-------------------------------------' . "\n" . '# '
					. $command
					. " exited non zero...\n"
					. $output . "\n";
				$self->{ixchel}{errors_count}++;
			} else {
				$results->{status_text}
					= $results->{status_text}
					. '-----[ Enable '
					. $unit
					. ' ]-------------------------------------' . "\n" . '# '
					. $command
					. " exited zero...\n"
					. $output . "\n";
			} ## end else [ if ( $? != 0 ) ]
		} ## end foreach my $unit (@units)
	} ## end if ( $self->{opts}{enable} )

	# if asked to start the services, attempt to do so
	if ( $self->{opts}{start} ) {
		foreach my $unit (@units) {
			my $escaped_unit = shell_quote($unit);
			my $command      = 'systemctl start ' . $escaped_unit . ' 2>&1';
			my $output       = `$command`;
			if ( !defined($output) ) {
				$output = '';
			}
			if ( $? != 0 ) {
				$results->{started} = 0;
				$results->{status_text}
					= $results->{status_text}
					. '-----[ Start '
					. $unit
					. ' Error ]-------------------------------------' . "\n" . '# '
					. $command
					. " exited non zero...\n"
					. $output . "\n";
				$self->{ixchel}{errors_count}++;
			} else {
				$results->{status_text}
					= $results->{status_text}
					. '-----[ Start '
					. $unit
					. ' ]-------------------------------------' . "\n" . '# '
					. $command
					. " exited zero...\n"
					. $output . "\n";
			} ## end else [ if ( $? != 0 ) ]
		} ## end foreach my $unit (@units)
	} ## end if ( $self->{opts}{start} )

	# if asked to restart the services, attempt to do so
	if ( $self->{opts}{restart} ) {
		foreach my $unit (@units) {
			my $escaped_unit = shell_quote($unit);
			my $command      = 'systemctl restart ' . $escaped_unit . ' 2>&1';
			my $output       = `$command`;
			if ( !defined($output) ) {
				$output = '';
			}
			if ( $? != 0 ) {
				$results->{restarted} = 0;
				$results->{status_text}
					= $results->{status_text}
					. '-----[ Retart '
					. $unit
					. ' Error ]-------------------------------------' . "\n" . '# '
					. $command
					. " exited non zero...\n"
					. $output . "\n";
				$self->{ixchel}{errors_count}++;
			} else {
				$results->{status_text}
					= $results->{status_text}
					. '-----[ Retart '
					. $unit
					. ' ]-------------------------------------' . "\n" . '# '
					. $command
					. " exited zero...\n"
					. $output . "\n";
			} ## end else [ if ( $? != 0 ) ]
		} ## end foreach my $unit (@units)
	} ## end if ( $self->{opts}{restart} )

	if ( !$self->{opts}{np} ) {
		print $results->{status_text};
	}

	# only set ok to true if all the all the following are also true
	# otherwise some error was encountered
	if (   $results->{is_systemd}
		&& $results->{written}
		&& $results->{started}
		&& $results->{restarted}
		&& $results->{enabled}
		&& $results->{reloaded} )
	{
		$results->{ok} = 1;
	}

	return $results;
} ## end sub action

sub short {
	return 'Handles generation of service file as specified under .systemd.auto .';
}

sub opts_data {
	return 's=s
np
w
reload
start
enable
restart
';
} ## end sub opts_data

1;
