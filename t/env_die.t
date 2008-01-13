#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib', 't/lib';
BEGIN { $ENV{DIE_ON_FAIL} = 1 }
use Test::Most tests => 7;
use OurTester qw($DIED dies);

ok 1, 'Normal calls to ok() should succeed';
is 2, 2, '... as should all passing tests';
dies { eq_or_diff( [3], [4] ) } '... but failing tests should die';
ok 4, 'Subsequent calls to ok() should be fine';
ok !$DIED, '... and not die';
