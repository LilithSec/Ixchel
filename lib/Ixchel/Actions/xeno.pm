package Ixchel::Actions::xeno;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use JSON::Path;
use YAML::XS qw(Load);
use Ixchel::functions::file_get;

=head1 NAME

Ixchel::Actions::xeno :: Invokes xeno_build with the specified hash.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';

=head1 SYNOPSIS

    use Data::Dumper;

    my $results=$ixchel->action(action=>'suricata_outputs', opts=>{np=>1, w=>1, });

    print Dumper($results);

=head1 FLAGS

=head2 --xb <file>

Read this YAML file to use for with xeno_build.

=head2 -r <repo item>

Uses the specified value to fetch
'https://raw.githubusercontent.com/LilithSec/xeno_build/main/$repo_item.yaml'.

=head2 -u <url>

Install use the file from URL.

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

	$self->{results} = {
		errors      => [],
		status_text => '',
		ok          => 0,
	};

	# if neither are defined error and return
	if ( !defined( $self->{opts}{xb} ) && !defined( $self->{opts}{r} ) && !defined( $self->{opts}{u} ) ) {
		my $error = 'Neither --xb, -r, or -u specified';
		warn($error);
		push( @{ $self->{results}{errors} }, $error );
		return $self->{results};
	}

	# if neither are defined error and return
	my $args_test = 0;
	if ( defined( $self->{opts}{xb} ) ) {
		$args_test++;
	}
	if ( defined( $self->{opts}{r} ) ) {
		$args_test++;
	}
	if ( defined( $self->{opts}{u} ) ) {
		$args_test++;
	}
	if ( $args_test >= 2 ) {
		my $error = 'Neither --xb, -r, and/or  -u specified together... can only use one';
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

	my $xeno_build;
	my $xeno_build_raw;
	if ( defined( $self->{opts}{xb} ) ) {
		my $xeno_build_file;
		if ( -f $self->{opts}{xb} ) {
			$xeno_build_file = $self->{opts}{xb};
		} elsif ( -f $self->{share_dir} . '/' . $self->{opts}{xb} ) {
			$xeno_build_file = $self->{share_dir} . '/' . $self->{opts}{xb};
		} elsif ( -f $self->{share_dir} . '/' . $self->{opts}{xb} . '.yaml' ) {
			$xeno_build_file = $self->{share_dir} . '/' . $self->{opts}{xb} . '.yaml';
		}
		eval { $xeno_build_raw = read_file($xeno_build_file) || die( 'Failed to read "' . $xeno_build_file . '"' ); };
		if ($@) {
			my $error = 'xeno_build errored: ' . $@;
			warn($error);
			push( @{ $self->{results}{errors} }, $error );
			return $self->{results};
		}
	} elsif ( defined( $self->{opts}{r} ) ) {
		$self->{opts}{r} =~ s/\.yaml$//;
		my $url = 'https://raw.githubusercontent.com/LilithSec/xeno_build/main/' . $self->{opts}{r} . '.yaml';
		eval { $xeno_build_raw = file_get( url => $url ); };
		if ($@) {
			my $error = 'xeno_build errored: ' . $@;
			warn($error);
			push( @{ $self->{results}{errors} }, $error );
			return $self->{results};
		}
	}elsif (defined($self->{opts}{u})) {
		eval { $xeno_build_raw = file_get( url => $self->{opts}{u} ); };
		if ($@) {
			my $error = 'xeno_build errored: ' . $@;
			warn($error);
			push( @{ $self->{results}{errors} }, $error );
			return $self->{results};
		}
	} ## end elsif ( defined( $self->{opts}{r} ) )

	# parse the xeno_build yaml
	eval { $xeno_build = Load($xeno_build_raw); };
	if ($@) {
		my $error = 'xeno_build errored: ' . $@;
		warn($error);
		push( @{ $self->{results}{errors} }, $error );
		return $self->{results};
	}

	return $self->{ixchel}->action( action => 'xeno_build', opts => { xeno_build => $xeno_build } );
} ## end sub action

sub help {
	return 'Invoke xeno_build on the specified hash.

--xb <file>       Read this YAML file in and use it as the hash for xeno_build.

-r <repo item>    Xeno Build Repo item to fetch and build.

-u <url>          Fetch the specified URL and use the YAML as the Xeno Build hash.
';
} ## end sub help

sub short {
	return 'Invoke xeno_build on the specified hash.';
}

sub opts_data {
	return '
xb=s
r=s
u=s
';
}

1;
