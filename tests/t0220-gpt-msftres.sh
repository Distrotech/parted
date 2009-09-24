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

test_description='gpt default "flag" for a partition must not be msftres'

: ${srcdir=.}
. $srcdir/test-lib.sh

ss=$sector_size_
dev=loop-file

# FIXME: should be able to use "ufs" here, too, but that doesn't work.
fs_types='
ext2
fat16
fat32
hfs
hfs+
hfsx
linux-swap
NTFS
reiserfs
'

start=200
part_size=100
n_types=$(echo "$fs_types"|wc -w)

# Create a "disk" with enough room for one partition per FS type,
# and the overhead required for a GPT partition table.
# 32 is the number of 512-byte sectors required to accommodate the
# minimum size of the secondary GPT header at the end of the disk.
n_sectors=$(expr $start + $n_types \* $part_size + 1 + 32)

test_expect_success \
    'create a test file large enough for one partition per FS type' \
    'dd if=/dev/null of=$dev bs=$ss seek=$n_sectors'

test_expect_success \
    'create a gpt partition table' \
    'parted -s $dev mklabel gpt > out 2>&1'
test_expect_success 'expect no output' 'compare out /dev/null'

printf "BYT;\n$dev:${n_sectors}s:file:$ss:$ss:gpt:;\n" > exp
i=1
fail=0
rm -f out
for type in $fs_types; do
  end=$(expr $start + $part_size - 1)
  echo "$i:${start}s:${end}s:${part_size}s::$type:;" >> exp || fail=1
  parted -s $dev mkpart primary $type ${start}s ${end}s >> out 2>&1 || fail=1
  parted -s $dev name $i $type >> out 2>&1 || fail=1
  start=$(expr $end + 1)
  i=$(expr $i + 1)
done

test_expect_success \
    "create $n_types partitions" \
    'test $fail = 0'
test_expect_success 'expect no output' 'compare out /dev/null'

rm -f out
test_expect_success \
    'print partition table' \
    'parted -m -s $dev u s p > out 2>&1'

sed "s,.*/$dev:,$dev:," out > k && mv k out && ok=1 || ok=0
test_expect_success \
    'match against expected output' \
    'test $ok = 1 && compare out exp'

test_done
