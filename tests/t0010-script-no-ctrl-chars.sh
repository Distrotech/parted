#!/bin/sh
# Ensure that printing with -s outputs no readline control chars

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

test_description='--script does no readline initialization'

: ${srcdir=.}
. $srcdir/test-lib.sh

ss=$sector_size_
n_sectors=5000
dev=loop-file

test_expect_success \
    'create the test file' \
    'dd if=/dev/null of=$dev bs=$ss seek=$n_sectors'

test_expect_success \
    'run parted -s FILE mklabel msdos' \
    'parted -s $dev mklabel msdos > out 2>&1'
test_expect_success 'expect no output' 'compare out /dev/null'

test_expect_success \
    'print partition table in --script mode' \
    'TERM=xterm parted -m -s $dev u s p > out 2>&1'

ok=0
sed "s,.*/$dev:,$dev:," out > k && mv k out &&
printf "BYT;\n$dev:${n_sectors}s:file:$ss:$ss:msdos:;\n" > exp &&
  ok=1

test_expect_success \
    'match against expected output' \
    'test $ok = 1 && compare out exp'

test_done
