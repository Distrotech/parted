AM_CFLAGS = $(WARN_CFLAGS) $(WERROR_CFLAGS)
partedincludedir      =	-I$(top_srcdir)/include

noinst_LTLIBRARIES    =	libamigafs.la
libamigafs_la_SOURCES   =	amiga.h		\
			amiga.c		\
			affs.h		\
			affs.c		\
			asfs.h		\
			asfs.c		\
			apfs.h		\
			apfs.c		\
			interface.c

INCLUDES = $(partedincludedir) $(INTLINCS)

MAINTAINERCLEANFILES = Makefile.in
