/*
Copyright 2012 Lukas Mai.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
 */

#ifdef __GNUC__
 #if (__GNUC__ == 4 && __GNUC_MINOR__ >= 6) || __GNUC__ >= 5
  #define PRAGMA_GCC_(X) _Pragma(#X)
  #define PRAGMA_GCC(X) PRAGMA_GCC_(GCC X)
 #endif
#endif

#ifndef PRAGMA_GCC
 #define PRAGMA_GCC(X)
#endif

#ifdef DEVEL
 #define WARNINGS_RESET PRAGMA_GCC(diagnostic pop)
 #define WARNINGS_ENABLEW(X) PRAGMA_GCC(diagnostic warning #X)
 #define WARNINGS_ENABLE \
 	WARNINGS_ENABLEW(-Wall) \
 	WARNINGS_ENABLEW(-Wextra) \
 	WARNINGS_ENABLEW(-Wundef) \
 	/* WARNINGS_ENABLEW(-Wshadow) :-( */ \
 	WARNINGS_ENABLEW(-Wbad-function-cast) \
 	WARNINGS_ENABLEW(-Wcast-align) \
 	WARNINGS_ENABLEW(-Wwrite-strings) \
 	/* WARNINGS_ENABLEW(-Wnested-externs) wtf? */ \
 	WARNINGS_ENABLEW(-Wstrict-prototypes) \
 	WARNINGS_ENABLEW(-Wmissing-prototypes) \
 	WARNINGS_ENABLEW(-Winline) \
 	WARNINGS_ENABLEW(-Wdisabled-optimization)

#else
 #define WARNINGS_RESET
 #define WARNINGS_ENABLE
#endif


#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <string.h>
#include <ctype.h>


WARNINGS_ENABLE


#define HAVE_PERL_VERSION(R, V, S) \
	(PERL_REVISION > (R) || (PERL_REVISION == (R) && (PERL_VERSION > (V) || (PERL_VERSION == (V) && (PERL_SUBVERSION >= (S))))))

#if HAVE_PERL_VERSION(5, 16, 0)
 #define IF_HAVE_PERL_5_16(YES, NO) YES
#else
 #define IF_HAVE_PERL_5_16(YES, NO) NO
#endif


#define MY_PKG "Quote::Code"

#define HINTK_QC  MY_PKG "/qc"


static int (*next_keyword_plugin)(pTHX_ char *, STRLEN, OP **);

static void free_ptr_op(pTHX_ void *vp) {
	OP **pp = vp;
	op_free(*pp);
	Safefree(pp);
}

static void missing_terminator(pTHX_ I32 c) {
	SV *sv;
	sv = sv_2mortal(newSVpvs("'\"'"));
	if (c != '"') {
		char utf8_tmp[UTF8_MAXBYTES + 1], *d;
		d = uvchr_to_utf8(utf8_tmp, c);
		pv_uni_display(sv, utf8_tmp, d - utf8_tmp, 100, UNI_DISPLAY_QQ);
		sv_insert(sv, 0, 0, "\"", 1);
		sv_catpvs(sv, "\"");
	}
	croak("Can't find string terminator %"SVf" anywhere before EOF", SVfARG(sv));
}

static void my_sv_cat_c(pTHX_ SV *sv, U32 c) {
	char ds[UTF8_MAXBYTES + 1], *d;
	d = uvchr_to_utf8(ds, c);
	if (d - ds > 1) {
		sv_utf8_upgrade(sv);
	}
	sv_catpvn(sv, ds, d - ds);
}

static U32 hex2int(unsigned char c) {
	static char xdigits[] = "0123456789abcdef";
	char *p = strchr(xdigits, tolower(c));
	if (!c || !p) {
		return 0;
	}
	return p - xdigits;
}

