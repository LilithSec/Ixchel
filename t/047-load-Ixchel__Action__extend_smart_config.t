#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Ixchel::Actions::extend_smart_config' ) || print "Bail out!\n";
}

diag( "Testing Ixchel $Ixchel::Actions::extend_smart_config::VERSION, Perl $], $^X" );
