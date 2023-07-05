package Ixchel::Actions::list_actions;

use 5.006;
use strict;
use warnings;
use Module::List qw(list_modules);

=head1 NAME

Ixchel::Actions::list_actions :: Lists the various actions.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

Prints out a list of available actions.

=cut

sub new {
	my ( $empty, %opts ) = @_;

	my $self = { config => undef, };
	bless $self;

	if ( defined( $opts{config} ) ) {
		$self->{config} = $opts{config};
	}

	return $self;
} ## end sub new

sub action{
	my $actions=list_modules("Ixchel::Actions::", { list_modules => 1});

	foreach my $action (keys(%{ $actions })) {
		my $action_name=$action;
		$action_name=~s/^Ixchel\:\:Actions\:\://;

		my $short;
		my $to_eval='use '.$action.'; $short='.$action.'->short;';
		eval($to_eval);
		if(!defined($short)){
			$short='';
		}
		print $action_name. ' : '.$short."\n";
	}
};

sub help {
	return 'Lists the available actions.';
}

sub short {
	return 'Lists the available actions.';
}

1;

