noinst_PROGRAMS	= clearfat

clearfat_SOURCES = clearfat.c

clearfat_LDADD = @LIBS@ @PARTED_LIBS@ \
               $(top_builddir)/libparted/libparted.la


partedincludedir	= -I$(top_srcdir)/include

INCLUDES 		= $(partedincludedir) @INTLINCS@

