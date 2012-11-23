use 5.014;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Quote::Code',
    AUTHOR              => q{Lukas Mai <l.mai@web.de>},
    VERSION_FROM        => 'lib/Quote/Code.pm',
    ABSTRACT_FROM       => 'lib/Quote/Code.pm',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.56',
    },
    LICENSE => 'perl',
    PL_FILES            => {},
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'warnings' => 0,
        'strict' => 0,
    	'XSLoader' => 0,
    	'Carp' => 0,
    },
    MIN_PERL_VERSION => '5.14.0',
    META_MERGE => {
        resources => {
            repository => {
                url => 'git://github.com/mauke/Quote-Code.git',
                web => 'https://github.com/mauke/Quote-Code',
                type => 'git',
            },
        },
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Quote-Code-*' },
);
