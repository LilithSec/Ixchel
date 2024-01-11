package Ixchel::Actions::xeno;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use JSON::Path;
use YAML::XS qw(Load);
use Ixchel::functions::file_get;

=head1 NAME

Ixchel::Actions::xeno - Invokes xeno_build with the specified hash.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';

=head1 SYNOPSIS

    use Data::Dumper;

    my $results=$ixchel->action(action=>'xeno', opts=>{r=>'librenms/extends/smart' });

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
