#!/bin/sh

# Copyright (C) 2009 Free Software Foundation, Inc.

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

test_description='printing a GPT partition table must not modify it'

: ${srcdir=.}
. $srcdir/test-lib.sh

N=2M
dev=loop-file
test_expect_success \
    'create a file large enough to hold a GPT partition table' \
    'dd if=/dev/null of=$dev bs=1 seek=$N 2> /dev/null'

test_expect_success \
    'create a GPT partition table' \
    'parted -s $dev mklabel gpt > out 2>&1'
test_expect_success 'expect no output' 'compare out /dev/null'

test_expect_success \
    'save a copy of the original primary GPT table' \
    'dd if=$dev of=before count=1 skip=1'

test_expect_success \
    'extend the backing file by 1 byte' \
    'printf x >> $dev'

test_expect_success \
    'use parted simply to print the partition table' \
    'parted -m -s $dev u s p > out 2> err'
# don't bother comparing stdout
test_expect_success 'expect no stderr' 'compare err /dev/null'

test_expect_success \
    'extract the primary GPT table again' \
    'dd if=$dev of=after count=1 skip=1'

test_expect_success \
    'compare partition tables (they had better be identical)' \
    'compare before after'

test_done
