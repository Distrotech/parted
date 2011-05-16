AM_CFLAGS = $(WARN_CFLAGS) $(WERROR_CFLAGS)
partedincludedir      =	-I$(top_srcdir)/include

noinst_LTLIBRARIES    =	libext2.la
libext2_la_SOURCES    =	ext2.h \
			ext2_fs.h \
			interface.c

INCLUDES = $(partedincludedir) $(INTLINCS)

MAINTAINERCLEANFILES = Makefile.in
