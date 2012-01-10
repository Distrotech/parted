# This file is part of GNU Parted
# Copyright (C) 1999-2001, 2007, 2009-2012 Free Software Foundation, Inc.
#
# This file may be modified and/or distributed without restriction.

partedincludedir      =	-I$(top_srcdir)/include
noinst_LTLIBRARIES    =	libfs.la
libfs_la_LDFLAGS  = -version-info $(LT_CURRENT):$(LT_REVISION):$(LT_AGE) \
			-release $(LT_RELEASE)

libfs_la_LIBADD   = $(UUID_LIBS)		\
		    $(INTLLIBS)			\
		    $(OS_LIBS)

libfs_la_SOURCES =		\
  amiga/affs.c			\
  amiga/affs.h			\
  amiga/amiga.c			\
  amiga/amiga.h			\
  amiga/apfs.c			\
  amiga/apfs.h			\
  amiga/asfs.c			\
  amiga/asfs.h			\
  amiga/a-interface.c		\
  ext2/ext2.h			\
  ext2/ext2_fs.h		\
  ext2/interface.c		\
  fat/bootsector.c		\
  fat/bootsector.h		\
  fat/count.h			\
  fat/fat.c			\
  fat/fat.h			\
  hfs/hfs.c			\
  hfs/hfs.h			\
  hfs/probe.c			\
  hfs/probe.h			\
  jfs/jfs.c			\
  jfs/jfs_superblock.h		\
  jfs/jfs_types.h		\
  linux_swap/linux_swap.c	\
  nilfs2/nilfs2.c		\
  ntfs/ntfs.c			\
  reiserfs/reiserfs.c		\
  reiserfs/reiserfs.h		\
  ufs/ufs.c			\
  xfs/platform_defs.h		\
  xfs/xfs.c			\
  xfs/xfs_sb.h			\
  xfs/xfs_types.h

EXTRA_DIST = hfs/DOC hfs/HISTORY

INCLUDES = $(partedincludedir) $(INTLINCS)

MAINTAINERCLEANFILES = Makefile.in
