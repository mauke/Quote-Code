package Quote::Code;

use v5.14.0;

use warnings;

use Carp qw(croak);

use XSLoader;
BEGIN {
	our $VERSION = '0.03';
	XSLoader::load;
}

my %export = (
	qc => HINTK_QC,
	qc_to => HINTK_QC_TO,
);

sub import {
	my $class = shift;

	my @todo;
	for my $item (@_) {
		push @todo, $export{$item} || croak qq{"$item" is not exported by the $class module};
	}
	for my $item (@todo ? @todo : values %export) {
		$^H{$item} = 1;
	}
}

sub unimport {
	my $class = shift;
	my @todo;
	for my $item (@_) {
		push @todo, $export{$item} || croak qq{"$item" is not exported by the $class module};
	}
	for my $item (@todo ? @todo : values %export) {
		delete $^H{$item};
	}
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
 
 my $heredoc = qc_to <<'EOT';
 .trigger:hover .message:after {
   content: "The #{get_adjective()} brown fox #{get_verb()} over the lazy dog.";
 }
 EOT
 print $heredoc;

=head1 DESCRIPTION

This module provides the new keywords C<qc> and C<qc_to>.

=head2 qc

C<qc> is a quoting operator like L<q or qq|perlop/Quote-and-Quote-like-Operators>.
It works like C<q> in that it doesn't interpolate C<$foo> or C<@foo>, but like
C<qq> in that it recognizes backslash escapes such as C<\n>, C<\xff>,
C<\N{EURO SIGN}>, etc.

What it adds is the ability to embed arbitrary expressions in braces
(C<{...}>). This is both more readable and more efficient than the old C<"foo
@{[bar]}"> L<trick|perlfaq4/How-do-I-expand-function-calls-in-a-string->. All
embedded code runs in scalar context.

If you need a literal C<{> in a C<qc> string, you can escape it with a backslash
(C<\{>) or interpolate code that yields a left brace (C<{'{'}>).

=head2 qc_to

For longer strings you can use C<qc_to>, which provides a
L<heredoc-like|perlop/EOF> syntax. The main difference between C<qc> and
C<qc_to> is that C<qc_to> uses the Ruby-like C<#{ ... }> to interpolate code
(not C<{ ... }>). This is because C<{ }> are more common in longer texts and
escaping them gets annoying.

C<qc_to> has two syntactic forms:

 qc_to <<'FOO'
 ...
 FOO

and

 qc_to <<"FOO"
 ...
 FOO

After C<qc_to> there must always be a C<E<lt>E<lt>> (this is to give syntax
highlighters a chance to get things right). After that, there are two
possibilities:

=over

=item *

An identifier in single quotes. Backslash isn't treated specially in the
string. To embed a literal C<#{>, you need to write C<#{'#{'}>.

=item *

An identifier in double quotes. Backslash escapes are recognized. You can
escape C<#{> by writing either C<\#{> or C<#\{>.

=back

Variables aren't interpolated in either case.

=head1 AUTHOR

Lukas Mai, C<< <l.mai at web.de> >>

=head1 COPYRIGHT & LICENSE

Copyright 2012 Lukas Mai.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
