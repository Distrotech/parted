#!/bin/sh

# Copyright (C) 2007 Free Software Foundation, Inc.

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

test_description='Create some file systems using mkpartfs.'

. ./init.sh

N=1M
dev=loop-file
test_expect_success \
    'create a file too small to hold a fat32 file system' \
    'dd if=/dev/null of=$dev bs=1 seek=$N 2> /dev/null'

test_expect_success \
    'label the test disk' \
    'parted -s $dev mklabel msdos > out 2>&1'
test_expect_success 'expect no output' '$compare out /dev/null'

# Expect parted's mkpartfs command to fail.
test_expect_failure \
    'try/fail to create a file system in too small a space' \
    'parted -s $dev mkpartfs primary fat32 0 1 > out 2>&1'

test_expect_success \
    'create expected output file' \
    'echo "Error: Partition too big/small for a fat32 file system." > exp'

test_expect_success \
    'check for expected failure diagnostic' \
    '$compare out exp'

test_expect_success 'clean up, preparing for next test' 'rm $dev out'

#====================================================================
# Similar, but with a file that's large enough, so mkpartfs succeeds.
N=40M

test_expect_success \
    'create a file large enough to hold a fat32 file system' \
    'dd if=/dev/null of=$dev bs=1 seek=$N 2> /dev/null'

test_expect_success \
    'label the test disk' \
    'parted -s $dev mklabel msdos > out 2>&1'
test_expect_success 'expect no output' '$compare out /dev/null'

test_expect_success \
    'create an msdos file system' \
    'parted -s $dev mkpartfs primary fat32 1 40 > out 2>&1'

test_expect_success 'expect no output' '$compare out /dev/null'

test_done
