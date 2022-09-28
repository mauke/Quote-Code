use warnings FATAL => 'all';
use strict;

use Test::More tests => 9;

use Quote::Code ();

is eval('qc]1]'), undef;
like $@, qr/syntax error/;

{
    use Quote::Code;
    is qc]1], '1';
}

is eval('qc]1]'), undef;
like $@, qr/syntax error/;

use Quote::Code;
is qc]1], '1';

{
    no Quote::Code;
    is eval('qc]1]'), undef;
    like $@, qr/syntax error/;
}

is qc]1], '1';
