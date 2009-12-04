XFAIL_TESTS = \
  t3200-type-change.sh

TESTS = \
  t0000-basic.sh \
  t0001-tiny.sh \
  t0010-script-no-ctrl-chars.sh \
  t0100-print.sh \
  t0200-gpt.sh \
  t0201-gpt.sh \
  t0202-gpt-pmbr.sh \
  t0220-gpt-msftres.sh \
  t0250-gpt.sh \
  t0280-gpt-corrupt.sh \
  t0300-dos-on-gpt.sh \
  t0400-loop-clobber-infloop.sh \
  t1100-busy-label.sh \
  t1700-ext-probe.sh \
  t2100-mkswap.sh \
  t2200-dos-label-recog.sh \
  t2300-dos-label-extended-bootcode.sh \
  t3000-resize-fs.sh \
  t4000-sun-raid-type.sh \
  t4100-msdos-partition-limits.sh \
  t4100-dvh-partition-limits.sh \
  t4100-msdos-starting-sector.sh \
  t4200-partprobe.sh \
  t5000-tags.sh \
  t6000-dm.sh \
  t7000-scripting.sh \
  t8000-loop.sh \
  t9010-big-sector.sh \
  t9020-alignment.sh \
  t9021-maxima.sh \
  t9030-align-check.sh

EXTRA_DIST = \
  $(TESTS) test-lib.sh t-lib.sh lvm-utils.sh t-local.sh t-lvm.sh

check_PROGRAMS = print-align print-max
LDADD = \
  $(top_builddir)/libparted/libparted.la
AM_CPPFLAGS = \
  -I$(top_srcdir)/lib \
  -I$(top_srcdir)/include
AM_CFLAGS = $(WARN_CFLAGS) $(WERROR_CFLAGS)

parted_dir = $(abs_top_builddir)/parted
pp_dir = $(abs_top_builddir)/partprobe
sep = $(PATH_SEPARATOR)

CLEANFILES = init.sh
all: init.sh
init.sh: Makefile.in
	rm -f $@-t $@
	echo 'PARTED_USABLE_TEST_DIR="$(PARTED_USABLE_TEST_DIR)"' > $@-t
	echo 'abs_top_srcdir="$(abs_top_srcdir)"' >> $@-t
	echo 'PATH="$(parted_dir)$(sep)$(pp_dir)$(sep)$$PATH"' >> $@-t
	echo 'export PATH' >> $@-t
	chmod a-w $@-t
	mv $@-t $@

# Note that the first lines are statements.  They ensure that environment
# variables that can perturb tests are unset or set to expected values.
# The rest are envvar settings that propagate build-related Makefile
# variables to test scripts.
TESTS_ENVIRONMENT =				\
  tmp__=$$TMPDIR; test -d "$$tmp__" || tmp__=.;	\
  TMPDIR=$$tmp__; export TMPDIR;		\
  exec 9>&2;					\
  shell_or_perl_() {				\
    if grep '^\#!/usr/bin/perl' "$$1" > /dev/null; then			\
      if $(PERL) -e 'use warnings' > /dev/null 2>&1; then		\
	grep '^\#!/usr/bin/perl -T' "$$1" > /dev/null && T_=T || T_=;	\
        $(PERL) -w$$T_ -I$(srcdir) -MCoreutils				\
	      -M"CuTmpdir qw($$f)" -- "$$1";	\
      else					\
	echo 1>&2 "$$tst: configure did not find a usable version of Perl," \
	  "so skipping this test";		\
	(exit 77);				\
      fi;					\
    else					\
      $(SHELL) "$$1";				\
    fi;						\
  };						\
  export					\
  abs_top_builddir='$(abs_top_builddir)'	\
  abs_top_srcdir='$(abs_top_srcdir)'		\
  abs_srcdir='$(abs_srcdir)'			\
  srcdir='$(srcdir)'				\
  top_srcdir='$(top_srcdir)'			\
  CC='$(CC)'					\
  MAKE=$(MAKE)					\
  PACKAGE_BUGREPORT='$(PACKAGE_BUGREPORT)'	\
  PACKAGE_VERSION=$(PACKAGE_VERSION)		\
  CONFIG_HEADER='$(abs_top_builddir)/lib/config.h' \
  ENABLE_DEVICE_MAPPER=$(ENABLE_DEVICE_MAPPER)	\
  PERL='$(PERL)'				\
  PREFERABLY_POSIX_SHELL='$(PREFERABLY_POSIX_SHELL)' \
  REPLACE_GETCWD=$(REPLACE_GETCWD)		\
  PATH='$(abs_top_builddir)/parted$(PATH_SEPARATOR)'"$$PATH" \
  ; shell_or_perl_

VERBOSE = yes
