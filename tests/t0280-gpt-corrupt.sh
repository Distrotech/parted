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

test_description="corrupt a GPT table; ensure parted takes notice"

peek()
{
  case $# in 2) ;; *) echo "usage: peek FILE 0_BASED_OFFSET" >&2; exit 1;; esac
  case $2 in *[^0-9]*) echo "peek: invalid offset: $2"; exit 1 ;; esac
  dd if="$1" bs=1 skip="$2" count=1
}

poke()
{
  case $# in 3) ;; *) echo "usage: poke FILE 0_BASED_OFFSET BYTE" >&2; exit 1;;
    esac
  case $2 in *[^0-9]*) echo "poke: invalid offset: $2"; exit 1 ;; esac
  case $3 in ?) ;; *) echo "poke: invalid byte: '$3'"; exit 1 ;; esac
  printf %s "$3" | dd of="$1" bs=1 seek="$2" count=1 conv=notrunc
}

: ${srcdir=.}
. $srcdir/test-lib.sh

dev=loop-file

ss=$sector_size_
n_sectors=200

test_expect_success \
    "setup: create zeroed device" \
    'dd if=/dev/null of=$dev bs=$ss seek=$n_sectors'

test_expect_success \
    'create gpt label' \
    'parted -s $dev mklabel gpt > empty 2>&1'
test_expect_success 'expect no output' 'compare /dev/null empty'

test_expect_success \
    'print the empty table' \
    'parted -m -s $dev unit s print > t 2>&1 &&
     sed 's,.*/$dev:,$dev:,' t > out'

test_expect_success \
    'check for expected output' \
    'printf "BYT;\n$dev:${n_sectors}s:file:$sector_size_:$sector_size_:gpt:;\n"\
       > exp &&
     compare exp out'

test_expect_success \
    'create a partition' \
    'parted -s $dev mkpart sw linux-swap 60s 100s > empty 2>&1'
test_expect_success 'expect no output' 'compare /dev/null empty'

# We're going to change the name of the first partition,
# thus invalidating the PartitionEntryArrayCRC32 checksum.

# byte 56 of the partition entry is the first byte of its 72-byte name field
pte_offset=$(expr $ss \* 2 + 56)

test_expect_success \
    'get the first byte of the name' \
    'pte_byte=$(peek $dev $pte_offset)'

test x"$pte_byte" = xA && new_byte=B || new_byte=A

test_expect_success \
    'Replace with a different byte' \
    'poke $dev $pte_offset "$new_byte"'

test_expect_success \
    'printing the table must fail' \
    'parted -s $dev print > err 2>&1;
     test $? = 1'

test_expect_success \
    'check for expected diagnostic' \
    'echo "Error: primary partition table array CRC mismatch" > exp &&
     compare exp err'

# ----------------------------------------------------------
# Now, restore things, and corrupt the MyLBA in the alternate GUID table.

orig_byte=s
test_expect_success \
    'Restore original byte' \
    'poke $dev $pte_offset "$orig_byte"'

test_expect_success \
    'print the table' \
    'parted -s $dev print > out 2> err'
test_expect_success 'expect no output' 'compare /dev/null err'

# The MyLBA member of the alternate table is in the last sector,
# $n_sectors, 8-byte field starting at offset 24.
alt_my_lba_offset=$(expr $n_sectors \* $ss - $ss + 24)
test_expect_success \
    'get the first byte of MyLBA' \
    'byte=$(peek $dev $alt_my_lba_offset)'

# Perturb it.
test x"$byte" = xA && new_byte=B || new_byte=A

# Insert the bad byte.
test_expect_success \
    'Replace with a different byte' \
    'poke $dev $alt_my_lba_offset "$new_byte"'

test_expect_success \
    'attempting to set partition name must print a diagnostic' \
    'parted -m -s $dev name 1 foo > err 2>&1'

test_expect_success \
    'check for expected diagnostic' \
    'echo "Error: The backup GPT table is corrupt, but the primary appears OK, so that will be used." > exp &&
     compare exp err'

test_expect_success \
    'corruption is fixed; printing the table now elicits no diagnostic' \
    'parted -m -s $dev u s print > out 2>&1'

test_expect_success \
    'check for expected output' \
    'printf "BYT;\nfile\n1:60s:100s:41s::foo:;\n" > exp &&
     sed "s/.*gpt:;/file/" out > k && mv k out &&
     compare exp out'

test_done
