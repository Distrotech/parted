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

test_description='avoid segfault creating a dos PT on top of a gpt one'

PARTED_SECTOR_SIZE=4096
export PARTED_SECTOR_SIZE

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
    'create a DOS partition table on top of it' \
    'parted -s $dev mklabel msdos > out 2>&1'
test_expect_success 'expect no output' 'compare out /dev/null'

test_done
