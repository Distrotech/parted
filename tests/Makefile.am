TESTS = \
  t0000-basic.sh \
  t1000-mkpartfs.sh \
  t2000-mkfs.sh

TESTS_ENVIRONMENT = \
  PATH="`pwd`/../parted$(PATH_SEPARATOR)$$PATH"

EXTRA_DIST = \
  $(TESTS) test-lib.sh

CLEANFILES = init.sh
all: init.sh
init.sh: Makefile.in
	( echo 'srcdir=$(srcdir)'; echo '. $$srcdir/test-lib.sh' ) > $@-t
	mv $@-t $@
