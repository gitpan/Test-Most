use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Test::Most',
    license           => 'perl',
    dist_author       => 'Curtis Poe <ovid@cpan.org>',
    dist_version_from => 'lib/Test/Most.pm',
    build_requires    => {
        'Test::More'        => 0,
        'Test::Exception'   => 0,
        'Test::Differences' => 0,
        'Test::Deep'        => 0,
        'Test::Harness'     => 3.07,
        perl                => 5.6,
    },
    add_to_cleanup     => ['Test-Most-*'],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
