package Test::Most;

use warnings;
use strict;

# XXX don't use 'base' as it can override our signal handlers
use Test::Builder::Module;
our ( @ISA, @EXPORT );

use Test::More;
use Test::Differences;
use Test::Exception;
use Test::Deep;

use Test::Builder;
my $OK_FUNC;
BEGIN {
    $OK_FUNC = \&Test::Builder::ok;
}

=head1 NAME

Test::Most - Most commonly needed test functions and features.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

B<WARNING>:  This is alpha code.  It seems to work well, but use with caution.

This module provides you with the most commonly used testing functions and
gives you a bit more fine-grained control over your test suite.

    use Test::Most tests => 4, 'die';

    ok 1, 'Normal calls to ok() should succeed';
    is 2, 2, '... as should all passing tests';
    eq_or_diff [3], [4], '... but failing tests should die';
    ok 4, '... will never get to here';

As you can see, the C<eq_or_diff> test will fail.  Because 'die' is in the
import list, the test program will halt at that point.

=head1 EXPORT

All functions from the following modules will automatically be exported into
your namespace:

=over 4

=item * C<Test::More>

=item * C<Test::Exception>

=item * C<Test::Differences>

=item * C<Test::Deep> 

=back

Functions which are I<optionally> exported from any of those modules must be
referred to by their fully-qualified name:

  Test::Deep::render_stack( $var, $stack );

=head1 FUNCTIONS

Four other functions are also automatically exported:

=head2 C<die_on_fail>

 die_on_fail;
 is_deeply $foo, bar, '... we die if this fails';

This function, if called, will cause the test program to die if any tests fail
after it.

=head2 C<bail_on_fail>

 bail_on_fail;
 is_deeply $foo, bar, '... we bail out if this fails';

This function, if called, will cause the test suite to BAIL_OUT() if any
tests fail after it.

