#!/bin/sh

git log --pretty=medium | fold -s > ChangeLog
aclocal
autoconf -f
autoheader
autopoint -f
libtoolize -c -f
automake -a -c
