# NAME

Quote::Code - quoted strings with arbitrary code interpolation

# SYNOPSIS

```
use Quote::Code;
print qc"2 + 2 = {2 + 2}";  # "2 + 2 is 4"
my $msg = qc{The {$obj->name()} is {$obj->state()}.};

my $heredoc = qc_to <<'EOT';
.trigger:hover .message:after {
  content: "The #{get_adjective()} brown fox #{get_verb()} over the lazy dog.";
}
EOT
print $heredoc;

my $name = "A B C";
my @words = qcw(
  foo
  bar\ baz
  {2 + 2}
  ({$name})
);
# @words = ("foo", "bar baz", "4", "(A B C)");
```

# DESCRIPTION

This module provides the new keywords `qc`, `qc_to` and `qcw`.

## qc

`qc` is a quoting operator like [q or qq](https://metacpan.org/pod/perlop#Quote-and-Quote-like-Operators).
It works like `q` in that it doesn't interpolate `$foo` or `@foo`, but like
`qq` in that it recognizes backslash escapes such as `\n`, `\xff`,
`\N{EURO SIGN}`, etc.

What it adds is the ability to embed arbitrary expressions in braces
(`{...}`). This is both more readable and more efficient than the old `"foo
@{[bar]}"` [trick](https://metacpan.org/pod/perlfaq4#How-do-I-expand-function-calls-in-a-string). All
embedded code runs in scalar context.

If you need a literal `{` in a `qc` string, you can escape it with a backslash
(`\{`) or interpolate code that yields a left brace (`{'{'}`).

## qc\_to

For longer strings you can use `qc_to`, which provides a
[heredoc-like](https://metacpan.org/pod/perlop#EOF) syntax. The main difference between `qc` and
`qc_to` is that `qc_to` uses the Ruby-like `#{ ... }` to interpolate code
(not `{ ... }`). This is because `{ }` are more common in longer texts and
escaping them gets annoying.

`qc_to` has two syntactic forms:

```
qc_to <<'FOO'
...
FOO
```

and

```
qc_to <<"FOO"
...
FOO
```

After `qc_to` there must always be a `<<` (this is to give syntax
highlighters a chance to get things right). After that, there are two
possibilities:

- An identifier in single quotes. Backslash isn't treated specially in the
string. To embed a literal `#{`, you need to write `#{'#{'}`.
- An identifier in double quotes. Backslash escapes are recognized. You can
escape `#{` by writing either `\#{` or `#\{`.

Variables aren't interpolated in either case.

## qcw

`qcw` is analogous to [`qw`](https://metacpan.org/pod/perlop#qw-STRING). It quotes a list of
strings with code interpolation (`{ ... }`) like `qc`.

Differences between `qcw` and `qw`:

- `{ ... }` sequences are interpreted as expressions to be interpolated in the
current word. The result of `{ ... }` is not scanned for spaces or split.
- Backslash escape sequences such as `\n`, `\xff`, `\cA` etc. are recognized.
- Spaces can be escaped with a backslash to prevent word splitting:
`qcw(a b\ c d)` is equivalent to `('a', 'b c', 'd')`.

## Backslash escape sequences

`qc`, `qcw`, and `qc_to <<"..."` support the following backslash
escape sequences:

```
\\         backslash
\a         alarm/bell       (BEL)
\b         backspace        (BS)
\e         escape           (ESC)
\f         form feed        (FF)
\n         newline          (LF)
\r         carriage return  (CR)
\t         tab              (HT)

\cX        control-X
           X can be any character from the set
             ?, @, a-z, A-Z, [, \, ], ^, _

\o{FOO}    the character whose octal code is FOO
\FOO       the character whose octal code is FOO
           (where FOO is at most 3 octal digits long)

\x{FOO}    the character whose hexadecimal code is FOO
\xFOO      the character whose hexadecimal code is FOO
           (where FOO is at most 2 hexadecimal digits long)
\x         a NUL byte (if \x is not followed by '{' or a hex digit)
           (don't use this, it might go away in a future release)

\N{U+FOO}  the character whose hexadecimal code is FOO
\N{FOO}    the character whose Unicode name is FOO
           (as determined by the charnames pragma)
```

Any other backslashed character (including delimiters) is taken literally. In
particular this means e.g. both `qc!a\!b!` and `qc(a\!b)` represent the
three-character string `"a!b"`.

The following are explicitly **not supported**: `\Q`, `\L`, `\l`, `\U`,
`\u`, `\F`, `\E`.

Starting with perl v5.16, if you specify a named Unicode character with
`\N{...}` and [`charnames`](https://metacpan.org/pod/charnames) hasn't been loaded yet, it is
automatically loaded as if by `use charnames ':full', ':short';`.

# AUTHOR

Lukas Mai, `<l.mai at web.de>`

# COPYRIGHT & LICENSE

Copyright 2012-2013 Lukas Mai.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
