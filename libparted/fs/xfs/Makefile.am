AM_CFLAGS = $(WARN_CFLAGS) $(WERROR_CFLAGS)
partedincludedir	= -I$(top_srcdir)/include

noinst_LTLIBRARIES	= libxfs.la
libxfs_la_SOURCES	= xfs.c xfs_sb.h xfs_types.h platform_defs.h

INCLUDES = $(partedincludedir) $(INTLINCS)

MAINTAINERCLEANFILES = Makefile.in
