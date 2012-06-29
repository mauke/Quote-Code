package Quote::Code;

use v5.14.0;

use warnings;
use strict;

use Carp qw(croak);

use XSLoader;
BEGIN {
	our $VERSION = '0.01';
	XSLoader::load;
}

sub import {
	my $class = shift;
	croak qq{"$_" is not exported by the $class module} for @_;

	$^H{+HINTK_QC} = 1;
}

sub unimport {
	my $class = shift;
	croak qq{"$_" is not exported by the $class module} for @_;

	delete $^H{+HINTK_QC};
}

'ok'

__END__

=encoding UTF-8

=head1 NAME

Quote::Code - quoted strings with arbitrary code interpolation

=head1 SYNOPSIS

 use Quote::Code;
 print qc"2 + 2 = {2 + 2}";  # "2 + 2 is 4"
 my $msg = qc{The {$obj->name()} is {$obj->state()}.};

=head1 DESCRIPTION

This module provides the new keyword C<qc>.
C<qc> is a quoting operator like L<q or qq|perlop/Quote-and-Quote-like-Operators>.
It works like C<q> in that it doesn't interpolate C<$foo> or C<@foo>, but like
C<qq> in that it recognizes backslash escapes such as C<\n>, C<\xff>, etc.

What it adds is the ability to embed arbitrary expressions in braces
(C<{...}>). This is both more readable and more efficient than the old C<"foo
@{[bar]}"> L<trick|perlfaq4/How-do-I-expand-function-calls-in-a-string->.

If you need a literal C<{> in a C<qc> string, you can escape it with a backslash
(C<\{>) or interpolate code that yields a left brace (C<{'{'}>).

=head1 BUGS

It doesn't understand C<\N{...}>.

=head1 AUTHOR

Lukas Mai, C<< <l.mai at web.de> >>

=head1 COPYRIGHT & LICENSE

Copyright 2012 Lukas Mai.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
