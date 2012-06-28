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
