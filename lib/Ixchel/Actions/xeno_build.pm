package Ixchel::Actions::xeno_build;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use String::ShellQuote;
use Rex::Commands::Gather;
use File::Temp qw/ tempdir /;
use Rex::Commands::Pkg;
use LWP::Simple;

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

=head2 options

    - .options.build_dir :: Build dir to use. If not defined, .config.xeno_options.build_dir
            is used. If that is undef, '/tmp/' is used.
        - Default :: undef

    . options.tmpdir :: The path for a automatically created tmpdir under .options.build_dir.
            This will be removed one once xeno_build has finished running. This allows for easy cleanup
            when using templating with fetch and exec when using templating. This is created via
            L<File::Temp>->newdir.

    - .options.$var :: Additional variable to define.

=head2 fetch

    - .fetch.items.$name.url :: URL to fetch.

    - .fetch.items.$name.dst :: Where to write it to.

    - .fetch.template :: If the url and dst should be treated as a template.
        - Default :: 0

.fetch.items is a hash for the purpose of allowing it to easily be referenced later in exec. If .fetch.items.$name.url or
.fetch.items.$name.dst is templated, the template output is saved as that variable so it can easily be used in exec.

Variables for template are as below.

    - config :: Ixchel config.

    - options :: Stuff defined via .options.

    - os :: OS as per L<Rex::Commands::Gather>.

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

    . exec.dir :: Directory to use. If undef, this will use .options.build_dir .
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

Variables for template are as below.

    - config :: Ixchel config.

    - options :: Stuff defined via .options.

    - os :: OS as per L<Rex::Commands::Gather>.

    - .fetched :: .fetch.items if it exists.

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

    fetch
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

