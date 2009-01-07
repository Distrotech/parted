#!/bin/sh

# Copyright (C) 2008-2009 Free Software Foundation, Inc.

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

test_description='Probe Ext2, Ext3 and Ext4 file systems.'

: ${srcdir=.}
. $srcdir/test-lib.sh

dev=loop-file

for type in ext2 ext3 ext4; do

( mkfs.$type -V ) >/dev/null 2>&1 ||
  { echo "no $type support; skipping that test"; continue; }

test_expect_success \
    "create an $type file system" '
    dd if=/dev/zero of=$dev bs=1024 count=4096 >/dev/null &&
    mkfs -F -t $type $dev >/dev/null'

test_expect_success \
    "probe the $type file system" '
    parted -s $dev print >out 2>1
    grep -w $type out'

done

test_done
