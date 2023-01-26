use strict;
use warnings;

use ExtUtils::MakeMaker 6.48 ();
use Config ();

sub MY::postamble {
    my ($self, %args) = @_;
    $args{text} || ''
}

sub {
    my ($opt) = @_;

    $opt->{depend}{Makefile} .= ' ' . __FILE__;

    $opt->{test}{TESTS} .= ' ' . find_tests_recursively_in 'xt';

    $opt->{postamble}{text} .= <<'__EOT__';
export RELEASE_TESTING=1
export HARNESS_OPTIONS=c
__EOT__

    if (exists $opt->{PREREQ_PM}{XSLoader}) {
        my $preload_libasan;

        my @ccflags;
        my @otherldflags;

        if (-e '/dev/null') {
            {
                my $libasan_path = `\Q$Config::Config{cc}\E -print-file-name=libasan.so` || 'libasan.so';
                chomp $libasan_path;
                local $ENV{LD_PRELOAD} = $libasan_path . ' ' . ($ENV{LD_PRELOAD} || '');
                my $out = `"$^X" -e 0 2>&1`;
                if ($? == 0 && $out eq '') {
                    $preload_libasan = $libasan_path;
                } else {
                    warn qq{LD_PRELOAD="$ENV{LD_PRELOAD}" "$^X" failed:\n${out}Skipping ...\n};
                }
            }

            my $good_cc_flag = sub {
                system("echo 'int main(void) { return 0; }' | \Q$Config::Config{cc}\E @_ -xc - -o /dev/null") == 0
            };
            for my $flag ($preload_libasan ? '-fsanitize=address' : (), '-fsanitize=undefined') {
                if (!$good_cc_flag->($flag)) {
                    warn "!! Your C compiler ($Config::Config{cc}) doesn't seem to support '$flag'. Skipping ...\n";
                    next;
                }
                push @ccflags,      $flag;
                push @otherldflags, $flag;
            }
        }

        $opt->{postamble}{text} .= <<"__EOT__";
CCFLAGS      += @ccflags -DDEVEL
OTHERLDFLAGS += @otherldflags
__EOT__

        if ($preload_libasan) {
            my $extra_options = '';
            if ($^V lt v5.22.0) {
                # Hack. ASan reports a memory leak on 5.14 .. 5.20, but I don't
                # want integration tests to fail for now.
                $extra_options = "LSAN_OPTIONS='exitcode=0'";
            }
            $opt->{postamble}{text} .= <<"__EOT__";
FULLPERLRUN := $extra_options LD_PRELOAD="$preload_libasan \$\$LD_PRELOAD" \$(FULLPERLRUN)
__EOT__
        }
    }

    my $perl_pattern = '*';
    if ($opt->{MIN_PERL_VERSION}) {
        my ($ver, $subver) = $opt->{MIN_PERL_VERSION} =~ /\A5\.(\d{1,3})\.(\d{1,3})\z/
            or die "Can't parse MIN_PERL_VERSION '$opt->{MIN_PERL_VERSION}'";

        my $genverpat = sub {
            my ($num, $width) = @_;
            $num = sprintf '%0*d', $width, $num
                if $width;

            my $i_last = length($num) - 1;

            my @pat;
            for my $i (0 .. $i_last) {
                my $pre = substr $num, 0, $i;
                $pre =~ s/\A0+//;
                my $x = substr $num, $i, 1;
                if ($i < $i_last) {
                    next if $x eq '9';
                    $x++;
                }
                $x = "[$x-9]"
                    unless $x eq '9';
                my $post = '[0-9]' x ($i_last - $i);
                push @pat, $pre . $x . $post;
            }

            '{' . join(',', reverse @pat) . '}'
        };

        my $pat = $genverpat->($ver + ($subver != 0), 3) . '.[0-9]';
        if ($subver) {
            $pat = "{$ver." . $genverpat->($subver, 3) . ",$pat}";
        }

        $perl_pattern = "*5.$pat*";
    }

    my $multitest = <<'__EOT__';

.PHONY: multitest
multitest :
	shopt -s nullglob; f=''; k=''; \
	for i in "$$PERLBREW_ROOT"/perls/<PERL_PATTERN>/bin/perl perl; do \
	    echo "Trying $$i ..."; \
	    if $$i Makefile.PL && make && make test; then \
	        k="$$k $$i"; \
	    else \
	        f="$$f $$i"; \
	    fi; \
	    echo "... done (trying $$i)"; \
	done; \
	[ -z "$$k" ] || { echo "OK:    $$k" >&2; } ; \
	[ -z "$$f" ] || { echo "Failed:$$f" >&2; exit 1; }
__EOT__
    $multitest =~ s/<PERL_PATTERN>/$perl_pattern/g;
    $opt->{postamble}{text} .= $multitest;
    $opt->{macro}{SHELL} ||= '/bin/bash';

    my $maint_distcheck = <<'__EOT__';

distcheck : maint_distcheck
.PHONY: maint_distcheck
maint_distcheck :
	$(PERLRUN) maint/distcheck.pl '$(VERSION)' '$(TO_INST_PM)'

create_distdir : distcheck
__EOT__
    $opt->{postamble}{text} .= $maint_distcheck;

    my $readme = <<'__EOT__';

pure_all :: .github/README.md

.github/README.md : lib/$(subst ::,/,$(NAME)).pm maint/pod2markdown.pl
	mkdir -p .github
	$(PERLRUN) maint/pod2markdown.pl < '$<' > '$@.~tmp~' && $(MV) -- '$@.~tmp~' '$@'

distdir : $(DISTVNAME)/README

$(DISTVNAME)/README : lib/$(subst ::,/,$(NAME)).pm create_distdir
	$(TEST_F) '$@' || ( $(PERLRUN) maint/pod2readme.pl < '$<' > '$@.~tmp~' && $(MV) -- '$@.~tmp~' '$@' && cd '$(DISTVNAME)' && $(PERLRUN) -MExtUtils::Manifest=maniadd -e 'maniadd { "README" => "generated from $(NAME) POD (added by maint/eumm-fixup.pl)" }' )

__EOT__
    $opt->{postamble}{text} .= $readme;
    for ($opt->{META_MERGE}{prereqs}{develop}{requires}{'Pod::Markdown'}) {
        $_ = '3.005' if !$_ || $_ < '3.005';
    }
    for ($opt->{META_MERGE}{prereqs}{develop}{requires}{'Pod::Text'}) {
        $_ = '4.09'  if !$_ || $_ < '4.09';
    }
}
