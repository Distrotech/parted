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

# Written by Tom "spot" Callaway <tcallawa@redhat.com>
# Derived from an example by Jim Meyering <jim@meyering.net>

test_description="RAID support on sun disk type"

: ${srcdir=.}
. $srcdir/test-lib.sh

N=10M
dev=sun-disk-file
exp="BYT;\n---:20480s:file:512:512:sun:;\n1:0s:50s:51s"
test_expect_success \
    'create an empty file as a test disk' \
    'dd if=/dev/null of=$dev bs=1 seek=$N 2> /dev/null'

test_expect_success \
    'label the test disk as a sun disk' \
    'parted -s $dev mklabel sun > out 2>&1'
test_expect_success 'check for empty output' 'compare out /dev/null'

test_expect_success \
    'create a single partition' \
    'parted -s $dev unit s mkpart ext2 0s 50s > out 2>&1'
test_expect_success 'check for empty output' 'compare out /dev/null'

test_expect_success \
    'print the partition data in machine readable format' \
    'parted -m -s $dev unit s p > out 2>&1 &&
     sed "s,^.*/$dev:,---:," out > k && mv k out'

test_expect_success \
    'check for expected values for the partition' '
    printf "$exp:::;\n" > exp &&
    compare out exp'

test_expect_success \
    'set the raid flag' \
    'parted -s $dev set 1 raid >out 2>&1'
test_expect_success 'check for empty output' 'compare out /dev/null'

test_expect_success \
    'print the partition data in machine readable format again' \
    'parted -m -s $dev unit s p > out 2>&1 &&
     sed "s,^.*/$dev:,---:," out > k && mv k out'

test_expect_success \
    'check for expected values (including raid flag) for the partition' '
    printf "$exp:::raid;\n" > exp &&
    compare out exp'

test_done
