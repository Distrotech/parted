#!/bin/sh
# Ensure that Sun VTOC is properly initialized.

# Copyright (C) 2009-2010 Free Software Foundation, Inc.

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

# Written by Karel Zak <kzak@redhat.com>

test_description='test Sun VTOC initialization'

: ${srcdir=.}
. $srcdir/test-lib.sh

N=2M
dev=loop-file
test_expect_success \
    'create a file to simulate the underlying device' \
    'dd if=/dev/null of=$dev bs=1 seek=$N 2> /dev/null'

test_expect_success \
    'label the test disk' \
    'parted -s $dev mklabel sun > out 2>&1'
test_expect_success 'expect no output' 'compare out /dev/null'

test_expect_success \
    'extract version' \
    'od -t x1 -An -j128 -N4 $dev > out && echo " 00 00 00 01" > exp'
test_expect_success 'expect it to be 00 00 00 01, not 00 00 00 00' \
    'compare out exp'

test_expect_success \
    'extract nparts' \
    'od -t x1 -An -j140 -N2 $dev > out && echo " 00 08" > exp'
test_expect_success 'expect it to be 00 08, not 00 00' 'compare out exp'

test_expect_success \
    'extract sanity magic' \
    'od -t x1 -An -j188 -N4 $dev > out && echo " 60 0d de ee" > exp'
test_expect_success 'expect it to be 60 0d de ee, not 00 00 00 00' \
    'compare out exp'

test_done
