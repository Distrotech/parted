# This file is part of GNU Parted
# Copyright (C) 1999, 2000, 2001 Free Software Foundation, Inc.
#
# This file may be modified and/or distributed without restriction.

LIBS = @INTLLIBS@ @LIBS@

partedincludedir      =	-I$(top_srcdir)/include
noinst_LTLIBRARIES    =	liblabels.la
liblabels_la_LDFLAGS  = -version-info $(LT_CURRENT):$(LT_REVISION):$(LT_AGE) \
 			-release $(LT_RELEASE)

liblabels_la_SOURCES  = rdb.c		\
			bsd.c  		\
			dasd.c		\
			fdasd.c		\
			fdash.h		\
			vtoc.c		\
			vtoc.h		\
			efi_crc32.c	\
			dos.c  		\
			dvh.h		\
			dvh.c  		\
			gpt.c  		\
			loop.c 		\
			mac.c  		\
			pc98.c 		\
			sun.c			\
			aix.c
			

liblabels_la_LIBADD   = @OS_LIBS@

INCLUDES = $(partedincludedir) @INTLINCS@

