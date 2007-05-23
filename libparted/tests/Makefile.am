# This file is part of GNU Parted
# Copyright (C) 1999, 2000, 2001, 2007 Free Software Foundation, Inc.
#
# This file may be modified and/or distributed without restriction.

TESTS = t1000-label.sh
EXTRA_DIST = $(TESTS)
bin_PROGRAMS     = label
label_CFLAGS    = $(CHECK_CFLAGS) -I$(top_srcdir)/include
label_LDADD     = $(CHECK_LIBS) $(top_builddir)/libparted/libparted.la
label_SOURCES   = common.h common.c label.c

MAINTAINERCLEANFILES = Makefile.in

CLEANFILES = init.sh
all: init.sh
init.sh: Makefile.in
	rm -f $@-t $@
	echo 'PARTED_USABLE_TEST_DIR=$(PARTED_USABLE_TEST_DIR)' > $@-t
	echo 'abs_top_srcdir=$(abs_top_srcdir)' >> $@-t
	echo '. $(abs_top_srcdir)/tests/test-lib.sh' >> $@-t
	echo 'PATH=$(abs_builddir)$(PATH_SEPARATOR)$$PATH; export PATH' >> $@-t
	chmod a-w $@-t
	mv $@-t $@
