partedincludedir	= -I$(top_srcdir)/include

noinst_LTLIBRARIES	= libhfs.la
libhfs_la_SOURCES	= hfs.c hfs.h \
			  probe.c probe.h \
			  cache.c cache.h \
			  advfs.c advfs.h \
			  file.c file.h \
			  reloc.c reloc.h \
			  advfs_plus.c advfs_plus.h \
			  file_plus.c file_plus.h \
			  reloc_plus.c reloc_plus.h \
			  journal.c journal.h

INCLUDES = $(partedincludedir) $(INTLINCS)

EXTRA_DIST = DOC HISTORY

MAINTAINERCLEANFILES = Makefile.in
