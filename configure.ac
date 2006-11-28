dnl GNU Parted - a library and front end for manipulation hard disk partitions
dnl Copyright (C) 1998, 1999, 2000, 2001, 2002, 2005
dnl                     Free Software Foundation, Inc.
dnl
dnl This file may be modified and/or distributed without restriction.

AC_PREREQ(2.50)

AC_INIT(include/parted/parted.h)

dnl Versioning
dnl Shamelessly pulled straight from glib's configure.in ...
dnl Making releases:
dnl    PED_MICRO_VERSION += 1;
dnl    PED_INTERFACE_AGE += 1;
dnl    PED_BINARY_AGE += 1;
dnl if any functions have been added, set PED_INTERFACE_AGE to 0.
dnl if backwards compatibility has been broken (eg. functions removed,
dnl function signatures changed),
dnl set PED_BINARY_AGE _and_ PED_INTERFACE_AGE to 0.
PED_MAJOR_VERSION=1
PED_MINOR_VERSION=8
PED_MICRO_VERSION=1
PED_INTERFACE_AGE=1
PED_BINARY_AGE=1
PED_VERSION_SUFFIX=
PED_VERSION=$PED_MAJOR_VERSION.$PED_MINOR_VERSION.$PED_MICRO_VERSION$PED_VERSION_SUFFIX

LT_RELEASE=$PED_MAJOR_VERSION.$PED_MINOR_VERSION
LT_CURRENT=`expr $PED_MICRO_VERSION - $PED_INTERFACE_AGE`
LT_REVISION=$PED_INTERFACE_AGE
LT_AGE=`expr $PED_BINARY_AGE - $PED_INTERFACE_AGE`

AC_SUBST(LT_RELEASE)
AC_SUBST(LT_CURRENT)
AC_SUBST(LT_REVISION)
AC_SUBST(LT_AGE)

PACKAGE=parted
VERSION=$PED_VERSION

AM_INIT_AUTOMAKE($PACKAGE, $VERSION)
 
AM_CONFIG_HEADER(config.h)

AC_CANONICAL_HOST
case "$host_os" in
	linux*) OS=linux ;;
	gnu*)	OS=gnu ;;
	beos*)	OS=beos ;;
	*)	AC_MSG_ERROR([Unknown or unsupported OS "$host_os".  Only "linux", "gnu" and "beos" are supported in this version of GNU Parted.]) ;;
esac
AC_SUBST(OS)

dnl Command-line options
AC_ARG_WITH(readline,
	[  --with-readline         support fancy command line editing], ,
	with_readline=yes
)

AC_ARG_ENABLE(mtrace,
	[  --enable-mtrace         enable malloc() debugging], ,
	enable_mtrace=no
)
if test "$enable_mtrace" = yes; then
	AC_DEFINE(ENABLE_MTRACE, 1, [Mtrace malloc() debugging])
fi

AC_ARG_ENABLE(device-mapper,
	[  --enable-device-mapper  enable device mapper support [default=no]], ,
	enable_device_mapper=no
)
if test "$enable_device_mapper" = yes; then
	AC_DEFINE(ENABLE_DEVICE_MAPPER, 1, [device mapper (libdevmapper) support])
fi

AC_ARG_ENABLE(discover-only,
	[  --enable-discover-only  support only reading/probing [default=no]], ,
	enable_discover_only=no
)
if test "$enable_discover_only" = yes; then
	AC_DEFINE(DISCOVER_ONLY, 1, [Probing functionality only])
fi

