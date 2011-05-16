AM_CFLAGS = $(WARN_CFLAGS) $(WERROR_CFLAGS)
partedincludedir	= -I$(top_srcdir)/include

noinst_LTLIBRARIES	= libjfs.la
libjfs_la_SOURCES	= jfs.c jfs_superblock.h jfs_types.h

INCLUDES = $(partedincludedir) $(INTLINCS)

MAINTAINERCLEANFILES = Makefile.in
