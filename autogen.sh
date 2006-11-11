#!/bin/sh

aclocal
autoconf -f
autoheader
autopoint -f
libtoolize -c -f
automake -a -c
