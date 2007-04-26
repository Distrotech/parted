ACLOCAL_AMFLAGS = -I m4
SUBDIRS = po lib libparted parted partprobe include doc debug tests

EXTRA_DIST =				\
  .prev-version				\
  BUGS					\
  libparted.pc.in			\
  parted.spec.in			\
  parted.spec				\
  scripts/data/abi/baseline_symbols.txt \
  scripts/extract_symvers		\
  Makefile.cfg				\
  Makefile.maint			\
  GNUmakefile

aclocaldir=$(datadir)/aclocal

pcdir = $(libdir)/pkgconfig
pc_DATA = libparted.pc

# This is best not done via configure.ac, because automake's
# make distcheck target does not like auto-generated files
# being included in the distributed archive.
parted.spec: parted.spec.in
	sed 's/@''PACKAGE@/$(PACKAGE)/;s/@''VERSION@/$(VERSION)/' $< > $@-tmp
	mv $@-tmp $@
MAINTAINERCLEANFILES = parted.spec

distcheck-hook:
	$(MAKE) my-distcheck

### ABI Checking scripts ###

baseline_file = ${top_srcdir}/scripts/data/abi/baseline_symbols.txt
extract_symvers = $(top_srcdir)/scripts/extract_symvers

current_symbols.txt: ${extract_symvers}
	  -@(sh ${extract_symvers} libparted/.libs/libparted.so current_symbols.txt)

baseline_symbols:
	-@(output=${baseline_file}; \
	  if test ! -f $${output}; then \
	    echo "Baseline file doesn't exist."; \
	    echo "Try 'make new-abi-baseline' to create it."; \
	    exit 1; \
	  fi; true)

new-abi-baseline:
	-@$(mkinstalldirs) ${baseline_dir}
	-@(output=${baseline_file}; \
	  if test -f $${output}; then \
	    output=$${output}.new; \
	    t=`echo $${output} | sed 's=.*config/abi/=='`; \
	    echo "Baseline file already exists, writing to $${t} instead."; \
	  fi; \
	  sh ${extract_symvers} libparted/.libs/libparted.so $${output})

# Use 'new-abi-baseline' to create an initial symbol file.  Then run
# 'check-abi' to test for changes against that file.
check-abi: baseline_symbols current_symbols.txt
	@diff -u ${baseline_file} ./current_symbols.txt 2>&1 \
         | tee libparted.abi-diff
	@test `wc -l < libparted.abi-diff` -gt 0 \
         && (echo "ABI has changed. Please, update you ABI package version."; exit 1) \
         || exit 0

MOSTLYCLEANDIRS = m4

MAINTAINERCLEANFILES += \
  ABOUT-NLS     \
  ChangeLog     \
  INSTALL       \
  aclocal.m4    \
  configure