PARTED_LIBS=""
AC_ARG_ENABLE(dynamic-loading,
[  --enable-dynamic-loading  support dynamic fs libraries [default=yes]], ,
	if test "$enable_discover_only" = yes; then
		enable_dynamic_loading=no
	else
		enable_dynamic_loading=yes
	fi
)
if test "$enable_discover_only" = yes -a "$enable_dynamic_loading" = yes; then
	AC_MSG_ERROR(
[You can't use --enable-dynamic-loading and --disable-discover-only together]
	)
fi

AC_ARG_ENABLE(fs,
	[  --enable-fs             include filesystem support [default=yes]], ,
	enable_fs=yes
)
if test "$enable_fs" = yes; then
	AC_DEFINE(ENABLE_FS, 1,
		  [Include file system support.  i.e. libparted/fs_...])
fi

AC_ARG_ENABLE(debug,
	[  --enable-debug          compile in assertions [default=yes]], ,
	enable_debug=yes
)

if test "$enable_debug" = yes; then
	AC_DEFINE(DEBUG, 1, [Enable assertions, etc.])
fi

AC_ARG_ENABLE(read-only,
	[  --enable-read-only      disable writing (for debugging) [default=no]]
	, ,
	enable_read_only=no
)
if test "$enable_read_only" = yes; then
	AC_DEFINE(READ_ONLY, 1, [Disable all writing code])
fi

PARTEDLDFLAGS=
AC_SUBST(PARTEDLDFLAGS)

AC_ARG_ENABLE(pc98,
	[  --enable-pc98          build with pc98 support [default=yes]], ,
	enable_pc98=yes
)
if test "$enable_pc98" = yes; then
	AC_DEFINE(ENABLE_PC98, 1,
		  [Include PC98 partition tables.  (Sometimes excluded to avoid
		   collisions with msdos partition tables])
fi

AC_ARG_ENABLE(Werror,
	[  --enable-Werror         build with gcc -Werror [default=yes]], ,
	enable_Werror=yes
)

AC_ARG_ENABLE(hfs-extract-fs,
	[  --enable-hfs-extract-fs Extract special HFS files for debugging [default=no]], ,
	enable_hfs_extract_fs=no
)
if test "$enable_hfs_extract_fs" = yes; then
       AC_DEFINE(HFS_EXTRACT_FS, 1,
                 [Extract low level special HFS(+) files for debugging purposes
                  when using the "check" command (NOT FOR PACKAGING)])
fi

dnl make libc threadsafe (not required for us, but useful other users of
dnl libparted)
CFLAGS="$CFLAGS -D_REENTRANT"

dnl Check for programs.
AC_ISC_POSIX
AC_PROG_CC
AC_PROG_GCC_TRADITIONAL

dnl This test must come as early as possible after the compiler configuration
dnl tests, because the choice of the file model can (in principle) affect
dnl whether functions and headers are available, whether they work, etc.
AC_SYS_LARGEFILE

CFLAGS="$CFLAGS -D_FILE_OFFSET_BITS=${ac_cv_sys_file_offset_bits}"
AC_CHECK_SIZEOF(off_t, 64, [
	#include <stdio.h>
	#include <sys/types.h>
	#include <unistd.h>
])

AM_ENABLE_SHARED
if test "$OS" = linux -a $ac_cv_sizeof_off_t -lt 8; then
	dnl Need to disable shared libraries, to get llseek() to work.  Long
	dnl story.  The short story is: lseek() isn't in glibc, so a syscall
	dnl must be made.  syscalls can't be made from within shared libraries,
	dnl because of a bug (?) in gcc.
	AC_MSG_WARN(
off_t is less than 8 bytes.  Using llseek syscall, and disabling shared
libraries.)
	AM_DISABLE_SHARED
fi
AM_PROG_LIBTOOL

dnl Initialize i18n:
ALL_LINGUAS="ca cs da de es fr gl id it ja nl nn hu pl pt pt_BR ru sv tr uk vi zh_CN zh_TW"
AM_GNU_GETTEXT_VERSION([0.12.1])
AM_GNU_GETTEXT([external])
CFLAGS="$CFLAGS -DLOCALEDIR=\"\\\"$datadir/locale\\\"\""
if test "$USE_INCLUDED_LIBINTL" = "yes"; then
	AC_MSG_ERROR(
GNU Parted requires gettext to be installed for compilation -
if native language support is desired.  Either disable native language support
with:
	$ ./configure --disable-nls
Or install gettext.  GNU gettext is available from
	http://ftp.gnu.org/gnu/gettext
)
	exit
fi
CFLAGS="$CFLAGS -DLOCALEDIR=\"\\\"$datadir/locale\\\"\""

dnl Check for libdl, if we are doing dynamic loading
DL_LIBS=""
if test "$enable_dynamic_loading" = yes; then
	AC_CHECK_LIB(dl, dlopen,
		DL_LIBS="-ldl"
		PARTED_LIBS="$PARTED_LIBS -ldl"
		AC_DEFINE(DYNAMIC_LOADING, 1, [Lazy linking to fs libs]),
		AC_MSG_ERROR(
			[-ldl not found!  Try using --disable-dynamic-loading]
		)
		exit
	)
fi
AC_SUBST(DL_LIBS)

dnl Check for libuuid
UUID_LIBS=""
AC_CHECK_LIB(uuid, uuid_generate, UUID_LIBS="-luuid",
	AC_MSG_ERROR(
GNU Parted requires libuuid - a part of the e2fsprogs package (but
sometimes distributed separately in uuid-devel or similar)
This can probably be found on your distribution's CD or FTP site or at:
         http://web.mit.edu/tytso/www/linux/e2fsprogs.html
Note: if you are using precompiled packages you will also need the development
package as well (which may be called e2fsprogs-devel or something similar).
If you compile e2fsprogs yourself then you need to do 'make install' and
'make install-libs'.
	)
	exit
)
AC_SUBST(UUID_LIBS)

dnl Check for libdevmapper
DM_LIBS=""
if test "$enable_device_mapper" = yes; then
	AC_CHECK_LIB(devmapper, dm_task_create,
		DM_LIBS="-ldevmapper",
		AC_MSG_ERROR(
			[libdevmapper not found!  Try using --disable-device-mapper]
		)
		exit
	)
fi
AC_SUBST(DM_LIBS)

dnl Check for libreiserfs
REISER_LIBS=""
if test "$enable_dynamic_loading" = no -a "$enable_discover_only" = no; then
	OLD_LIBS="$LIBS"
	AC_CHECK_LIB(dal, dal_equals,
		LIBS="-ldal"
		AC_CHECK_LIB(reiserfs, reiserfs_fs_probe,
			REISER_LIBS="-ldal -lreiserfs"
			AC_DEFINE(HAVE_LIBREISERFS, 1, [Have libreiserfs])
		)
		AC_CHECK_LIB(reiserfs, reiserfs_fs_check,
			AC_DEFINE(HAVE_REISERFS_FS_CHECK, 1, [Have reiserfs_fs_check()])
		)
	)
	LIBS="$OLD_LIBS"
fi
AC_SUBST(REISER_LIBS)

dnl Check for termcap
if test "$with_readline" = yes; then
	OLD_LIBS="$LIBS"
	LIBS=""
	AC_SEARCH_LIBS(tgetent, ncurses curses termcap termlib,
		PARTED_LIBS="$PARTED_LIBS $LIBS",
		AC_MSG_ERROR(
termcap could not be found which is required for the
--with-readline option (which is enabled by default).  Either disable readline
support with --without-readline or download and install termcap from:
	ftp.gnu.org/gnu/termcap
Note: if you are using precompiled packages you will also need the development
  package as well (which may be called termcap-devel or something similar).
Note: (n)curses also seems to work as a substitute for termcap.  This was
  not found either - but you could try installing that as well.
)
	exit
	)
	LIBS="$OLD_LIBS"
fi

dnl Check for readline
if test "$with_readline" = yes; then
	OLD_LIBS="$LIBS"
	LIBS="$LIBS $PARTED_LIBS"
	AC_CHECK_LIB(readline, readline,
		PARTED_LIBS="-lreadline $PARTED_LIBS"
		AC_DEFINE(HAVE_LIBREADLINE, 1, [have readline]),
		AC_MSG_ERROR(
GNU Readline could not be found which is required for the
--with-readline (which is enabled by default).  Either disable readline support with
--without-readline or downloaded and install it from:
        ftp.gnu.org/gnu/readline
Note: if you are using precompiled packages you will also need the development
package as well (which may be called readline-devel or something similar).
)
		exit,
		$PARTED_LIBS
	)
 	LIBS="$OLD_LIBS"
fi

AC_SUBST(PARTED_LIBS)

dnl Check for OS specific libraries

dnl GNU/Hurd:
if test "$OS" = gnu; then
	CFLAGS="$CFLAGS -D_GNU_SOURCE=1"

dnl libshouldbeinlibc
	AC_CHECK_LIB(shouldbeinlibc, vm_deallocate,
		OS_LIBS="$OS_LIBS -lshouldbeinlibc",
		AC_MSG_ERROR(
GNU Parted requires libshouldbeinlibc when running on
GNU/Hurd systems.  It is a standard part of a GNU/Hurd system.
		)
		exit
	)

dnl libstore may depend on libparted being present.
dnl Aren't circular dependencies wonderful?
	OLD_LIBS="$LIBS"
	LIBS=

	AC_CHECK_LIB(parted, ped_device_read)

dnl libstore
	AC_CHECK_LIB(store, store_open,
		OS_LIBS="$OS_LIBS -lstore",
		AC_MSG_ERROR(
GNU Parted requires libstore when running on GNU/Hurd
systems.  It is a standard part of a GNU/Hurd system.
		)
		exit,
		$OS_LIBS $UUID_LIBS $DM_LIBS $LIBS
	)
	LIBS="$OLD_LIBS"
fi

dnl BeOS/ZETA/Haiku:

if test "$OS" = beos; then
	dnl Include the socket library, as it is a depedency of libuuid
	dnl and so also of us (due to socket() call in libuuid)
	OS_LIBS="$OS_LIBS -lsocket"
fi	

AC_SUBST(OS_LIBS)

dnl One day, gettext might support libtool...
dnl if test "$USE_INCLUDED_LIBINTL" = "yes"; then
dnl	INTLINCS='-I$(top_srcdir)/intl'
dnl fi
AC_SUBST(INTLINCS)


dnl Checks for header files.
AC_CHECK_HEADER(uuid/uuid.h, ,
	AC_MSG_ERROR(
GNU Parted requires libuuid - a part of the e2fsprogs package.
You seem to have the library installed but not the headers.  These are usually
found in a corresponding development package (usually called e2fsprogs-devel).
If you can't find one try:
        http://web.mit.edu/tytso/www/linux/e2fsprogs.html
)
	exit
)

AC_CHECK_HEADERS(getopt.h) 

dnl required for libparted/llseek.c  (TODO: make linux-x86 only)
if test "$OS" = linux; then
	AC_CHECK_HEADER(linux/unistd.h)
fi

if test "$with_readline" = yes; then
	AC_CHECK_HEADERS(readline/readline.h readline/history.h, ,
		AC_MSG_ERROR(
The headers for GNU Readline could not be found which
are required for the --with-readline option.  You seem to have the GNU readline
library installed but not the headers.  These are usually found in a
corresponding development package (usually called readline-devel).  If you can't
find one try:
        ftp.gnu.org/gnu/readline
Alternatively you can disable readline support with --without-readline
)
	exit
	)
fi

AC_CHECK_HEADERS(termcap.h)

if test "$USE_NLS" = yes; then
	AC_CHECK_HEADERS(wctype.h, ,
		AC_MSG_ERROR(
One or more of the header files that are required for
native language support (wctype.h) could not be found.  Either get a newer
version of GNU libc and its headers - which can be obtained from:
	ftp.gnu.org/gnu/glibc
Or disable native language support with the --disable-nls option
)
	exit
	)
fi

AC_CHECK_HEADER([execinfo.h], [
	AC_CHECK_LIB(c, backtrace, [
		AC_DEFINE(HAVE_BACKTRACE, 1, [Has backtrace support])
		LDFLAGS="$LDFLAGS -rdynamic"
	])
])

dnl Checks for typedefs, structures and compiler characteristics.
AC_PROG_LD

AC_C_BIGENDIAN
AC_C_INLINE
AC_C_CONST
AC_C_RESTRICT


dnl Checks for library functions.
AC_CHECK_FUNCS(sigaction)
AC_CHECK_FUNCS(getuid)

if test "$with_readline" = yes; then
	OLD_LIBS="$LIBS"
	LIBS="$LIBS $PARTED_LIBS -lreadline"
	AC_CHECK_FUNCS(rl_completion_matches)
	LIBS="$OLD_LIBS"
fi

OLD_CFLAGS="$CFLAGS"
CFLAGS=-D_GNU_SOURCE=1
AC_CHECK_FUNCS(canonicalize_file_name)
CFLAGS="$OLD_CFLAGS"

CFLAGS="$CFLAGS -W -Wall -Wno-unused -Wno-switch -Wno-format"

if test "$enable_Werror" = yes; then
	CFLAGS="$CFLAGS -Werror"
fi

DATE=$(date '+%d %b %Y %H:%M')
USER=$(whoami)
HOST=$(hostname)
BUILDINFO="$USER@$HOST, $DATE"
AC_SUBST(BUILDINFO)

AC_OUTPUT([
Makefile
include/Makefile
include/parted/Makefile
libparted/Makefile
libparted/labels/Makefile
libparted/fs/Makefile
libparted/fs/amiga/Makefile
libparted/fs/ext2/Makefile
libparted/fs/fat/Makefile
libparted/fs/hfs/Makefile
libparted/fs/jfs/Makefile
libparted/fs/linux_swap/Makefile
libparted/fs/ntfs/Makefile
libparted/fs/reiserfs/Makefile
libparted/fs/ufs/Makefile
libparted/fs/xfs/Makefile
parted/Makefile
partprobe/Makefile
doc/Makefile
doc/C/Makefile
doc/pt_BR/Makefile
debug/Makefile
debug/clearfat/Makefile
debug/test/Makefile
po/Makefile.in
parted.spec
])

echo
echo Type \'make\' to compile parted.
