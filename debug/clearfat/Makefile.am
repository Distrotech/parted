noinst_PROGRAMS	= clearfat

AM_CFLAGS = $(WARN_CFLAGS) $(WERROR_CFLAGS)
clearfat_SOURCES = clearfat.c

clearfat_LDADD = \
  $(top_builddir)/libparted/libparted.la \
  $(INTLLIBS) $(LIBS) \
  $(PARTED_LIBS)

partedincludedir	= -I$(top_srcdir)/lib -I$(top_srcdir)/include

INCLUDES		= $(partedincludedir) $(INTLINCS)

MAINTAINERCLEANFILES = Makefile.in
