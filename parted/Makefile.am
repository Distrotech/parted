sbin_PROGRAMS = parted

partedincludedir      = -I$(top_srcdir)/include

parted_SOURCES = command.c	\
		 command.h	\
		 parted.c	\
		 strlist.c	\
		 strlist.h	\
		 ui.c		\
		 ui.h		\
		 table.c	\
		 table.h

#parted_CFLAGS = -DBUILDINFO='"\"'@BUILDINFO@'\""'
parted_CFLAGS = -DBUILDINFO=

parted_LDADD = @INTLLIBS@ @LIBS@ $(top_builddir)/libparted/libparted.la \
	       @PARTED_LIBS@ 

parted_LDFLAGS = @PARTEDLDFLAGS@

INCLUDES	= $(partedincludedir) @INTLINCS@

