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

=head1 Functions

=head2 perl_module_via_pkg

The function that makes it so.

    - module :: The name of name of the module to install.

=cut

sub  perl_module_via_pkg{
	my ( %opts ) = @_;


	if (!defined($opts{module})) {
		die('Nothing specified for a module to install');
	}

	my $os=get_operating_system;
	my $pkg=$opts{module};
	my @pkg_alts;

	if ($os eq 'FreeBSD') {
		$pkg=~s/^/p5\-/;
		$pkg=~s/\:\:/\-/g;
	}elsif ($os eq 'Debian' || $os eq 'Ubuntu') {
		$pkg=~s/\:\:/\-/g;
		$pkg='lib'.lc($pkg).'-perl';
	}elsif ($os eq 'Redhat') {
		$pkg=~s/\:\:/\-/g;
		$pkg='perl-'.$pkg;
		push(@pkg_alts, lc($pkg));
	}

	eval{
		pkg($pkg, ensure=>'present]');
		return 1;
	};
	# pkg will die if installing it fails
	if ($@) {
		# try possible alts if we have them
		if (defined( $pkg_alts[0] )) {
			foreach my $alt_pkg (@pkg_alts) {
				eval{
					pkg($alt_pkg, ensure=>'present');
					return 1;
				};
			}
		}
	}

	# return false as we failed to install it
	return 0;
}

1;
