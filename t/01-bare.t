use warnings;
use strict;

use Test::More tests => 5;

use Quote::Code;

is "foo {2 + 2}", 'foo {2 + 2}';
is length("{0}"), 3;
is qc"foo {2 + 2}", "foo 4";
is length(qc'{0}'), 1;
$_ = "abc";
is qc($_ {substr $_, 1}\t(\n)), "\$_ bc\t(\n)";
