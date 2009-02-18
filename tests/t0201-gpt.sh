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

test_description='avoid failed assertion when creating a GPT on top of an old one for a larger device'

: ${srcdir=.}
. $srcdir/test-lib.sh

dev=loop-file
test_expect_success \
    'create a backing file large enough for a GPT partition table' \
    'dd if=/dev/null of=$dev seek=4001 2> /dev/null'

test_expect_success \
    'create a GPT partition table' \
    'parted -s $dev mklabel gpt > out 2>&1'
test_expect_success 'expect no output' 'compare out /dev/null'

test_expect_success \
    'shrink the backing file' \
    'dd if=/dev/null of=$dev seek=4000 2> /dev/null'

test_expect_success \
    'create a new GPT table on top of the shrunken backing file' \
    'parted -s $dev mklabel gpt > out 2>&1'
test_expect_success 'expect no output' 'compare out /dev/null'

test_done
