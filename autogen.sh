#!/bin/sh

git log --pretty=medium | fold -s > ChangeLog
mkdir -p m4
aclocal -I m4
autoconf -f
autoheader
autopoint -f
libtoolize -c -f
automake -a -c
