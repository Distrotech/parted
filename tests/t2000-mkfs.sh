#!/bin/sh

# Copyright (C) 2007 Free Software Foundation, Inc.

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301, USA.

test_description='Create some file systems using mkfs.'

. ./init.sh

N=40M
dev=loop-file
test_expect_success \
    'create a file large enough to hold a fat32 file system' \
    'dd if=/dev/null of=$dev bs=1 seek=$N 2> /dev/null'

test_expect_success \
    'label the test disk' \
    'parted -s $dev mklabel msdos > out 2>&1'
test_expect_success 'expect no output' '$compare out /dev/null'

test_expect_success \
    'create a partition' \
    'parted -s $dev mkpart primary 1 40 > out 2>&1'

test_expect_success \
    'create an msdos file system' \
    'parted -s $dev mkfs 1 fat32 > out 2>&1'

test_expect_success 'expect no output' '$compare out /dev/null'

N=10M
test_expect_success \
    'create a file large enough to hold a fat32 file system' \
    'dd if=/dev/null of=$dev bs=1 seek=$N 2> /dev/null'

test_expect_success \
    'label the test disk' \
    'parted -s $dev mklabel msdos > out 2>&1'
test_expect_success 'expect no output' '$compare out /dev/null'

# test if can create a partition and a filesystem in the same session.
fail=0
cat <<EOF >in || fail=1
mkpart
primary
ext2
0
10
mkfs
No
quit
EOF
test_expect_success 'create input file' 'test $fail = 0'

test_expect_success \
    'create a partition and a filesystem in the same session' \
    'parted ---pretend-input-tty $dev < in > out 2>&1'

test_expect_success \
    'normalize the actual output' \
    'sed -n "s/.*\(Warning: The existing.*\)$/\1/p" out > out2'

test_expect_success \
    'check for expected prompt' \
    'echo "Warning: The existing file system will be destroyed and all" \
       "data on the partition will be lost. Do you want to continue?" > exp &&
     $compare out2 exp'

#############################################################
# Ensure that an invalid file system type elicits a diagnostic.
# Before parted 1.8.8, this would fail silently.

dev=loop-file

test_expect_success \
    "setup: create and label a device" \
    'dd if=/dev/null of=$dev bs=1 seek=1M 2>/dev/null &&
     parted -s $dev mklabel msdos'

test_expect_failure \
    'try to create a file system with invalid type name' \
    'parted -s $dev mkpartfs primary bogus 1 1 >out 2>&1'

test_expect_success \
    'normalize the actual output' \
    'mv out o2 && sed -e "s,   *,,;s, $,," \
                      -e "s,^.*/lt-parted: ,parted: ," o2 > out'

test_expect_success \
    'check for expected diagnostic' \
    '{ echo "parted: invalid token: bogus"
       echo "Error: Expecting a file system type."; } > exp &&
     $compare out exp'

#############################################################
# Demonstrate 3-block-group failure for 16+MB EXT2 file system.
# This test fails with at least parted-1.8.8.

dev=loop-file

test_expect_success \
    "setup: create and label a device" \
    'dd if=/dev/null of=$dev bs=1 seek=20M 2>/dev/null &&
     parted -s $dev mklabel gpt'

# FIXME: this test currently fails with the diagnostic "Error: Attempt
# to write sectors 32772-32773 outside of partition on .../loop-file."
# Eventually, when this bug is fixed, change to "test_expect_success"
# and ensure that the output file is empty.
test_expect_failure \
    'try to create a file system with the offending size' \
    'parted -s $dev mkpartfs primary ext2 0 16796160B >out 2>&1'

test_done
