partedincludedir      =	-I$(top_srcdir)/include

noinst_LTLIBRARIES    =	libext2.la
libext2_la_SOURCES    =	ext2.c \
			ext2.h \
			ext2_fs.h \
			ext2_block_relocator.c \
			ext2_buffer.c \
			ext2_inode_relocator.c \
			ext2_meta.c \
			ext2_mkfs.c \
			ext2_resize.c \
			interface.c \
			parted_io.c \
			parted_io.h \
			tune.c \
			tune.h

INCLUDES = $(partedincludedir) $(INTLINCS)

MAINTAINERCLEANFILES = Makefile.in
