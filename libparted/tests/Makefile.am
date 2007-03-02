# This file is part of GNU Parted
# Copyright (C) 1999, 2000, 2001 Free Software Foundation, Inc.
#
# This file may be modified and/or distributed without restriction.

TESTS = label
bin_PROGRAMS     = label
label_CFLAGS    = $(CHECK_CFLAGS) -I$(top_srcdir)/include
label_LDADD     = $(CHECK_LIBS) $(top_builddir)/libparted/libparted.la
label_SOURCES   = common.h common.c label.c

MAINTAINERCLEANFILES = Makefile.in
