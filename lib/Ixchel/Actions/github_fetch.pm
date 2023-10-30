package Ixchel::Actions::github_fetch;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use LWP::Simple;
use JSON;

=head1 NAME

Ixchel::Actions::github_fetch :: Fetch an release asset from a github repo.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use Data::Dumper;

    my $results=$ixchel->action(action=>'suricata_outputs', opts=>{np=>1, w=>1, });

    print Dumper($results);

=head1 FLAGS


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

	$self->{results} = {
		errors      => [],
		status_text => '',
		ok          => 0,
	};

	# if neither are defined error and return
	if ( !defined( $self->{opts}{r} ) ) {
		my $error = '-r not specified';
		warn($error);
		push( @{ $self->{results}{errors} }, $error );
		return $self->{results};
	}

	# if neither are defined error and return
	if ( !defined( $self->{opts}{o} ) ) {
		my $error = '-o not specified';
		warn($error);
		push( @{ $self->{results}{errors} }, $error );
		return $self->{results};
	}

	# if neither are defined error and return
	if ( !defined( $self->{opts}{f} ) ) {
		my $error = '-fs not specified';
		warn($error);
		push( @{ $self->{results}{errors} }, $error );
		return $self->{results};
	}



	# set the proxy proxy info if we have any in the config
	if ( defined( $self->{config}{proxy} ) ) {
		if ( defined( $self->{config}{proxy}{ftp} ) && $self->{config}{proxy}{ftp} ne '' ) {
			$ENV{FTP_PROXY} = $self->{config}{proxy}{ftp};
			$ENV{ftp_proxy} = $self->{config}{proxy}{ftp};
		}
		if ( defined( $self->{config}{proxy}{http} ) && $self->{config}{proxy}{http} ne '' ) {
			$ENV{HTTP_PROXY} = $self->{config}{proxy}{http};
			$ENV{http_proxy} = $self->{config}{proxy}{http};
		}
		if ( defined( $self->{config}{proxy}{https} ) && $self->{config}{proxy}{https} ne '' ) {
			$ENV{HTTPS_PROXY} = $self->{config}{proxy}{https};
			$ENV{https_proxy} = $self->{config}{proxy}{https};
		}
	} ## end if ( defined( $self->{config}{proxy} ) )

	my $url     = 'https://api.github.com/repos/' . $self->{opts}{o} . '/' . $self->{opts}{r} . '/releases';
	my $content = get($url);
	if ( !defined($content) ) {
		die( 'Fetching "' . $url . '" failed' );
	}

	my $json;
	eval { $json = decode_json($content); };
	if ($@) {
		die( 'Decoding JSON from "' . $url . '" failed... ' . $@ );
	}

	if ( ref($json) ne 'ARRAY' ) {
		die 'The path . in the fetched JSON from "' . $url . '"is not of ref type ARRAY';
	}

	foreach my $release ( @{$json} ) {
		my $use_release = 1;

		if ( ref($release) ne 'HASH' ) {
			$use_release = 0;
		}

		# if it is a draft, check if fetching of drafts is allowed
		if (   $use_release
			&& defined( $release->{draft} )
			&& $release->{draft} =~ /$[Tt][Rr][Uu][Ee]^/
			&& !$self->{opts}{d} )
		{
			$use_release = 0;
		}

		# if it is a prerelease, check if fetching of prerelease is allowed
		if (   $use_release
			&& defined( $release->{prerelease} )
			&& $release->{prerelease} =~ /$[Tt][Rr][Uu][Ee]^/
			&& !$self->{opts}{p} )
		{
			$use_release = 0;
		}

		if ($use_release) {
			foreach my $asset ( @{ $release->{assets} } ) {
				my $fetch_it = 0;
				if ( defined( $asset->{name} ) && $asset->{name} eq $self->{opts}{f} ) {
					$fetch_it = 1;
				}

				if ($fetch_it) {
					my $content = get( $asset->{browser_download_url} );
					if ( !defined($content) ) {
						die( 'Fetching "' . $asset->{browser_download_url} . '" failed' );
					}

					if ( $self->{opts}{P} ) {
						print $content;
						exit;
					}

					my $write_to = $asset->{name};
					$write_to =~ s/\//_/g;
					if ( defined( $self->{opts}{w} ) ) {
						$write_to = $self->{opts}{w};
					}

					eval {
						write_file(
							$write_to,
							{
								append     => $self->{opts}{A},
								atomic     => $self->{opts}{B},
								perms      => $self->{opts}{U}
							},
							$content
						);
					};
					if ($@) {
						die(      'Failed to write "'
								. $asset->{browser_download_url}
								. '" out to "'
								. $write_to . '"... '
								. $@ );
					}

					exit;
				} ## end if ($fetch_it)
			} ## end foreach my $asset ( @{ $release->{assets} } )
		} ## end if ($use_release)
	} ## end foreach my $release ( @{$json} )

} ## end sub action

sub help {
	return 'Fetch an release asset from a github repo for the latest release.

-r <repo>    The repo to fetch it from in org/repo format.

-f <asset>   The name of the asset to fetch for a release.

-p           Pre-releases are okay.

-d           Draft-releases are okay.

-P           Print it out instead of writing it out.

-w <output>  Where to write the output to.

-N           Do not overwrite if the file already exists.

-A           Write the file out in append mode.

-B           Write the file in a atomicly if possible.

-U           umask to use. If undef will default to what ever sysopen is.
';
} ## end sub help

sub short {
	return 'Fetch an release asset from a github repo.';
}

sub opts_data {
	return '
r=s
f=s
p
d
o=s
w=s
P
N
A
B
U
';
} ## end sub opts_data

1;
