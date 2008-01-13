#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Test::Most' )
      or BAIL_OUT("Cannot load Test::Most");
}

diag( "Testing Test::Most $Test::Most::VERSION, Perl $], $^X" );
