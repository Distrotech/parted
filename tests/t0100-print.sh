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

test_description="the most basic 'print' test"

. ./init.sh

dev=loop-file

msdos_magic='\x55\xaa'

# The extra 3KB+ zero bytes at the end are to avoid triggering a failure
# on linux-2.6.8 that's probably related to opening with O_DIRECT.
# Note that the minimum number of appended zero bytes required to avoid
# the failure was 3465.  Here, we append a little more to make the resulting
# file have a total size of exactly 4kB.
test_expect_success \
    "setup: create the most basic partition table, manually" \
    '{ dd if=/dev/zero  bs=510 count=1; printf "$msdos_magic"
       dd if=/dev/zero bs=3584 count=1; } > $dev'

test_expect_success \
    'print the empty table' \
    'parted -s $dev print >out 2>&1'

pwd=`pwd`

fail=0
{
  cat <<EOF
Model:  (file)
Disk .../$dev: 4096B
Sector size (logical/physical): 512B/512B
Partition Table: msdos

Number  Start  End  Size  Type  File system  Flags

EOF
} > exp || fail=1

test_expect_success \
    'prepare actual and expected output' \
    'test $fail = 0 &&
     mv out o2 && sed "s,^Disk .*/$dev:,Disk .../$dev:," o2 > out'

test_expect_success 'check for expected output' '$compare out exp'

test_done
