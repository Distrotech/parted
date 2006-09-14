# This file is part of GNU Parted
# Copyright (C) 1999, 2000, 2001 Free Software Foundation, Inc.
#
# This file may be modified and/or distributed without restriction.

SUBDIRS       = labels fs

LIBS = @INTLLIBS@ @LIBS@

partedincludedir      =	-I$(top_srcdir)/include
lib_LTLIBRARIES	      =	libparted.la
libparted_la_LDFLAGS  = -version-info $(LT_CURRENT):$(LT_REVISION):$(LT_AGE) \
 			-release $(LT_RELEASE)

libparted_la_SOURCES  = debug.c			\
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
			arch/@OS@.c

EXTRA_libparted_la_SOURCES    = arch/linux.c		\
				arch/gnu.c \
				arch/beos.c

libparted_la_LIBADD   = @OS_LIBS@			\
			@DL_LIBS@			\
			fs/libfs.la			\
			labels/liblabels.la

EXTRA_DIST	      = mbr.s

INCLUDES = $(partedincludedir) @INTLINCS@
