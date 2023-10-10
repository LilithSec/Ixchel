package Ixchel::functions::python_module_via_pkg;

use 5.006;
use strict;
use warnings;
use Exporter 'import';
our @EXPORT = qw(python_module_via_pkg);
use Rex -feature => [qw/1.4/];
use Rex::Commands::Gather;
use Rex::Commands::Pkg;

# prevents Rex from printing out rex is exiting after the script ends
$::QUIET = 2;

=head1 NAME

Ixchel::functions::python_module_via_pkg - Tries to install a module for python3 via the package manager.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use Ixchel::functions::python_module_via_pkg;
    use Data::Dumper;

    eval{ python_module_via_pkg(module=>'Pillow') };
    if ($@) {
        print 'Failed to install Pillow...'.$@."\n";
    }

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
    Void Linux

=head1 Functions

=head2 python_module_via_pkg

Tries to install a python3 module via packages.

    eval{ python_module_via_pkg(module=>'django') };
    if ($@) {
        print 'Failed to install python module ...'.$@;
    }

=cut

sub python_module_via_pkg {
	my (%opts) = @_;

	if (is_freebsd) {
		my $which_python3 = `which python3 2> /dev/null`;
		chomp($which_python3);
		if ( $which_python3 !~ /python3$/ ) {
			die( 'Unable to locate python3 with PATH=' . $ENV{PATH} );
		}
		my $python_link = readlink($which_python3);
		$python_link =~ s/.*python3\.//;
		my $pkg = 'py3' . $python_link . '-' . $opts{module};
		eval { pkg( $pkg, ensure => "present" ); };
		if ($@) {
			eval { pkg( lc($pkg), ensure => "present" ); };
			if ($@) {
				die( 'Neither ' . $pkg . ' or ' . lc($pkg) . ' could be installed' );
			}
		}
	} elsif (is_debian) {
		pkg( 'python3-' . lc( $opts{module} ), ensure => 'present' );
	} elsif (is_redhat) {
		pkg( 'python3-' . lc( $opts{module} ), ensure => 'present' );
	} elsif (is_arch) {
		pkg( 'python3-' . lc( $opts{module} ), ensure => 'present' );
	} elsif (is_suse) {
		pkg( 'python311-' . lc( $opts{module} ), ensure => 'present' );
	} elsif (is_alt) {
		pkg( 'python3-module-' . lc( $opts{module} ), ensure => 'present' );
	} elsif (is_netbsd) {
		my $pkg = 'py311-' . lc( $opts{module} );
	} elsif (is_openbsd) {
		my $pkg = 'py311-' . lc( $opts{module} );
	} elsif (is_mageia) {
		pkg( 'python3-' . lc( $opts{module} ), ensure => 'present' );
	} elsif (is_void) {
		pkg( 'python3-' . lc( $opts{module} ), ensure => 'present' );
	}

	return 1;
} ## end sub python_module_via_pkg

1;
