# This file is part of GNU Parted
# Copyright (C) 1999, 2000, 2001, 2007, 2009 Free Software Foundation, Inc.
#
# This file may be modified and/or distributed without restriction.

if HAVE_CHECK
SUBDIRS_CHECK = tests
else
SUBDIRS_CHECK =
endif

if BUILD_LINUX
ARCH_SOURCE = arch/$(OS).c arch/$(OS).h
else
ARCH_SOURCE = arch/$(OS).c
endif

SUBDIRS       = labels fs . $(SUBDIRS_CHECK)


partedincludedir      = -I$(top_srcdir)/lib -I$(top_srcdir)/include
lib_LTLIBRARIES	      =	libparted.la
libparted_la_LDFLAGS  = -version-info $(LT_CURRENT):$(LT_REVISION):$(LT_AGE) \
						-release $(LT_RELEASE)
libparted_la_SOURCES  = debug.c			\
			architecture.c		\
			architecture.h		\
			device.c		\
			exception.c		\
			filesys.c		\
			libparted.c		\
			timer.c			\
			unit.c			\
			disk.c			\
			cs/geom.c		\
			cs/constraint.c		\
			cs/natmath.c		\
			arch/blkpg.h		\
			$(ARCH_SOURCE)


EXTRA_libparted_la_SOURCES    = arch/linux.c		\
				arch/linux.h	\
				arch/gnu.c \
				arch/beos.c

libparted_la_LIBADD =	\
  fs/libfs.la		\
  labels/liblabels.la	\
  $(top_builddir)/lib/libgnulib.la \
  $(OS_LIBS)		\
  $(DL_LIBS)		\
  $(DM_LIBS)		\
  $(SELINUX_LIBS)	\
  $(INTLLIBS)

EXTRA_DIST	      = mbr.s

INCLUDES = $(partedincludedir) $(INTLINCS)

MAINTAINERCLEANFILES = Makefile.in
