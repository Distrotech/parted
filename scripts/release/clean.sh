#!/bin/bash
# Clean tree of unmanaged files after a 'make distclean'

if [ ! -d parted ] && [ ! -d libparted ]; then
	echo "Run this from the toplevel parted directory."
	exit 1
fi

rm -rf ChangeLog doc/mdate-sh doc/texinfo.tex
rm -rf m4 configure config.rpath depcomp
rm -rf parted-*.*.*
rm -rf compile config.guess config.sub ltmain.sh mkinstalldirs
rm -rf config.h.in autom4te.cache missing aclocal.m4 install-sh
rm -rf doc/stamp-vti doc/version.texi doc/parted.info
rm -rf ABOUT-NLS INSTALL

rm -rf po/*.gmo po/stamp-po po/Makevars.template po/Rules-quot
rm -rf po/Makefile.in.in

find . -type f -name Makefile.in | xargs rm -f

exit 0
