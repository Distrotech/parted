partedincludedir      = -I$(top_srcdir)/include

sbin_PROGRAMS = partprobe

partprobe_SOURCES = partprobe.c

partprobe_LDADD = @INTLLIBS@ @LIBS@ \
	       $(top_builddir)/libparted/libparted.la @PARTED_LIBS@ 

partprobe_LDFLAGS = @PARTEDLDFLAGS@

INCLUDES	= $(partedincludedir) @INTLINCS@

