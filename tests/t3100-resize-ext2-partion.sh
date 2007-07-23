#!/bin/sh
# Exercise an EXT2-resizing bug.

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

test_description='Exercise an EXT2-resize bug in at least 1.8.7'

. ./init.sh

dev=loop-file
# The "device size", $N, must be larger than $NEW_SIZE.
N=1500M

# To trigger the bug, the target size must be 269M or larger.
NEW_SIZE=269M

# $ORIG_SIZE may be just about anything smaller than $NEW_SIZE.
ORIG_SIZE=1M

test_expect_success \
    'create the test file' \
    'dd if=/dev/null of=$dev bs=1 seek=$N 2> /dev/null'

test_expect_success \
    'run parted -s FILE mklabel msdos' \
    'parted -s $dev mklabel msdos > out 2>&1'
test_expect_success 'check for empty output' '$compare out /dev/null'

test_expect_success \
    'make an ext2 primary partition' \
    'parted -s $dev mkpartfs primary ext2 0 $ORIG_SIZE > out 2>&1'
test_expect_success 'check for empty output' '$compare out /dev/null'

# FIXME: this test currently fails with the diagnostic "error: block
# relocator should have relocated 64".
# Eventually, when this bug is fixed, change each of the following
# expected failures to "test_expect_success".
test_expect_failure \
    'resize ext2 primary partition' \
    'parted -s $dev resize 1 0 $NEW_SIZE > out 2>&1'
test_expect_failure 'check for empty output' '$compare out /dev/null'

test_done
