package Ixchel::functions::perl_module_via_pkg;

use 5.006;
use strict;
use warnings;
use Exporter 'import';
our @EXPORT = qw(perl_module_via_pkg);
use Rex -feature => [qw/1.4/];
use Rex::Commands::Gather;
use Rex::Commands::Pkg;

# prevents Rex from printing out rex is exiting after the script ends
$::QUIET = 2;

=head1 NAME

Ixchel::functions::perl_module_via_pkg

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use Ixchel::functions::perl_module_via_pkg;
    use Data::Dumper;

    my $returned=perl_module_via_pkg(module=>'Monitoring::Sneck');

    print Dumper($returned);

Supported OS families are...

    Alt Linux
    Arch Linux
    Debian Linux
    FreeBSD
    Mageia Linux
    NetBSD
    OpenBSD
    Redhat Linux
    Suse Linux

=head1 Functions

=head2 perl_module_via_pkg

The function that makes it so.

    - module :: The name of name of the module to install.

=cut

sub perl_module_via_pkg {
	my (%opts) = @_;

	if ( !defined( $opts{module} ) ) {
		die('Nothing specified for a module to install');
	}

	my $pkg = $opts{module};
	my @pkg_alts;

	if (is_freebsd) {
		$pkg =~ s/^/p5\-/;
		$pkg =~ s/\:\:/\-/g;
	} elsif (is_debian) {
		$pkg =~ s/\:\:/\-/g;
		$pkg = 'lib' . lc($pkg) . '-perl';
	} elsif (is_redhat) {
		$pkg =~ s/\:\:/\-/g;
		$pkg = 'perl-' . $pkg;
	} elsif (is_arch) {
		$pkg =~ s/\:\:/\-/g;
		$pkg = 'perl-' . $pkg;
	} elsif (is_suse) {
		$pkg =~ s/\:\:/\-/g;
		$pkg = 'perl-' . $pkg;
	} elsif (is_alt) {
		$pkg =~ s/\:\:/\-/g;
		$pkg = 'perl-' . $pkg;
	} elsif (is_netbsd) {
		$pkg =~ s/^/p5\-/;
		$pkg =~ s/\:\:/\-/g;
	} elsif (is_openbsd) {
		$pkg =~ s/^/p5\-/;
		$pkg =~ s/\:\:/\-/g;
	}elsif (is_mageia) {
		$pkg =~ s/\:\:/\-/g;
		$pkg = 'perl-' . $pkg;
	}

	pkg( $pkg, ensure => 'present]' );

	return 1;
} ## end sub perl_module_via_pkg

1;
