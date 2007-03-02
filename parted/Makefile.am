sbin_PROGRAMS = parted

partedincludedir      = -I$(top_srcdir)/lib -I$(top_srcdir)/include

parted_SOURCES = command.c	\
		 command.h	\
		 parted.c	\
		 strlist.c	\
		 strlist.h	\
		 ui.c		\
		 ui.h		\
		 table.c	\
		 table.h

#parted_CFLAGS = -DBUILDINFO='"\"'$(BUILDINFO)'\""'
parted_CFLAGS = -DBUILDINFO=

parted_LDADD = \
  $(top_builddir)/lib/libparted.la \
  $(top_builddir)/libparted/libparted.la \
  $(INTLLIBS) $(LIBS) \
  $(PARTED_LIBS)

parted_LDFLAGS = $(PARTEDLDFLAGS)

INCLUDES	= $(partedincludedir) $(INTLINCS)

MAINTAINERCLEANFILES = Makefile.in
