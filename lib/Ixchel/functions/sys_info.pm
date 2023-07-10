package Ixchel::functions::sys_info;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use Exporter 'import';
our @EXPORT = qw(sys_info);
use Rex -feature => [qw/1.4/];
use Rex::Hardware;

# prevents Rex from printing out rex is exiting after the script ends
$::QUIET = 2;

=head1 NAME

Ixchel::functions::sys_info - Fetches system info via Rex::Hardware.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use Ixchel::functions::sys_info;
    use Data::Dumper;

    print Dumper(sys_info);

=head1 Functions

=head2 sys_info

Calls L<Rex::Hardware>->get and returns the data as a hash ref.

=cut

sub sys_info {
	my %all=Rex::Hardware->get(qw/ All /);

	return \%all;
}

1;
