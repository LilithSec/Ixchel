package Ixchel::Actions::systemd_auto;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use String::ShellQuote;

=head1 NAME

Ixchel::Actions::systemd_auto :: 

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

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
	};

	my @units;

	my @services;
	if ( defined( $self->{opts}{s} ) ) {
		if ( !defined( $self->{config}{systemd}{auto}{ $self->{opts}{s} } ) ) {
			die( '"' . $self->{opts}{s} . '" does not exist as a defined systemd auto service' );
		}
		@services = ( $self->{opts}{s} );
	} else {
		@services = keys( %{ $self->{config}{systemd}{auto} } );
	}

	if ( !defined( $services[0] ) ) {
		die('There are no configured auto services under .systemd.auto');
	}

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

	if ( $self->{opts}{reload} ) {
		my $output = `systemctl daemon-reload 2>&1`;
		if ( !defined($output) ) {
			$output = '';
		}
		if ( $? != 0 ) {
			$results->{status_text}
				= $results->{status_text}
				. '-----[ Reload Error ]-------------------------------------' . "\n"
				. "# systemctl daemon-reload 2>&1 exited non zero...\n"
				. $output . "\n";
		} else {
			$results->{status_text}
				= $results->{status_text}
				. '-----[ Reload ]-------------------------------------' . "\n"
				. "# systemctl daemon-reload 2>&1 exit zero...\n"
				. $output . "\n";
		}
	} ## end if ( $self->{opts}{reload} )

	if ( $self->{opts}{enable} ) {
		foreach my $unit (@units) {
			my $escaped_unit = shell_quote($unit);
			my $command      = 'systemctl enable ' . $escaped_unit . ' 2>&1';
			my $output       = `$command`;
			if ( !defined($output) ) {
				$output = '';
			}
			if ( $? != 0 ) {
				$results->{status_text}
					= $results->{status_text}
					. '-----[ Enable '
					. $unit
					. ' Error ]-------------------------------------' . "\n" . '# '
					. $command
					. " exited non zero...\n"
					. $output . "\n";
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

	if ( $self->{opts}{start} ) {
		foreach my $unit (@units) {
			my $escaped_unit = shell_quote($unit);
			my $command      = 'systemctl start ' . $escaped_unit . ' 2>&1';
			my $output       = `$command`;
			if ( !defined($output) ) {
				$output = '';
			}
			if ( $? != 0 ) {
				$results->{status_text}
					= $results->{status_text}
					. '-----[ Start '
					. $unit
					. ' Error ]-------------------------------------' . "\n" . '# '
					. $command
					. " exited non zero...\n"
					. $output . "\n";
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

	if ( $self->{opts}{restart} ) {
		foreach my $unit (@units) {
			my $escaped_unit = shell_quote($unit);
			my $command      = 'systemctl restart ' . $escaped_unit . ' 2>&1';
			my $output       = `$command`;
			if ( !defined($output) ) {
				$output = '';
			}
			if ( $? != 0 ) {
				$results->{status_text}
					= $results->{status_text}
					. '-----[ Retart '
					. $unit
					. ' Error ]-------------------------------------' . "\n" . '# '
					. $command
					. " exited non zero...\n"
					. $output . "\n";
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

	return $results;
} ## end sub action

sub help {
	return 'Handles generation of service file as specified under .systemd.auto .

--np          Do not print the status of it.

-w            Write the generated services to service files.

-s <service>  A auto service to operate on.

--reload      Run systemctl daemon-reload.

--enable      Enable the generated services.

--start       Start the generated services.

--restart     Restart the generated services.
';
}

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
