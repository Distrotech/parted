noinst_PROGRAMS	= clearfat

clearfat_SOURCES = clearfat.c

clearfat_LDADD = \
  $(top_builddir)/lib/libparted.la \
  $(top_builddir)/libparted/libparted.la \
  $(INTLLIBS) $(LIBS) \
  $(PARTED_LIBS)

partedincludedir	= -I$(top_srcdir)/lib -I$(top_srcdir)/include

INCLUDES 		= $(partedincludedir) $(INTLINCS)

MAINTAINERCLEANFILES = Makefile.in
