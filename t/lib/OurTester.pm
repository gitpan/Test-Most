package OurTester;

use strict;
use warnings;
use Carp 'croak';

BEGIN {
    unless ( $INC{'Test/Most.pm'} ) {
        croak ("Test::Most must be loaded before ".__PACKAGE__);
    }
}

use Exporter;
our @ISA = 'Exporter';
our ( $DIED, $BAILED );
our @EXPORT_OK = qw($DIED $BAILED dies bails);

use Test::Builder;
my $BUILDER = Test::Builder->new;

sub _set_die {
    _set_test_failure_handler( sub { $DIED = 1 } );
}

sub _set_bail {
    _set_test_failure_handler( sub { $BAILED = 1 } );
}

#
# This is like the normal override for Test::More::ok, but we need to check
# the actual value of of the test status, regardless of whether or not it's a
# TODO test.
#

sub _set_test_failure_handler {
    my $action = shift;
    my $ok     = \&Test::Builder::ok;
    no warnings 'redefine';
    *Test::Builder::ok = sub {
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        my $builder = $_[0];
        if ( $builder->{XXX_test_failed} ) {
            $builder->{XXX_test_failed} = 0;
            $action->();
        }
        $builder->{XXX_test_failed} = 0;
        my $result = $ok->(@_);

        # Not a fun interface
        $builder->{XXX_test_failed} = !( $builder->details )[-1]->{actual_ok};
        return $result;
    };
}

sub dies(&;$) {
    my ( $sub, $message ) = @_;
    _set_die();
    package main;
  TODO: {
        local $main::TODO = 'Planned failure';

        # ignore the error messages as they will be confusing.
        $BUILDER->no_diag(1);
        $sub->();
        $BUILDER->no_diag(0);
    }
    Test::More::ok 1, 'arguments are evaluated *before* ok()';
    Test::More::ok $DIED, $message;
    $DIED = 0;
}

sub bails(&;$) {
    my ( $sub, $message ) = @_;
    _set_bail();
    package main;
  TODO: {
        local $main::TODO = 'Planned failure';
        $BUILDER->no_diag(1);
        $sub->();
        $BUILDER->no_diag(0);
    }
    Test::More::ok 1, 'arguments are evaluated *before* ok()';
    Test::More::ok $BAILED, $message;
    $BAILED = 0;
}

1;
