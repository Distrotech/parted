TESTS = \
  t0000-basic.sh \
  t1000-mkpartfs.sh \
  t1100-busy-label.sh \
  t1500-small-ext2.sh \
  t2000-mkfs.sh

TESTS_ENVIRONMENT = \
  PATH="`pwd`/../parted$(PATH_SEPARATOR)$$PATH"

EXTRA_DIST = \
  $(TESTS) test-lib.sh

CLEANFILES = init.sh
all: init.sh
init.sh: Makefile.in
	rm -f $@-t $@
	( echo 'srcdir=$(srcdir)'; echo '. $$srcdir/test-lib.sh' ) > $@-t
	chmod a-w $@-t
	mv $@-t $@
