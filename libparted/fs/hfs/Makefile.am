AM_CFLAGS = $(WARN_CFLAGS) $(WERROR_CFLAGS)
partedincludedir	= -I$(top_srcdir)/include

noinst_LTLIBRARIES	= libhfs.la
libhfs_la_SOURCES	= hfs.c hfs.h \
			  probe.c probe.h

INCLUDES = $(partedincludedir) $(INTLINCS)

EXTRA_DIST = DOC HISTORY

MAINTAINERCLEANFILES = Makefile.in
