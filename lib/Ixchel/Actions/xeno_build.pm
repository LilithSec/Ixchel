package Ixchel::Actions::xeno_build;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use String::ShellQuote;

=head1 NAME

Ixchel::Actions::xeno_build :: 

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

=head1 OPTIONS

=head2 build_hash

A build hash containing the options to use for installing and building.

=head1 BUILD HASH

=head2 pkgs

    - .pkgs.present :: A hash of arrays. The keys are the OS seen by
            L<Rex::Commands::Gather> and values in the array will be ensured to be
            present via L<Rex::Commands::Pkg>.
        - Default :: []

    - .pkgs.latest :: A hash of arrays. The keys are the OS seen by
            L<Rex::Commands::Gather> and values in the array will be ensured to be
            latest via L<Rex::Commands::Pkg>.
        - Default :: []

    - .pkgs.absent :: A hash of arrays. The keys are the OS seen by
            L<Rex::Commands::Gather> and values in the array will be ensured to be
            absent via L<Rex::Commands::Pkg>.

    - .pkgs.update_package_db :: A Perl boolean for if the package DB should be updated
            if .pkgs.latest is being used.
        - Default :: 1

    - .pkgs.update_package_db_force :: A Perl boolean for if the package DB should be
            updated even there is nothing undef to be installed.
        - Default :: 0

So if you want to install apache24 and exa on FreeBSD and jq on Debian, it would be like below.

    {
        pkgs => {
            latest => {
                FreeBSD => [ 'apache24', 'exa' ],
                Debian => [ 'jq' ],
            },
        },
    }

=head2 cpanm

    - .cpanm.modules :: A array of modules to to install via cpanm.
        - Default :: []

    - .cpanm.use_proxy :: A Perl boolean for if it use use proxy values in the
        config under .proxy for ones defined or not blank.

    - .cpanm.reinstall :: A Perl boolean for if it should --reinstall should be passed.
        - Default :: 0

    - .cpanm.notest :: A Perl boolean for if it should --notest should be passed.
        - Default :: 0

    - .cpanm.force :: A Perl boolean for if it should --force should be passed.
        - Default :: 0

    - .cpanm.install :: Ensures that cpanm is installed, which will also ensure that Perl is installed.
            If undef or 0, then cpanm won't be installed and will be assumed to already be present. If
            set to true, it will be installed if anything is specificed in .cpanm.modules.
        - Default :: 1

    - .cpanm.install_force :: Install cpanm even if .cpanm.modules does not contain any modules.
        - Default :: 0

    - cpanm.pkgs :: A list of modules to install via packages if possible.
        - Default :: []

    - cpanm.pkgs_always_try :: A Perl boolean for if the array for .cpanm.modules should be appended to
            .cpanm.pkgs.
        - Default :: 0

    - cpanm.pkgs_require :: A list of modules to install via packages. Will fail if any of these fail.
        - Default :: []

For the packages, if you want to make sure the package DB is up to date, you will want to set
.pkgs.update_package_db_force to "1".

=head2 exec

    - .exec.commands :: A array of hash to use for running commands.
        - Default :: []

    - .exec.command :: A command to run.
        - Default :: undef

   - .exec.exits :: A array of acceptable exit values. May start with >, >=, <, or <= .
       - Default :: [0]

   - .exec.template :: If the command in question should be treated as a TT template.
       - Default :: [0]

   - .exec.template_failure_ok :: A Perl boolean if it is okay for templating to fail.
       - Default :: 0

Either .exec.commands or .exec.command must be used. If .exec.commands is used, each value in
the array is a hash using the same keys, minus .commands, as .exec. So if .exec.commands[0].exits
is undef, then .exec.exits is used as the default.

If .exec.commands[0] or .exec.command is undef, then nothing will be ran and even if .exec exists.
Similarly if .command for a hash under .exec.commands, then nothing will be ran for that hash,
it will be skipped.

=head2 python

Install python stuff.

    - .python.install :: A Perl boolean for if it should install python. By default only installs
            python and pip if .python.pip[0] or .python.pkgs[0] is defined.
        - Default :: 1

    - .python.version :: Version to use for installing python. 3 is used here by default as that will
            generally work as it is likely to be symlinked to which ever version of python3 and that
            extension pip as well.
        - Default :: 3

    - .python.pip :: A array items to install via pip.
        - Default :: []

    - .python.pkgs :: A array items to install via packages.
        - Default :: []

=head2 order

An array of the order it should process the steps in. The default is as below.

    pkgs
    cpanm
    python
    exec

So lets say you have a .exec in the hash, but .order does not contain 'exec' any place in
the array, then whatever is in .exec will not be processed.

If you want to run exec twice with different values, you can create .exec0 and .exec with
the desired stuff and set the order like below.

    exec0
    pkgs
    exec

Fire .exec0, then pkgs, and then .exec will be ran. The type is determined via removing
the end from it via the regexp s/[0-9]*$//. So .cpanm123 would be ran as cpanm type.

Unknown types will result in an error.

=head1 RESULT HASH REF

    .errors :: A array of errors encountered.
    .status_text :: A string description of what was done and teh results.
    .ok :: 

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

	my $results = {
		errors      => [],
		status_text => '',
		ok          => 0,
	};

	return $results;
} ## end sub action

sub help {
	return 'Builds/installs stuff based on a passed hash ref.

Not usable directly. Use xeno action.

See perldoc Ixchel::Actions::xeno_build for more details.
';
}

sub short {
	return 'Builds/installs stuff based on a passed hash ref. Not usable directly. Use xeno action.';
}

sub opts_data {
	return '
';
}

1;
