#!/bin/sh

# Copyright (C) 2007-2009 Free Software Foundation, Inc.

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

test_description="test bios_grub flag in gpt labels"

: ${srcdir=.}
. $srcdir/test-lib.sh
ss=$sector_size_

dev=loop-file
N=300 # number of sectors

part_sectors=128
start_sector=60
end_sector=$(expr $start_sector + $part_sectors - 1)

test_expect_success \
    "setup: reasonable params" \
    'test $end_sector -lt $N'

test_expect_success \
    "setup: create zeroed device" \
    'dd if=/dev/zero of=$dev bs=${ss}c count=$N 2> /dev/null'

test_expect_success \
    'create gpt label' \
    'parted -s $dev mklabel gpt > empty 2>&1'

test_expect_success 'ensure there was no output' \
    'compare /dev/null empty'

test_expect_success \
    'print the table (before adding a partition)' \
    'parted -m -s $dev unit s print > t 2>&1 &&
     sed 's,.*/$dev:,$dev:,' t > out'

test_expect_success \
    'check for expected output' \
    'printf "BYT;\n$dev:${N}s:file:$ss:$ss:gpt:;\n" > exp &&
     compare exp out'

test_expect_success \
    'add a partition' \
    'parted -s $dev u s mkpart name1 ${start_sector} ${end_sector} >out 2>&1'

test_expect_success \
    'print the table before modification' \
    '
     parted -m -s $dev unit s print > t 2>&1 &&
     sed 's,.*/$dev:,$dev:,' t >> out
    '

test_expect_success \
    'set the new bios_grub attribute' \
    'parted -m -s $dev set 1 bios_grub on'

test_expect_success \
    'print the table after modification' \
    '
     parted -m -s $dev unit s print > t 2>&1
     sed 's,.*/$dev:,$dev:,' t >> out
    '

gen_exp()
{
  cat <<EOF
BYT;
$dev:${N}s:file:$ss:$ss:gpt:;
1:${start_sector}s:${end_sector}s:${part_sectors}s::name1:;
BYT;
$dev:${N}s:file:$ss:$ss:gpt:;
1:${start_sector}s:${end_sector}s:${part_sectors}s::name1:bios_grub;
EOF
}

test_expect_success 'check for expected output' \
    '
     gen_exp > exp &&
     compare exp out
    '

test_done
