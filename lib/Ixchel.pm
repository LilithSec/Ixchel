package Ixchel;

use 5.006;
use strict;
use warnings;
use Template;
use File::ShareDir ":ALL";
use Getopt::Long;
use Ixchel::DefaultConfig;
use Hash::Merge;

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
		t => Template->new(
			{
				EVAL_PERL    => 1,
				INTERPOLATE  => 0,
				POST_CHOMP   => 1,
				INCLUDE_PATH => dist_dir("Ixchel") . '/templates/',
			}
		),
		share_dir     => dist_dir("Ixchel"),
		options_array => undef,
	};
	bless $self;

	my %default_config = %{ Ixchel::DefaultConfig->get };
	if ( defined( $opts{config} ) ) {
		my $merger    = Hash::Merge->new('RIGHT_PRECEDENT');
		my %tmp_config=%{ $opts{config} };
		my %tmp_shash = %{ $merger->merge( \%default_config, \%tmp_config ) };

		$self->{config} = \%tmp_shash;
	} else {
		$self->{config} = \%default_config;
	}

	return $self;
} ## end sub new

=head2 action

The action to perform.

=cut

sub action {
	my $self   = $_[0];
	my $action = $_[1];

	if ( !defined($action) ) {
		die('No action to fetch help for defined');
	}

	# split it appart and remove comments and blank lines
	my $opts_data;
	my %parsed_options;
	my $to_eval = 'use Ixchel::Actions::' . $action . '; $opts_data=Ixchel::Actions::' . $action . '->opts_data;';
	eval($to_eval);
	if ( defined($opts_data) ) {
		my @options = split( /\n/, $opts_data );
		@options = grep( !/^#/, @options );
		@options = grep( !/^$/, @options );
		GetOptions( \%parsed_options, @options );
	}

	my $action_return;
	my $action_obj;
	$to_eval
		= 'use Ixchel::Actions::'
		. $action
		. '; $action_obj=Ixchel::Actions::'
		. $action
		. '->new(config=>$self->{config}, t=>$self->{t}, share_dir=>$self->{share_dir}, opts=>\%parsed_options, argv=>\@ARGV);'
		. '$action_return=$action_obj->action;';
	eval($to_eval);
	if ($@) {
		die( 'Action eval failed... ' . $@ );
	}

	return $action_return;
} ## end sub action

=head2 help

Fetches help.

=cut

sub help {
	my $self   = $_[0];
	my $action = $_[1];

	if ( !defined($action) ) {
		die('No action to run defined');
	}

	# make sure the action only contains sane characters for when we eval
	if ( $action =~ /[^a-zA-Z0-9\_]/ ) {
		die( '"' . $action . '" matched /[^a-zA-Z0-9\_]/, which is not a valid action name' );
	}

	my $help;
	my $to_eval = 'use Ixchel::Actions::' . $action . '; $help=Ixchel::Actions::' . $action . '->help;';
	eval($to_eval);
	if ($@) {
		die( 'Help eval failed... ' . $@ );
	}

	return $help;
} ## end sub help

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
