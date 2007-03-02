partedincludedir      = -I$(top_srcdir)/lib -I$(top_srcdir)/include

sbin_PROGRAMS = partprobe

partprobe_SOURCES = partprobe.c

partprobe_LDADD = \
  $(top_builddir)/lib/libparted.la \
  $(top_builddir)/libparted/libparted.la \
  $(INTLLIBS) $(LIBS) \
  $(PARTED_LIBS)

partprobe_LDFLAGS = $(PARTEDLDFLAGS)

INCLUDES	= $(partedincludedir) $(INTLINCS)

MAINTAINERCLEANFILES = Makefile.in
