#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Ixchel::functions::perl_module_via_pkg' ) || print "Bail out!\n";
}

diag( "Testing Ixchel $Ixchel::functions::perl_module_via_pkg::VERSION, Perl $], $^X" );
