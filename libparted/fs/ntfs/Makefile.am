AM_CFLAGS = $(WARN_CFLAGS) $(WERROR_CFLAGS)
partedincludedir	= -I$(top_srcdir)/include

noinst_LTLIBRARIES	= libntfs.la
libntfs_la_SOURCES	= ntfs.c

INCLUDES = $(partedincludedir) $(INTLINCS)

MAINTAINERCLEANFILES = Makefile.in
