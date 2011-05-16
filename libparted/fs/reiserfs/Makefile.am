AM_CFLAGS = $(WARN_CFLAGS) $(WERROR_CFLAGS)
partedincludedir	= -I$(top_srcdir)/include

noinst_LTLIBRARIES	= libreiserfs.la

libreiserfs_la_SOURCES	= reiserfs.c reiserfs.h

INCLUDES = $(partedincludedir) $(INTLINCS)

MAINTAINERCLEANFILES = Makefile.in
