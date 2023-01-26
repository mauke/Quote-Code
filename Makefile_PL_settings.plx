# vi:set ft=perl:
use strict;
use warnings;

return {
    NAME   => 'Quote::Code',
    AUTHOR => q{Lukas Mai <l.mai@web.de>},

    MIN_PERL_VERSION => '5.14.0',
    CONFIGURE_REQUIRES => {},
    BUILD_REQUIRES => {},
    TEST_REQUIRES => {
        'charnames'  => 0,
        'if'         => 0,
        'strict'     => 0,
        'utf8'       => 0,
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Carp'     => 0,
        'XSLoader' => 0,
        'warnings' => 0,
    },

    REPOSITORY => [ github => 'mauke' ],
};
