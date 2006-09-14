#!/bin/sh

aclocal
autoconf -f
autoheader
autopoint
libtoolize -c -f
automake -a -c
