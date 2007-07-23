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

test_description='Create very small ext2 file systems.'

. ./init.sh

dev=loop-file
test_expect_success \
    'setup' '
    dd if=/dev/null of=$dev bs=1 seek=10M 2> /dev/null &&
    parted -s $dev mklabel msdos'

test_expect_failure \
    'try to create an ext2 partition that is one byte too small' '
    parted -s $dev mkpartfs primary ext2 10KB 29695B > out 2>&1'

test_expect_success \
    'check for expected diagnostic' '
    echo Error: File system too small for ext2. > exp &&
    $compare out exp'

test_expect_success \
    'create the smallest ext2 partition' '
    parted -s $dev mkpartfs primary ext2 10KB 29696B > out 2>&1
    $compare out /dev/null'

# Restore $dev to initial state by writing 1KB of zeroes at the beginning.
# Then relabel.
test_expect_success \
    'setup' '
    dd if=/dev/zero of=$dev bs=1K count=1 conv=notrunc 2> /dev/null &&
    parted -s $dev mklabel msdos'

test_expect_success \
    'create another ext2 file system (this would fail for parted-1.8.7)' '
    parted -s $dev mkpartfs primary ext2 2 10 > out 2>&1'
test_expect_success 'expect no output' '$compare out /dev/null'

test_expect_success \
    'create a smaller one; this would succeed for parted-1.8.7' '
    dd if=/dev/zero of=$dev bs=1K count=1 conv=notrunc 2> /dev/null &&
    parted -s $dev mklabel msdos &&
    parted -s $dev mkpartfs primary ext2 2 9 > out 2>&1'
test_expect_success 'expect no output' '$compare out /dev/null'

test_done
