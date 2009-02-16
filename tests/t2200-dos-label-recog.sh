#!/bin/sh

# Copyright (C) 2008 Free Software Foundation, Inc.

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

test_description='improved MSDOS partition-table recognition'

: ${srcdir=.}
. $srcdir/test-lib.sh

######################################################################
# With vestiges of a preceding FAT file system boot sector in the MBR,
# parted 1.8.8.1.29 and earlier would fail to recognize a DOS
# partition table.
######################################################################
N=100k
dev=loop-file
test_expect_success \
    'create a file to simulate the underlying device' \
    'dd if=/dev/null of=$dev bs=1 seek=$N 2> /dev/null'

test_expect_success \
    'label the test disk' \
    'parted -s $dev mklabel msdos > out 2>&1'
test_expect_success 'expect no output' 'compare out /dev/null'

test_expect_success \
    'create two partition' \
    '
    parted -s $dev mkpart primary  1s 40s > out 2>&1 &&
    parted -s $dev mkpart primary 41s 80s > out 2>&1

    '
test_expect_success 'expect no output' 'compare out /dev/null'

test_expect_success \
    'write "FAT" where it would cause trouble' \
    'printf FAT|dd bs=1c seek=82 count=3 of=$dev conv=notrunc'

test_expect_success \
    'print the partition table' \
    '
    parted -m -s $dev unit s p > out &&
    tail -2 out > k && mv k out &&
    printf "1:1s:40s:40s:::;\n2:41s:80s:40s:::;\n" > exp

    '
test_expect_success 'expect two partitions' 'compare out exp'

test_done
