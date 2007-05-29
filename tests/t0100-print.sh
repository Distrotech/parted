#!/bin/sh

# Copyright (C) 2007 Free Software Foundation, Inc.

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301, USA.

test_description="the most basic 'print' test"

. ./init.sh

dev=loop-file

msdos_magic='\x55\xaa'

test_expect_success \
    "setup: create the most basic partition table, manually" \
    '{ dd if=/dev/zero bs=510 count=1; printf "$msdos_magic"; } > $dev'

test_expect_success \
    'print the empty table' \
    'parted -s $dev print >out 2>&1'

pwd=`pwd`

fail=0
{
  cat <<EOF
Model:  (file)
Disk .../$dev: 512B
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
