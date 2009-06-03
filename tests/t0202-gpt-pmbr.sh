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

test_description='Preserve first 446B of the Protected MBR for gpt partitions.'

: ${srcdir=.}
. $srcdir/test-lib.sh

dev=loop-file
test_expect_success \
    'Create a 100k test file with random content' \
    'dd if=/dev/urandom of=$dev bs=1c count=446 &&
     dd if=/dev/zero of=$dev bs=1c seek=446 count=101954 > /dev/null 2>&1'

test_expect_success \
    'Extract the first 446 Bytes before GPT creation' \
    'dd if=$dev of=before bs=1c count=446 > /dev/null 2>&1'

test_expect_success \
    'create a GPT partition table' \
    'parted -s $dev mklabel gpt > out 2>&1'
test_expect_success 'expect no output' 'compare out /dev/null'

test_expect_success \
    'Extract the first 446 Bytes after GPT creation' \
    'dd if=$dev of=after bs=1c count=446 > /dev/null 2>&1'

test_expect_success \
    'Compare the before and after' \
    'compare before after'

test_done
