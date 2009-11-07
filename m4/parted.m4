# library paths for libparted
# written by Damien Genet <damien.genet@free.fr>

dnl Usage:
dnl PARTED_CHECK_LIBPARTED([MINIMUM-VERSION, [ACTION-IF-FOUND [, ACTION-IF-NOT-FOUND]]])
dnl where MINIMUM-VERSION must be >= 1.2.8 and != 1.3.0
dnl
dnl Example:
dnl PARTED_CHECK_LIBPARTED(1.2.8, , [AC_MSG_ERROR([*** libparted >= 1.2.8 not installed - please install first ***])])
dnl
dnl Adds the required libraries to $PARTED_LIBS and does an
dnl AC_SUBST([PARTED_LIBS])
dnl


AC_DEFUN([PARTED_CHECK_LIBPARTED],
[
AC_REQUIRE([AC_CANONICAL_HOST])

dnl save LIBS
saved_LIBS="$LIBS"

dnl Check for headers and library
AC_CHECK_HEADER([parted/parted.h], ,
		[AC_MSG_ERROR([<parted/parted.h> not found; install GNU/Parted])]
		$3)
AC_CHECK_LIB([uuid], [uuid_generate], ,
	     [AC_MSG_ERROR([libuuid not found; install e2fsprogs available at http://web.mit.edu/tytso/www/linux/e2fsprogs.html])]
             $3)
AC_CHECK_LIB([parted],ped_device_read, ,
             [AC_MSG_ERROR([libparted not found; install GNU/Parted available at http://www.gnu.org/software/parted/parted.html])]
             $3)

case "$host_os" in
	gnu*)	# The Hurd requires some special system libraries
		# with very generic names, which is why we special
		# case these tests.

		AC_CHECK_LIB([shouldbeinlibc], [lcm], ,
                	[AC_MSG_ERROR([libshouldbeinlibc not found; install the Hurd development libraries.])]
                $3)

		AC_CHECK_LIB([store], [store_open], ,
                	[AC_MSG_ERROR([libstore not found; install the Hurd development libraries.])]
                $3)
		;;
	*)	;;
esac

AC_MSG_CHECKING([for libparted - version >= $1])

AC_TRY_LINK_FUNC([ped_get_version], ,
                 AC_MSG_RESULT([failed])
                 AC_MSG_ERROR([*** libparted < 1.2.8 or == 1.3.0 can't execute test ***]))

dnl Get major, minor, and micro version from arg MINIMUM-VERSION
parted_config_major_version=`echo $1 | \
    sed 's/\([[0-9]]*\).\([[0-9]]*\).\([[0-9]]*\)/\1/'`
parted_config_minor_version=`echo $1 | \
    sed 's/\([[0-9]]*\).\([[0-9]]*\).\([[0-9]]*\)/\2/'`
parted_config_micro_version=`echo $1 | \
    sed 's/\([[0-9]]*\).\([[0-9]]*\).\([[0-9]]*\)/\3/'`

dnl Compare MINIMUM-VERSION with libparted version
AC_TRY_RUN([
#include <stdio.h>
#include <stdlib.h>
#include <parted/parted.h>

int main ()
{
	int		major, minor, micro;
	const char	*version;

	if ( !(version = ped_get_version ()) )
		exit(EXIT_FAILURE);
	if (sscanf(version, "%d.%d.%d", &major, &minor, &micro) != 3) {
		printf("%s, bad version string\n", version);
		exit(EXIT_FAILURE);
	}

	if ((major > $parted_config_major_version) ||
	   ((major == $parted_config_major_version) && (minor > $parted_config_minor_version)) ||
	   ((major == $parted_config_major_version) && (minor == $parted_config_minor_version) && (micro >= $parted_config_micro_version))) {
		return 0;
	} else {
		printf("\n*** An old version of libparted (%s) was found.\n",
		       version);
		printf("*** You need a version of libparted equal to or newer than %d.%d.%d.\n",
			$parted_config_major_version,
			$parted_config_minor_version,
			$parted_config_micro_version);
		printf("*** You can get it at - ftp://ftp.gnu.org/gnu/parted/\n");
		return 1;
	}
}
],
    AC_MSG_RESULT([yes]),
    AC_MSG_RESULT([no]) ; $3,
    [echo $ac_n "cross compiling; assumed OK... $ac_c"])

dnl restore orignial LIBS and set @PARTED_LIBS@
PARTED_LIBS="$LIBS"
LIBS="$saved_LIBS"
AC_SUBST([PARTED_LIBS])

dnl Execute ACTION-IF-FOUND
$2

])