=head2 C<restore_fail>

 die_on_fail;
 is_deeply $foo, bar, '... we die if this fails';

 restore_fail;
 cmp_bag(\@got, \@bag, '... we will not die if this fails';

This restores the original test failure behavior, so subsequent tests will no
longer die or BAIL_OUT().

=head2 C<explain>

Like C<diag()>, but only outputs the message if C<$ENV{TEST_VERBOSE}> is set.
This is typically set by using the C<-v> switch with C<prove>.

Requires C<Test::Harness> 3.07 or greater.

=head1 DIE OR BAIL ON FAIL

Sometimes you want your test suite to die or BAIL_OUT() if a test fails.  In
order to provide maximum flexibility, there are three ways to accomplish each
of these.

=head2 Import list

 use Test::Most 'die', tests => 7;
 use Test::Most qw< no_plan bail >;

If C<die> or C<bail> is anywhere in the import list, the test program/suite
will C<die> or C<BAIL_OUT()> as appropriate the first time a test fails.
Calling C<restore_fail> anywhere in the test program will restore the original
behavior (not dieing or bailing out).

=head2 Functions

 use Test::Most 'no_plan;
 ok $bar, 'The test suite will continue if this passes';

 die_on_fail;
 is_deeply $foo, bar, '... we die if this fails';

 restore_fail;
 ok $baz, 'The test suite will continue if this passes';

The C<die_on_fail> and C<bail_on_fail> functions will automatically set the
desired behavior at runtime.

=head2 Environment variables

 DIE_ON_FAIL=1 prove t/
 BAIL_ON_FAIL=1 prove t/

If the C<DIE_ON_FAIL> or C<BAIL_ON_FAIL> environment variables are true, any
tests which use C<Test::Most> will die or call BAIL_OUT on test failure.

=head1 RATIONALE

People want more control over their test suites.  Sometimes when you see
hundreds of tests failing and whizzing by, you want the test suite to simply
halt on the first failure.  This module gives you that control.

As for the reasons for the four test modules chosen, I ran code over a local
copy of the CPAN to find the most commonly used testing modules.  Here were
the top ten (out of 287):

 Test::More              44461
 Test                     8937
 Test::Exception          1379
 Test::Simple              731
 Test::Base                316
 Test::Builder::Tester     193
 Test::NoWarnings          174
 Test::Differences         146
 Test::MockObject          139
 Test::Deep                127

The four modules chosen seemed the best fit for what C<Test::Most> is trying
to do.

=cut

BEGIN {
    @ISA    = qw(Test::Builder::Module);
    @EXPORT = (
        @Test::More::EXPORT, 
        @Test::Differences::EXPORT,
        @Test::Exception::EXPORT,
        @Test::Differences::EXPORT,
        qw<
            explain
            restore_fail
            die_on_fail
            bail_on_fail
        >
    );

    if ( Test::Differences->VERSION <= 0.47 ) {

        # XXX There's a bug in Test::Differences 0.47 which attempts to render
        # an AoH in a cleaner 'table' format.
        # http://rt.cpan.org/Public/Bug/Display.html?id=29732
        no warnings 'redefine';
        *Test::Differences::_isnt_HASH_of_scalars = sub {
            return 1 if ref ne "HASH";
            return scalar grep ref, values %$_;
        };
    }
}

sub import {
    my $bail_set = 0;
    if ( $ENV{BAIL_ON_FAIL} ) {
        $bail_set = 1;
        bail_on_fail();
    }
    if ( !$bail_set and $ENV{DIE_ON_FAIL} ) {
        die_on_fail();
    }
    for my $i ( 0 .. $#_ ) {
        if ( 'bail' eq $_[$i] ) {
            splice @_, $i, 1;
            bail_on_fail();
            $bail_set = 1;
            last;
        }
    }
    for my $i ( 0 .. $#_ ) {
        if ( !$bail_set and ( 'die' eq $_[$i] ) ) {
            splice @_, $i, 1;
            die_on_fail();
            last;
        }
    }

    # 'magic' goto to avoid updating the callstack
    goto &Test::Builder::Module::import;
}

sub explain {
    return unless $ENV{TEST_VERBOSE};
    Test::More::diag(@_);
}

sub die_on_fail {
    _set_failure_handler( sub { die "Test failed.  Stopping test.\n" } );
}

sub bail_on_fail {
    _set_failure_handler(
        sub { Test::More::BAIL_OUT("Test failed.  BAIL OUT!.\n") } );
}

sub restore_fail {
    no warnings 'redefine';
    *Test::Builder::ok = $OK_FUNC;
}

sub _set_failure_handler {
    my $action = shift;
    no warnings 'redefine';
    Test::Builder->new->{XXX_failure_action} = $action; # for DESTROY
    *Test::Builder::ok = sub {
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        my $builder = $_[0];
        if ( $builder->{XXX_test_failed} ) {
            $builder->{XXX_test_failed} = 0;
            $action->();
        }
        $builder->{XXX_test_failed} = 0;
        my $result = $OK_FUNC->(@_);
        $builder->{XXX_test_failed} = !( $builder->summary )[-1];
        return $result;
    };
}

{
    no warnings 'redefine';

    # we need this because if the failure is on the final test, we won't have
    # a subsequent test triggering the behavior.
    sub Test::Builder::DESTROY {
        my $builder = $_[0];
        if ( $builder->{XXX_test_failed} ) {
            $builder->{XXX_failure_action}->();
        }
    }
}
1;

=head1 AUTHOR

Curtis Poe, C<< <ovid at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-extended at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Most>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Most

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Most>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Most>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Most>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Most>

=back

=head1 TODO

=head2 Deferred plans

Sometimes you don't know the number of tests you will run when you use
C<Test::More>.  The C<plan()> function allows you to delay specifying the
plan, but you must still call it before the tests are run.  This is an error:

 use Test::More;

 my $tests = 0;
 foreach my $test (
     my $count = run($test); # assumes tests are being run
     $tests += $count;
 }
 plan($tests);

The way around this is typically to use 'no_plan' and when the tests are done,
C<Test::Builder> merely sets the plan to the number of tests run.  We'd like
for the programmer to specify this number instead of letting C<Test::Builder>
do it.  However, C<Test::Builder> internals are a bit difficult to work with,
so we're delaying this feature.

=head2 Cleaner skip()

 if ( $some_condition ) {
     skip $message, $num_tests;
 }
 else {
     # run those tests
 }

That would be cleaner and I might add it if enough people want it.

=head1 CAVEATS

Because of how Perl handles arguments, and because diagnostics are not really
part of the Test Anything Protocol, what actually happens internally is that
we note that a test has failed and we die or bail out as soon as the I<next>
test is called (but before it runs).  This means that its arguments are
automatically evaulated before we can take action:

 use Test::Most qw<no_plan die>;

 ok $foo, 'Die if this fails';
 ok factorial(123456), '... but wait a loooong time before you die';

=head1 ACKNOWLEDGEMENTS

Many thanks to C<perl-qa> for arguing about this so much that I just went
ahead and did it :)

Thanks to Aristotle for suggesting a better way to die or bailout.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Curtis Poe, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;
