# This file is part of GNU Parted
# Copyright (C) 1999, 2000, 2001, 2007 Free Software Foundation, Inc.
#
# This file may be modified and/or distributed without restriction.

partedincludedir      =	-I$(top_srcdir)/include
noinst_LTLIBRARIES    =	liblabels.la

liblabels_la_SOURCES  = rdb.c		\
			bsd.c  		\
			dasd.c		\
			fdasd.c		\
			vtoc.c		\
			efi_crc32.c	\
			dos.c  		\
			dvh.h		\
			dvh.c  		\
			gpt.c  		\
			loop.c 		\
			mac.c  		\
			pc98.c 		\
			sun.c		\
			aix.c

liblabels_la_LIBADD = $(OS_LIBS) $(INTLLIBS)

INCLUDES = $(partedincludedir) $(INTLINCS)

MAINTAINERCLEANFILES = Makefile.in
