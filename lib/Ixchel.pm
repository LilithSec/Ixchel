package Ixchel;

use 5.006;
use strict;
use warnings;
use Template;

=head1 NAME

Ixchel - 

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 METHODS

=head2 new

=cut

sub new {
	my ( $empty, %opts ) = @_;

	my $self = {
		config => undef,
		t      => Template->new(
			{
				EVAL_PERL   => 1,
				INTERPOLATE => 1,
				POST_CHOMP  => 1,
			}
		),
	};
	bless $self;

	if (defined($opts{config})) {
		$self->{config}=$opts{config};
	}

	return $self;
} ## end sub new

=head2 help

Fetches help.

=cut

sub help{
	my $self=$_[0];
	my $action=$_[1];

	if (!defined($action)) {
		die('No action to fetch help for defined');
	}

	# make sure the action only contains sane characters for when we eval
	if ($action=~/[^a-zA-Z0-9\_]/) {
		die('"'.$action.'" matched /[^a-zA-Z0-9\_]/, which is not a valid action name');
	}

	my $help;
	my $to_eval='use Ixchel::Actions::'.$action.'; $help=Ixchel::Actions::'.$action.'->help;';
	eval( $to_eval );
	if ($@) {
		die('Help eval failed... '.$@);
	}

	return $help;
}

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ixchel at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Ixchel>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Ixchel


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Ixchel>

=item * Search CPAN

L<https://metacpan.org/release/Ixchel>

=item * Github

L<https://github.com/LilithSec/Ixchel>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007


=cut

1;    # End of Ixchel
