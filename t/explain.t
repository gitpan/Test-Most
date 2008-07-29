#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib', 't/lib';
use Test::Most tests => 2;

no warnings 'redefine';

my @EXPLAIN;
local *Test::More::diag = sub { @EXPLAIN = @_ };
local $ENV{TEST_VERBOSE} = 1;
explain 'foo';
eq_or_diff \@EXPLAIN, ['foo'], 'Basic explain should work just fine';

use Data::Dumper;
local $Data::Dumper::Indent   = 1;
local $Data::Dumper::Sortkeys = 1;
local $Data::Dumper::Terse    = 1;

my $aref = [qw/this that/];
explain 'hi', $aref, 'bye';

is_deeply \@EXPLAIN, [ 'hi', Dumper($aref), 'bye' ],
    '... and also allow you to dump references';
