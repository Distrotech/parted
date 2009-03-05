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

dev=loop-file

test_expect_success \
    "setup: create zeroed device" \
    '{ dd if=/dev/zero bs=1024 count=64; } > $dev'

test_expect_success \
    'create gpt label' \
    'parted -s $dev mklabel gpt >out 2>&1'

test_expect_success \
    'add a partition' \
    'parted -s $dev mkpart primary 0 1 >>out 2>&1'

test_expect_success \
    'print the table (before manual modification)' \
    'parted -s $dev print >>out 2>&1'

# Using bios_boot_magic='\x48\x61' looks nicer, but isn't portable.
# dash's builtin printf doesn't recognize such \xHH hexadecimal escapes.
bios_boot_magic='\110\141\150\41\111\144\157\156\164\116\145\145\144\105\106\111'

printf "$bios_boot_magic" | dd of=$dev bs=1024 seek=1 conv=notrunc

test_expect_success \
    'print the table (after manual modification)' \
    'parted -s $dev print >>out 2>&1'

pwd=`pwd`

fail=0
{
  cat <<EOF
Model:  (file)
Disk .../$dev: 65.5kB
Sector size (logical/physical): 512B/512B
Partition Table: gpt

Number  Start   End     Size    File system  Name     Flags
 1      17.4kB  48.6kB  31.2kB               primary

Model:  (file)
Disk .../$dev: 65.5kB
Sector size (logical/physical): 512B/512B
Partition Table: gpt

Number  Start   End     Size    File system  Name     Flags
 1      17.4kB  48.6kB  31.2kB               primary  bios_grub

EOF
} > exp || fail=1

test_expect_success \
    'prepare actual and expected output' \
    'test $fail = 0 &&
     mv out o2 && sed "s,^Disk .*/$dev:,Disk .../$dev:," o2 > out'

test_expect_success 'check for expected output' 'compare out exp'

test_done
