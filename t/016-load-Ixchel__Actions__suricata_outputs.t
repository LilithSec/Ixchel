#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Ixchel::Actions::suricata_outputs' ) || print "Bail out!\n";
}

diag( "Testing Ixchel $Ixchel::Actions::suricata_outputs::VERSION, Perl $], $^X" );