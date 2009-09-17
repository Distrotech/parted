XFAIL_TESTS = \
  t3200-type-change.sh

TESTS = \
  help-version \
  t0000-basic.sh \
  t0001-tiny.sh \
  t0010-script-no-ctrl-chars.sh \
  t0100-print.sh \
  t0101-print-empty.sh \
  t0200-gpt.sh \
  t0201-gpt.sh \
  t0202-gpt-pmbr.sh \
  t0205-gpt-list-clobbers-pmbr.sh \
  t0206-gpt-print-with-corrupt-primary-clobbers-pmbr.sh \
  t0207-IEC-binary-notation.sh \
  t0220-gpt-msftres.sh \
  t0250-gpt.sh \
  t0280-gpt-corrupt.sh \
  t0300-dos-on-gpt.sh \
  t0400-loop-clobber-infloop.sh \
  t0500-dup-clobber.sh \
  t1100-busy-label.sh \
  t1101-busy-partition.sh \
  t1700-probe-fs.sh \
  t2200-dos-label-recog.sh \
  t2300-dos-label-extended-bootcode.sh \
  t2310-dos-extended-2-sector-min-offset.sh \
  t2400-dos-hfs-partition-type.sh \
  t3200-type-change.sh \
  t3300-palo-prep.sh \
  t3310-flags.sh \
  t3400-whole-disk-FAT-partition.sh \
  t4000-sun-raid-type.sh \
  t4001-sun-vtoc.sh \
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
  t9030-align-check.sh \
  t9040-many-partitions.sh \
  t9041-undetected-in-use-16th-partition.sh \
  t9050-partition-table-types.sh

EXTRA_DIST = \
  $(TESTS) lvm-utils.sh t-local.sh t-lvm.sh \
  init.cfg init.sh t-lib-helpers.sh

check_PROGRAMS = print-align print-max dup-clobber
LDADD = \
  $(top_builddir)/libparted/libparted.la
AM_CPPFLAGS = \
  -I$(top_srcdir)/lib \
  -I$(top_srcdir)/include
AM_CFLAGS = $(WARN_CFLAGS) $(WERROR_CFLAGS)

parted_dir = $(abs_top_builddir)/parted
pp_dir = $(abs_top_builddir)/partprobe
sep = $(PATH_SEPARATOR)

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
  built_programs=parted				\
  srcdir='$(srcdir)'				\
  top_srcdir='$(top_srcdir)'			\
  AWK='$(AWK)'					\
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
  VERSION=$(VERSION)				\
  ; shell_or_perl_

VERBOSE = yes