static void parse_qc(pTHX_ OP **op_ptr) {
	I32 c, delim_start, delim_stop;
	int nesting;
	OP **gen_sentinel;
	SV *sv;

	c = lex_peek_unichar(0);

	if (c != '#') {
		lex_read_space(0);
		c = lex_peek_unichar(0);
		if (c == -1) {
			croak("Unexpected EOF after qc");
		}
	}
	lex_read_unichar(0);

	delim_start = c;
	delim_stop =
		c == '(' ? ')' :
		c == '[' ? ']' :
		c == '{' ? '}' :
		c == '<' ? '>' :
		c
	;

	nesting = delim_start == delim_stop ? -1 : 0;

	Newx(gen_sentinel, 1, OP *);
	*gen_sentinel = NULL;
	SAVEDESTRUCTOR_X(free_ptr_op, gen_sentinel);

	sv = sv_2mortal(newSVpvs(""));
	if (lex_bufutf8()) {
		SvUTF8_on(sv);
	}

	for (;;) {
		c = lex_read_unichar(0);
		if (c == -1) {
			missing_terminator(aTHX_ delim_stop);
		}

		if (c == '{') {
			OP *op;

			lex_stuff_pvs("{", 0);
			op = parse_block(0);
			op = newUNOP(OP_NULL, OPf_SPECIAL, op_scope(op));

			if (SvCUR(sv)) {
				OP *str = newSVOP(OP_CONST, 0, SvREFCNT_inc_simple_NN(sv));
				if (*gen_sentinel) {
					*gen_sentinel = newBINOP(OP_CONCAT, 0, *gen_sentinel, str);
				} else {
					*gen_sentinel = str;
				}
				sv = sv_2mortal(newSVpvs(""));
				if (lex_bufutf8()) {
					SvUTF8_on(sv);
				}
			}

			if (*gen_sentinel) {
				*gen_sentinel = newBINOP(OP_CONCAT, 0, *gen_sentinel, op);
			} else {
				*gen_sentinel = op;
			}

			continue;
		}

		if (nesting != -1 && c == delim_start) {
			nesting++;
		} else if (c == delim_stop) {
			if (nesting == -1 || nesting == 0) {
				break;
			}
			nesting--;
		} else if (c == '\\') {
			U32 u;

			c = lex_read_unichar(0);
			switch (c) {
				case -1:
					missing_terminator(aTHX_ delim_stop);

				case 'a': c = '\a'; break;
				case 'b': c = '\b'; break;
				case 'e': c = '\033'; break;
				case 'f': c = '\f'; break;
				case 'n': c = '\n'; break;
				case 'r': c = '\r'; break;
				case 't': c = '\t'; break;

				case 'c':
					c = lex_read_unichar(0);
					if (c == -1) {
						missing_terminator(aTHX_ delim_stop);
					}
					c = toUPPER(c) ^ 64;
					break;

				case 'o':
					c = lex_read_unichar(0);
					if (c != '{') {
						croak("Missing braces on \\o{}");
					}
					u = 0;
					while (c = lex_peek_unichar(0), c >= '0' && c <= '7') {
						u = u * 8 + (c - '0');
						lex_read_unichar(0);
					}
					if (c != '}') {
						croak("Missing right brace on \\o{}");
					}
					lex_read_unichar(0);
					c = u;
					break;

				case 'x':
					c = lex_read_unichar(0);
					if (c == '{') {
						u = 0;
						while (c = lex_peek_unichar(0), isXDIGIT(c)) {
							u = u * 16 + hex2int(c);
							lex_read_unichar(0);
						}
						if (c != '}') {
							croak("Missing right brace on \\x{}");
						}
						lex_read_unichar(0);
						c = u;
					} else if (isXDIGIT(c)) {
						u = hex2int(c);
						c = lex_peek_unichar(0);
						if (isXDIGIT(c)) {
							u = u * 16 + hex2int(c);
							lex_read_unichar(0);
						}
						c = u;
					} else {
						c = 0;
					}
					break;

				default:
					if (c >= '0' && c <= '7') {
						u = c - '0';
						c = lex_peek_unichar(0);
						if (c >= '0' && c <= '7') {
							u = u * 8 + (c - '0');
							lex_read_unichar(0);
							c = lex_peek_unichar(0);
							if (c >= '0' && c <= '7') {
								u = u * 8 + (c - '0');
								lex_read_unichar(0);
							}
						}
						c = u;
					}
					break;
			}
		}

		my_sv_cat_c(aTHX_ sv, c);
	}

	if (SvCUR(sv) || !*gen_sentinel) {
		OP *str = newSVOP(OP_CONST, 0, SvREFCNT_inc_simple_NN(sv));
		if (*gen_sentinel) {
			*gen_sentinel = newBINOP(OP_CONCAT, 0, *gen_sentinel, str);
		} else {
			*gen_sentinel = str;
		}
	}

	{
		OP *gen = *gen_sentinel;
		*gen_sentinel = NULL;

		if (gen->op_type == OP_CONST) {
			SvPOK_only_UTF8(((SVOP *)gen)->op_sv);
		} else if (gen->op_type != OP_CONCAT) {
			/* can't do this because B::Deparse dies on it:
			 * gen = newUNOP(OP_STRINGIFY, 0, gen);
			 */
			gen = newBINOP(OP_CONCAT, 0, gen, newSVOP(OP_CONST, 0, newSVpvs("")));
		}

		*op_ptr = gen;
	}
}

static int my_keyword_plugin(pTHX_ char *keyword_ptr, STRLEN keyword_len, OP **op_ptr) {
	int ret;

	SAVETMPS;

	if (keyword_len == 2 && keyword_ptr[0] == 'q' && keyword_ptr[1] == 'c') {
		parse_qc(aTHX_ op_ptr);
		ret = KEYWORD_PLUGIN_EXPR;
	} else {
		ret = next_keyword_plugin(aTHX_ keyword_ptr, keyword_len, op_ptr);
	}

	FREETMPS;

	return ret;
}


WARNINGS_RESET

MODULE = Quote::Code   PACKAGE = Quote::Code
PROTOTYPES: ENABLE

BOOT:
WARNINGS_ENABLE {
	HV *const stash = gv_stashpvs(MY_PKG, GV_ADD);
	/**/
	newCONSTSUB(stash, "HINTK_QC", newSVpvs(HINTK_QC));
	/**/
	next_keyword_plugin = PL_keyword_plugin;
	PL_keyword_plugin = my_keyword_plugin;
} WARNINGS_RESET
