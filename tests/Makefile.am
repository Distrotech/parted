TESTS = \
  t0000-basic.sh \
  t0100-print.sh \
  t1000-mkpartfs.sh \
  t1100-busy-label.sh \
  t1500-small-ext2.sh \
  t2000-mkfs.sh \
  t3000-constraints.sh \
  t3100-resize-ext2-partion.sh

EXTRA_DIST = \
  $(TESTS) test-lib.sh mkdtemp

CLEANFILES = init.sh
all: init.sh
init.sh: Makefile.in
	rm -f $@-t $@
	echo 'PARTED_USABLE_TEST_DIR=$(PARTED_USABLE_TEST_DIR)' > $@-t
	echo 'abs_top_srcdir=$(abs_top_srcdir)' >> $@-t
	echo '. $(abs_top_srcdir)/tests/test-lib.sh' >> $@-t
	echo 'PATH=$(abs_top_builddir)/parted$(PATH_SEPARATOR)$$PATH' >> $@-t
	echo 'export PATH' >> $@-t
	chmod a-w $@-t
	mv $@-t $@
