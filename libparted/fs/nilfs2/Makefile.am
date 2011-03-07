partedincludedir	= -I$(top_srcdir)/include

AM_CFLAGS = $(WARN_CFLAGS) $(WERROR_CFLAGS)

noinst_LTLIBRARIES	= libnilfs2.la
libnilfs2_la_SOURCES	= nilfs2.c

INCLUDES = $(partedincludedir) $(INTLINCS)

MAINTAINERCLEANFILES = Makefile.in
