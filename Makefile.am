ACLOCAL_AMFLAGS = -I m4
SUBDIRS = po libparted parted partprobe include doc debug

EXTRA_DIST = config.rpath                          \
             ABOUT-NLS                             \
             AUTHORS                               \
             BUGS                                  \
             COPYING                               \
             THANKS                                \
             TODO                                  \
             parted.spec.in                        \
             parted.m4                             \
             scripts/data/abi/baseline_symbols.txt \
             scripts/extract_symvers

aclocaldir=$(datadir)/aclocal
aclocal_DATA=parted.m4

dist-hook: parted.spec
	cp parted.spec $(distdir)

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