First .exec0, then pkgs, and then .exec will be ran. The type is determined via removing
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
		config        => {},
		vars          => {},
		arggv         => [],
		opts          => {},
		os            => get_operating_system,
		template_vars => {
			shell_quote => \&shell_quote,
		},
	};
	bless $self;
	# in two places as .template_vars will get passed to TT
	$self->{template_vars}{config} = $self->{config};
	# having it in two places for the purposes of simplicity
	$self->{template_vars}{os} = $self->{os};

	# set is_systemd template var
	if ( $^O eq 'linux' && ( -f '/usr/bin/systemctl' || -f '/bin/systemctl' ) ) {
		$self->{template_vars}{is_systemd}=1;
	}else {
		$self->{template_vars}{is_systemd}=0;
	}

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

	# if this is not set, no reason to continue
	if ( !defined( $self->{opts}{xeno_build} ) ) {
		push( @{ $results->{errors} }, '.opts.xeno_build was not set' );
		return $results;
	}

	# define the order if not specified
	if ( !defined( $self->{opts}{xeno_build}{order} ) ) {
		$self->{opts}{xeno_build}{order} = [ 'fetch', 'pkgs', 'cpanm', 'python', 'exec', ];
	}

	# set default options if needed
	if ( !defined( $self->{opts}{xeno_build}{options} ) ) {
		$self->{opts}{xeno_build}{options} = {};
	}
	# if the build_dir is not set, set it
	if ( !defined( $self->{opts}{xeno_build}{options}{build_dir} ) ) {
		# if .xeno_build.build_dir is set in the config, use it
		if ( defined( $self->{config}{xeno_build}{build_dir} ) ) {
			$self->{opts}{xeno_build}{options}{build_dir} = $self->{config}{xeno_build}{build_dir};
		} else {
			# if that is undef, use /tmp/
			$self->{opts}{xeno_build}{options}{build_dir} = '/tmp/';
		}
	}
	# create the tmpdir under the build dir
	$self->{opts}{xeno_build}{options}{tmpdir}
		= File::Temp->newdir( DIR => $self->{opts}{xeno_build}{options}{build_dir} );
	# now that options are setup, save it as a usable template variable
	$self->{template_vars}{options} = $self->{opts}{xeno_build}{options};

	# figure out the types we are going to use
	my @types;
	foreach my $type ( @{ $self->{opts}{xeno_build}{order} } ) {
		# make sure it is known
		if (   $type !~ /^fetch[0-9]*$/
			&& $type !~ /^pkgs[0-9]*$/
			&& $type !~ /^cpanm[0-9]*$/
			&& $type !~ /^python[0-9]*$/
			&& $type !~ /^exec[0-9]*$/ )
		{
			push( @{ $results->{errors} }, '"' . $type . '" is not of a known type' );
			return $results;
		}
		# if it exists, add it to the @types array
		if ( defined $self->{opts}{xeno_build}{$type} ) {
			push( @types, $type );
		}
	} ## end foreach my $type ( @{ $self->{opts}{xeno_build}...})

	foreach my $type (@types) {
		if ( $type =~ /^fetch[0-9]*$/ ) {
			# get the names of the items to fetch
			my @fetch_names;
			if ( !defined( $self->{opts}{xeno_build}{$type}{items} ) ) {
				@fetch_names = keys( %{ $self->{opts}{xeno_build}{$type}{items} } );
			}
			# figure out if we should template it or not
			my $template_it=0;
			if (defined( $self->{opts}{xeno_build}{$type}{template} )) {
				$template_it=$self->{opts}{xeno_build}{$type}{template};
			}
			foreach my $fetch_name (@fetch_names) {
				if (   defined( $self->{opts}{xeno_build}{$type}{items}{url} )
					&& defined( $self->{opts}{xeno_build}{$type}{items}{dst} ) )
				{
					my $url = $self->{opts}{xeno_build}{$type}{items}{url};
					my $dst = $self->{opts}{xeno_build}{$type}{items}{dst};
					if ($template_it) {
						# template the url
						my $output='';
						$self->{t}->process( \$url, $self->{template_vars}, \$output );
						$url=$output;
						$self->{opts}{xeno_build}{$type}{items}{url}=$url;
						# template the dst
						$output='';
						$self->{t}->process( \$dst, $self->{template_vars}, \$output );
						$dst=$output;
						$self->{opts}{xeno_build}{$type}{items}{dst}=$dst;
					}
					my $return_code=getstore($url, $dst);
				}
			}
		} elsif ( $type =~ /^pkgs[0-9]*$/ ) {
			# set .pkgs.update_package_db to 1 if it is undef
			if ( !defined( $self->{opts}{xeno_build}{$type}{update_package_db} ) ) {
				$self->{opts}{xeno_build}{$type}{update_package_db} = 1;
			}

			# update the db if requested to always do it
			# only
			my $updated;
			if ( defined( $self->{opts}{xeno_build}{$type}{update_package_db_force} )
				&& $self->{opts}{xeno_build}{$type}{update_package_db_force} )
			{
				$updated = 1;
				update_package_db;
			}
			# handle .pkgs.latest
			if ( defined( $self->{opts}{xeno_build}{$type}{latest}{ $self->{os} } ) ) {
				# handle latest
				if ( defined( $self->{opts}{xeno_build}{$type}{latest}{ $self->{os} }[0] ) ) {
					if ( !$updated && $self->{opts}{xeno_build}{$type}{update_package_db} ) {
						update_package_db;
					}
					foreach my $pkg ( @{ $self->{opts}{xeno_build}{$type}{latest}{ $self->{os} } } ) {
						pkg( $pkg, ensure => 'latest' );
					}
				}
				# handle present
				if ( defined( $self->{opts}{xeno_build}{$type}{present}{ $self->{os} }[0] ) ) {
					foreach my $pkg ( @{ $self->{opts}{xeno_build}{$type}{present}{ $self->{os} } } ) {
						pkg( $pkg, ensure => 'present' );
					}
				}
				# handle absent
				if ( defined( $self->{opts}{xeno_build}{$type}{absent}{ $self->{os} }[0] ) ) {
					foreach my $pkg ( @{ $self->{opts}{xeno_build}{$type}{absent}{ $self->{os} } } ) {
						pkg( $pkg, ensure => 'absent' );
					}
				}
			} ## end if ( defined( $self->{opts}{xeno_build}{$type...}))
		} elsif ( $type =~ /^cpanm[0-9]*$/ ) {
			
		} elsif ( $type =~ /^python[0-9]*$/ ) {
		} elsif ( $type =~ /^exec[0-9]*$/ ) {
		}
	} ## end foreach my $type (@types)

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
