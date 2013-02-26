use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Webdriver',
    license             => 'perl',
    dist_author         => q{Robert Messer},
    dist_version_from   => 'lib/Webdriver.pm',
    release_status      => 'testing',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Moose'          => 2.0604,
        'JSON'           => 2.53,
        'LWP::UserAgent' => 6.04,
        'Try::Tiny'      => 0.11,
    },
    add_to_cleanup     => [ 'Webdriver-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
